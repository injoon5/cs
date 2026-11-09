import Foundation

/// Scheduler configuration.
///
/// Defaults match FSRS-6 as shipped in open-spaced-repetition/py-fsrs 6.3.2
/// (`fsrs/scheduler.py`: `DEFAULT_PARAMETERS`, 21 weights, retention 0.9,
/// learning steps 1m 10m, relearning step 10m, max interval 36500 days, fuzz on).
public struct FSRSParameters: Sendable, Codable, Hashable {
    public static let defaultWeights: [Double] = [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666,
        0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658,
        0.1542,
    ]

    /// 21 FSRS-6 weights. A missing index falls back to the default weight.
    public var weights: [Double]
    public var desiredRetention: Double
    /// Seconds.
    public var learningSteps: [TimeInterval]
    /// Seconds.
    public var relearningSteps: [TimeInterval]
    /// Days.
    public var maximumInterval: Int
    public var enableFuzz: Bool

    public init(
        weights: [Double] = FSRSParameters.defaultWeights,
        desiredRetention: Double = 0.9,
        learningSteps: [TimeInterval] = [60, 600],
        relearningSteps: [TimeInterval] = [600],
        maximumInterval: Int = 36500,
        enableFuzz: Bool = true
    ) {
        self.weights = weights
        self.desiredRetention = desiredRetention
        self.learningSteps = learningSteps
        self.relearningSteps = relearningSteps
        self.maximumInterval = maximumInterval
        self.enableFuzz = enableFuzz
    }

    public static let `default` = FSRSParameters()

    func w(_ index: Int) -> Double {
        weights.indices.contains(index) ? weights[index] : Self.defaultWeights[index]
    }
}

/// Small deterministic generator (SplitMix64) for reproducible fuzz in tests.
public struct SeededGenerator: RandomNumberGenerator, Sendable, Hashable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
