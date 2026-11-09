#include "CPythonBridge.h"

#include <stdlib.h>
#include <string.h>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

// Python.framework is iOS-only. Package.swift adds its headers to the search path
// for iOS builds; everywhere else this file compiles to a stub.
#if defined(TARGET_OS_IOS) && TARGET_OS_IOS && __has_include(<Python/Python.h>)
#define CSB_HAS_PYTHON 1
#else
#define CSB_HAS_PYTHON 0
#endif

static char *csb_strdup_len(const char *text, size_t length) {
    char *copy = malloc(length + 1);
    if (copy == NULL) return NULL;
    memcpy(copy, text, length);
    copy[length] = '\0';
    return copy;
}

static char *csb_strdup(const char *text) {
    return csb_strdup_len(text, strlen(text));
}

static csb_write_callback csb_write_fn = NULL;
static csb_readline_callback csb_readline_fn = NULL;

void csb_set_callbacks(csb_write_callback write, csb_readline_callback readline) {
    csb_write_fn = write;
    csb_readline_fn = readline;
}

#if CSB_HAS_PYTHON

#define PY_SSIZE_T_CLEAN
#include <Python/Python.h>
#include <stdatomic.h>

// Owned by the run thread. Swapped in and out around each call.
static PyThreadState *csb_main_tstate = NULL;
// `PyThread_get_thread_ident()` of the run thread.
static unsigned long csb_run_thread_id = 0;
// True while csb_call runs Python code. Read and written only with the GIL held.
static int csb_call_active = 0;
static atomic_int csb_initialized = 0;

int csb_is_available(void) { return 1; }

// "Type\nmessage" for the current exception, which is cleared. Requires the GIL.
static char *csb_take_exception(void) {
    PyObject *exc = PyErr_GetRaisedException();
    if (exc == NULL) return csb_strdup("RuntimeError\nUnknown error");

    const char *type_name = "Exception";
    PyObject *name = PyType_GetName(Py_TYPE(exc));
    if (name != NULL) {
        const char *utf8 = PyUnicode_AsUTF8(name);
        if (utf8 != NULL) type_name = utf8;
    }
    PyErr_Clear();

    const char *message = "";
    PyObject *str = PyObject_Str(exc);
    if (str != NULL) {
        const char *utf8 = PyUnicode_AsUTF8(str);
        if (utf8 != NULL) message = utf8;
    }
    PyErr_Clear();

    size_t length = strlen(type_name) + 1 + strlen(message);
    char *result = malloc(length + 1);
    if (result != NULL) {
        strcpy(result, type_name);
        strcat(result, "\n");
        strcat(result, message);
    }
    Py_XDECREF(str);
    Py_XDECREF(name);
    Py_DECREF(exc);
    return result;
}

// MARK: - _csbridge

static PyObject *csbridge_write(PyObject *self, PyObject *args) {
    (void)self;
    int stream;
    PyObject *text;
    if (!PyArg_ParseTuple(args, "iU:write", &stream, &text)) return NULL;

    Py_ssize_t length = 0;
    const char *utf8 = PyUnicode_AsUTF8AndSize(text, &length);
    PyObject *encoded = NULL;
    if (utf8 == NULL) {
        // Lone surrogates can't be UTF-8; show replacement characters instead.
        PyErr_Clear();
        encoded = PyUnicode_AsEncodedString(text, "utf-8", "replace");
        if (encoded == NULL) return NULL;
        utf8 = PyBytes_AS_STRING(encoded);
        length = PyBytes_GET_SIZE(encoded);
    }
    if (csb_write_fn != NULL && length > 0) {
        csb_write_fn(stream, utf8, (size_t)length);
    }
    Py_XDECREF(encoded);
    Py_RETURN_NONE;
}

static PyObject *csbridge_readline(PyObject *self, PyObject *args) {
    (void)self;
    const char *prompt;
    if (!PyArg_ParseTuple(args, "s:readline", &prompt)) return NULL;
    if (csb_readline_fn == NULL) Py_RETURN_NONE;

    char *prompt_copy = csb_strdup(prompt);
    if (prompt_copy == NULL) return PyErr_NoMemory();

    char *line;
    Py_BEGIN_ALLOW_THREADS
    line = csb_readline_fn(prompt_copy);
    Py_END_ALLOW_THREADS
    free(prompt_copy);

    if (line == NULL) Py_RETURN_NONE;
    PyObject *result = PyUnicode_DecodeUTF8(line, (Py_ssize_t)strlen(line), "replace");
    free(line);
    return result;
}

