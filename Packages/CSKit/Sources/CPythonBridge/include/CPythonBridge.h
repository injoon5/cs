// Thin C layer over the embedded CPython interpreter. Used only by the Runtime
// target. No Python types appear here, so Swift never needs Python.h.
//
// Threading: csb_initialize and csb_call must run on the same dedicated thread
// (the "run thread"). csb_interrupt may be called from any thread.

#ifndef CPYTHONBRIDGE_H
#define CPYTHONBRIDGE_H

#include <stddef.h>

#pragma clang assume_nonnull begin

/// Receives `_csbridge.write(stream, text)`. `text` is UTF-8, not NUL-terminated.
/// Called on the run thread while it holds the GIL; return quickly.
typedef void (*csb_write_callback)(int stream, const char *text, size_t length);

/// Receives `_csbridge.readline(prompt)`. Called on the run thread with the GIL
/// released; may block. Returns a `malloc`ed UTF-8 string that the bridge frees,
/// or NULL for end of input.
typedef char *_Nullable (*csb_readline_callback)(const char *prompt);

/// 1 when this build embeds CPython, 0 for the stub (macOS, Linux).
int csb_is_available(void);

/// Sets the I/O callbacks. Call before csb_initialize.
void csb_set_callbacks(csb_write_callback write, csb_readline_callback readline);

/// Starts the interpreter on the calling thread: isolated config, `home` as
/// PYTHONHOME, `extra_paths` prepended to sys.path, then runs `bootstrap_source`
/// as the module `_csruntime`. Leaves the GIL released.
/// Returns 0 on success. On failure returns nonzero and sets `*error` to a
/// `malloc`ed message.
int csb_initialize(const char *home,
                   const char *_Nonnull const *_Nullable extra_paths,
                   int extra_path_count,
                   const char *bootstrap_source,
                   char *_Nullable *_Nonnull error);

/// Calls `_csruntime.call(module, function, *args)` with string arguments and
/// returns its string result (`malloc`ed). Runs user code; blocks until done.
/// Returns NULL and sets `*error` only if the call machinery itself failed.
char *_Nullable csb_call(const char *module,
                         const char *function,
                         const char *_Nonnull const *_Nullable args,
                         int arg_count,
                         char *_Nullable *_Nonnull error);

/// Raises KeyboardInterrupt in the run thread if a call is in progress.
/// Takes the GIL, so it can wait while the run thread is inside a long C call.
/// Returns 1 when an interrupt was scheduled.
int csb_interrupt(void);

#pragma clang assume_nonnull end

#endif
