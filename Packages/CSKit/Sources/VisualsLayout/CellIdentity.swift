import Foundation

/// Gives array cells ids that follow values between frames, so a swap animates as two moves
/// instead of two value changes.
///
/// Each new cell takes the id of an unmatched cell with the same value in the previous frame,
/// nearest index first (ties go to the lower new index, then the lower old index).
/// Values with no match get fresh ids.
public struct CellIdentityMatcher: Sendable {
    private var nextID = 0
    private var previousValues: [String] = []
    private var previousIDs: [Int] = []

    public init() {}

    /// Ids for `values`, given every frame passed before. Call once per frame, in order.
    public mutating func assign(_ values: [String]) -> [Int] {
        var ids = [Int](repeating: -1, count: values.count)
        var used = [Bool](repeating: false, count: previousValues.count)

        // Unchanged positions first: the common case, and always the nearest match.
        for i in 0..<min(values.count, previousValues.count) where values[i] == previousValues[i] {
            ids[i] = previousIDs[i]
            used[i] = true
        }

        // Group what's left by value.
        var oldByValue: [String: [Int]] = [:]
        for (i, value) in previousValues.enumerated() where !used[i] {
            oldByValue[value, default: []].append(i)
        }
        if !oldByValue.isEmpty {
            var newByValue: [String: [Int]] = [:]
            for (j, value) in values.enumerated() where ids[j] < 0 && oldByValue[value] != nil {
                newByValue[value, default: []].append(j)
            }
            for (value, newIndices) in newByValue {
                guard let oldIndices = oldByValue[value] else { continue }
                if oldIndices.count == 1 && newIndices.count == 1 {
                    ids[newIndices[0]] = previousIDs[oldIndices[0]]
                    continue
                }
                var pairs: [(distance: Int, new: Int, old: Int)] = []
                pairs.reserveCapacity(oldIndices.count * newIndices.count)
                for j in newIndices {
                    for i in oldIndices { pairs.append((abs(i - j), j, i)) }
                }
                pairs.sort { ($0.distance, $0.new, $0.old) < ($1.distance, $1.new, $1.old) }
                var oldTaken = Set<Int>()
                for pair in pairs where ids[pair.new] < 0 && !oldTaken.contains(pair.old) {
                    ids[pair.new] = previousIDs[pair.old]
                    oldTaken.insert(pair.old)
                }
            }
        }

        for j in ids.indices where ids[j] < 0 {
            ids[j] = nextID
            nextID += 1
        }
        // Fresh ids must never collide with carried ones.
        if let highest = ids.max(), highest >= nextID { nextID = highest + 1 }

        previousValues = values
        previousIDs = ids
        return ids
    }
}