static PyMethodDef csbridge_methods[] = {
    {"write", csbridge_write, METH_VARARGS, "write(stream, text): 1 = stdout, 2 = stderr."},
    {"readline", csbridge_readline, METH_VARARGS, "readline(prompt) -> str | None. Blocks until the UI answers."},
    {NULL, NULL, 0, NULL},
};

static struct PyModuleDef csbridge_module = {
    PyModuleDef_HEAD_INIT, "_csbridge", "Bridge to the CS app.", 0, csbridge_methods,
    NULL, NULL, NULL, NULL,
};

static PyObject *PyInit__csbridge(void) {
    return PyModule_Create(&csbridge_module);
}

// MARK: - Lifecycle

static int csb_fail_status(PyStatus status, char **error) {
    const char *message = status.err_msg != NULL ? status.err_msg : "unknown error";
    const char *function = status.func != NULL ? status.func : "Python";
    size_t length = strlen(function) + 2 + strlen(message);
    *error = malloc(length + 1);
    if (*error != NULL) {
        strcpy(*error, function);
        strcat(*error, ": ");
        strcat(*error, message);
    }
    return 1;
}

static int csb_fail_exception(char **error) {
    *error = csb_take_exception();
    return 1;
}

int csb_initialize(const char *home, const char *const *extra_paths, int extra_path_count,
                   const char *bootstrap_source, char **error) {
    *error = NULL;
    if (atomic_load(&csb_initialized)) return 0;

    if (PyImport_AppendInittab("_csbridge", PyInit__csbridge) != 0) {
        *error = csb_strdup("PyImport_AppendInittab failed");
        return 1;
    }

    PyPreConfig preconfig;
    PyPreConfig_InitIsolatedConfig(&preconfig);
    preconfig.utf8_mode = 1;
    PyStatus status = Py_PreInitialize(&preconfig);
    if (PyStatus_Exception(status)) return csb_fail_status(status, error);

    // Settings from https://docs.python.org/3.14/using/ios.html
    PyConfig config;
    PyConfig_InitIsolatedConfig(&config);
    config.buffered_stdio = 0;
    config.write_bytecode = 0;
    config.install_signal_handlers = 1;
    config.use_system_logger = 1;

    status = PyConfig_SetBytesString(&config, &config.home, home);
    if (PyStatus_Exception(status)) {
        PyConfig_Clear(&config);
        return csb_fail_status(status, error);
    }
    status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) return csb_fail_status(status, error);

    csb_run_thread_id = PyThread_get_thread_ident();

    PyObject *sys_path = PySys_GetObject("path");  // borrowed
    if (sys_path == NULL || !PyList_Check(sys_path)) {
        *error = csb_strdup("sys.path is missing");
        return 1;
    }
    for (int i = extra_path_count - 1; i >= 0; i--) {
        PyObject *path = PyUnicode_FromString(extra_paths[i]);
        if (path == NULL || PyList_Insert(sys_path, 0, path) != 0) {
            Py_XDECREF(path);
            return csb_fail_exception(error);
        }
        Py_DECREF(path);
    }

    // `_csruntime`: stdout/stderr/input wiring and the call wrapper.
    PyObject *module = PyImport_AddModuleRef("_csruntime");
    if (module == NULL) return csb_fail_exception(error);
    PyObject *globals = PyModule_GetDict(module);  // borrowed
    if (PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins()) != 0) {
        Py_DECREF(module);
        return csb_fail_exception(error);
    }
    PyObject *code = Py_CompileString(bootstrap_source, "<_csruntime>", Py_file_input);
    if (code == NULL) {
        Py_DECREF(module);
        return csb_fail_exception(error);
    }
    PyObject *result = PyEval_EvalCode(code, globals, globals);
    Py_DECREF(code);
    Py_DECREF(module);
    if (result == NULL) return csb_fail_exception(error);
    Py_DECREF(result);

    // Release the GIL so other threads (timers, csb_interrupt) can take it.
    csb_main_tstate = PyEval_SaveThread();
    atomic_store(&csb_initialized, 1);
    return 0;
}

