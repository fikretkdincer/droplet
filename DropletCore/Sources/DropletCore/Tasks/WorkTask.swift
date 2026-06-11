import Foundation

/// A work task that users can track time against.
public struct WorkTask: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var targetMinutes: Int?
    public var minutesWorked: Int
    public var isArchived: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        targetMinutes: Int? = nil,
        minutesWorked: Int = 0,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetMinutes = targetMinutes
        self.minutesWorked = max(0, minutesWorked)
        self.isArchived = isArchived
        self.createdAt = createdAt
    }

    /// Progress ratio (0.0 to 1.0+) for timed tasks, nil for unlimited.
    public var progress: Double? {
        guard let target = targetMinutes, target > 0 else { return nil }
        return Double(minutesWorked) / Double(target)
    }

    /// Whether the task has reached its target. Unlimited tasks never complete.
    public var isComplete: Bool {
        guard let target = targetMinutes else { return false }
        return minutesWorked >= target
    }
}
