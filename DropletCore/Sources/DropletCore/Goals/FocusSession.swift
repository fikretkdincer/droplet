import Foundation

/// Device or system surface that created a focus session.
public enum FocusSessionSource: String, CaseIterable, Codable, Sendable {
    case mac
    case iPhone
    case iPad
    case watch
    case widget
    case siri
    case manual
}

/// A syncable record of focused time.
public struct FocusSession: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var mode: TimerMode
    public var source: FocusSessionSource
    public var startDate: Date
    public var endDate: Date
    public var taskID: UUID?
    public var note: String?

    public init(
        id: UUID = UUID(),
        mode: TimerMode,
        source: FocusSessionSource,
        startDate: Date,
        endDate: Date,
        taskID: UUID? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.mode = mode
        self.source = source
        self.startDate = startDate
        self.endDate = endDate
        self.taskID = taskID
        self.note = note
    }

    public var durationSeconds: Int {
        max(0, Int(endDate.timeIntervalSince(startDate)))
    }

    public var wholeMinutes: Int {
        durationSeconds / 60
    }
}
