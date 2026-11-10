#if DEBUG && canImport(UIKit)
import Foundation

/// Launch arguments for checks without UI automation:
///
///     -PlaygroundSeed samples|empty   write the sample files, or delete every file
///     -PlaygroundOpen <name>          open a file at launch
///     -PlaygroundFocus 1              focus the editor (keyboard up)
///     -PlaygroundSelect <loc,len>     then select a range
///     -PlaygroundType <text>          then type text through the editor's keyboard path (\\n for return)
///     -PlaygroundRun 1                run the file
///     -PlaygroundStopAfter <seconds>  press Stop after a delay
///     -PlaygroundInput <text>         answer the first input() prompt
@MainActor
enum PlaygroundLaunchOptions {
    private static var defaults: UserDefaults { .standard }

    static func prepare(_ store: PlaygroundStore) -> URL? {
        switch defaults.string(forKey: "PlaygroundSeed") {
        case "empty":
            for file in store.files { store.delete(file) }
        case "samples":
            for file in store.files { store.delete(file) }
            for (name, code) in samples.reversed() {
                store.create(named: name, contents: code)
            }
        default:
            break
        }
        guard let name = defaults.string(forKey: "PlaygroundOpen") else { return nil }
        return store.files.first { $0.name == name }?.url
    }

    static func drive(session: RunSession, code: () -> String, focus: () -> Void) async {
        guard defaults.string(forKey: "PlaygroundOpen") != nil else { return }
        try? await Task.sleep(for: .milliseconds(600))
        if defaults.bool(forKey: "PlaygroundFocus") {
            focus()
            try? await Task.sleep(for: .milliseconds(800))
            if let select = defaults.string(forKey: "PlaygroundSelect") {
                NotificationCenter.default.post(name: .init("CodeEditorDebugSelect"), object: nil, userInfo: ["range": select])
                try? await Task.sleep(for: .milliseconds(300))
            }
            if let text = defaults.string(forKey: "PlaygroundType") {
                NotificationCenter.default.post(name: .init("CodeEditorDebugType"), object: nil, userInfo: ["text": text])
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
        guard defaults.bool(forKey: "PlaygroundRun") else { return }
        let stopAfter = defaults.double(forKey: "PlaygroundStopAfter")
        if stopAfter > 0 {
            Task {
                try? await Task.sleep(for: .seconds(stopAfter))
                await session.stop()
            }
        }
        if let input = defaults.string(forKey: "PlaygroundInput") {
            Task {
                while session.inputPrompt == nil {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                try? await Task.sleep(for: .milliseconds(500))
                session.inputText = input
                session.submitInput()
            }
        }
        await session.run(code())
    }

    static let samples: [(String, String)] = [
        ("Highlighting", """
        # Highlighting check: strings, comments, decorators, f-strings
        import functools
        from dataclasses import dataclass

        MAX_DEPTH = 10  # a constant


        @dataclass
        class Node:
            value: int
            left: "Node | None" = None


        @functools.cache
        def fib(n: int) -> int:
            \"\"\"Return the n-th Fibonacci number.\"\"\"
            if n < 2:
                return n
            return fib(n - 1) + fib(n - 2)


        name = 'Ada'
        values = [fib(i) for i in range(MAX_DEPTH)]
        print(f"Hello, {name}! {len(values)} values: {values[-1]:>5}\\n")
        print(r"raw \\d+", b"bytes", 0x1F, 3.14, True, None)
        node = Node(1)
        print(node.value is not None and not False)
        """),
        ("Output", """
        def bubble_sort(a):
            n = len(a)
            for i in range(n):
                for j in range(n - i - 1):
                    if a[j] > a[j + 1]:
                        a[j], a[j + 1] = a[j + 1], a[j]
            return a


        data = [5, 2, 9, 1, 7, 3]
        print("before:", data)
        print("after: ", bubble_sort(data[:]))
        for k in range(1, 6):
            print(f"{k:>2} squared is {k * k:>3}")
        """),
        ("Error", """
        def middle(xs):
            return xs[len(xs) // 2 + 3]


        print("finding the middle")
        print(middle([1, 2, 3]))
        """),
        ("Loop", """
        import time

        i = 0
        while True:
            print("tick", i)
            i += 1
            time.sleep(0.2)
        """),
        ("Greeting", """
        name = input("Name: ")
        print(f"Hello, {name}")
        """),
        ("Long", (1...200).map { "print(\"line \($0)\")  # " + String(repeating: "x", count: $0 % 30) }.joined(separator: "\n")),
    ]
}
#endif