// Builds `(module, function, *args)`. Returns a new reference, or NULL with an exception set.
static PyObject *csb_build_args(const char *module_name, const char *function,
                                const char *const *args, int arg_count) {
    PyObject *tuple = PyTuple_New(2 + arg_count);
    if (tuple == NULL) return NULL;
    for (int i = 0; i < 2 + arg_count; i++) {
        const char *text = i == 0 ? module_name : (i == 1 ? function : args[i - 2]);
        PyObject *item = PyUnicode_DecodeUTF8(text, (Py_ssize_t)strlen(text), "replace");
        if (item == NULL) {
            Py_DECREF(tuple);
            return NULL;
        }
        PyTuple_SET_ITEM(tuple, i, item);  // steals
    }
    return tuple;
}

// Runs `_csruntime.call(*call_args)` and returns its result as a malloc'ed string.
// Requires the GIL. Returns NULL with an exception set on failure.
static char *csb_call_locked(PyObject *call_args) {
    PyObject *runtime = PyImport_ImportModule("_csruntime");
    if (runtime == NULL) return NULL;
    PyObject *call = PyObject_GetAttrString(runtime, "call");
    Py_DECREF(runtime);
    if (call == NULL) return NULL;

    csb_call_active = 1;
    PyObject *result = PyObject_Call(call, call_args, NULL);
    csb_call_active = 0;
    Py_DECREF(call);
    if (result == NULL) return NULL;

    char *output = NULL;
    Py_ssize_t length = 0;
    const char *utf8 = PyUnicode_Check(result) ? PyUnicode_AsUTF8AndSize(result, &length) : NULL;
    if (utf8 != NULL) {
        output = csb_strdup_len(utf8, (size_t)length);
        if (output == NULL) PyErr_NoMemory();
    } else if (!PyErr_Occurred()) {
        PyErr_SetString(PyExc_TypeError, "_csruntime.call must return str");
    }
    Py_DECREF(result);
    return output;
}

char *csb_call(const char *module_name, const char *function, const char *const *args, int arg_count,
               char **error) {
    *error = NULL;
    if (!atomic_load(&csb_initialized)) {
        *error = csb_strdup("RuntimeError\nPython isn't running.");
        return NULL;
    }

    PyEval_RestoreThread(csb_main_tstate);

    char *output = NULL;
    PyObject *call_args = csb_build_args(module_name, function, args, arg_count);
    if (call_args != NULL) {
        output = csb_call_locked(call_args);
        Py_DECREF(call_args);
    }
    if (output == NULL) *error = csb_take_exception();

    // Drop a KeyboardInterrupt that was scheduled but never delivered.
    PyThreadState_SetAsyncExc(csb_run_thread_id, NULL);
    csb_main_tstate = PyEval_SaveThread();
    return output;
}

int csb_interrupt(void) {
    if (!atomic_load(&csb_initialized)) return 0;
    PyGILState_STATE gil = PyGILState_Ensure();
    int scheduled = 0;
    if (csb_call_active) {
        scheduled = PyThreadState_SetAsyncExc(csb_run_thread_id, PyExc_KeyboardInterrupt) == 1;
    }
    PyGILState_Release(gil);
    return scheduled;
}

#else  // Stub: no embedded Python on this platform.

static const char *csb_unavailable = "Python isn't available on this platform.";

int csb_is_available(void) { return 0; }

int csb_initialize(const char *home, const char *const *extra_paths, int extra_path_count,
                   const char *bootstrap_source, char **error) {
    (void)home; (void)extra_paths; (void)extra_path_count; (void)bootstrap_source;
    *error = csb_strdup(csb_unavailable);
    return 1;
}

char *csb_call(const char *module_name, const char *function, const char *const *args, int arg_count,
               char **error) {
    (void)module_name; (void)function; (void)args; (void)arg_count;
    char *message = malloc(strlen("RuntimeError\n") + strlen(csb_unavailable) + 1);
    if (message != NULL) {
        strcpy(message, "RuntimeError\n");
        strcat(message, csb_unavailable);
    }
    *error = message;
    return NULL;
}

int csb_interrupt(void) { return 0; }

#endif
