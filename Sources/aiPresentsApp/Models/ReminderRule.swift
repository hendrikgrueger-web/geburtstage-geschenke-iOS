import Foundation
import SwiftData

@Model
final class ReminderRule {
    var id: UUID
    var leadDays: [Int]
    var quietHoursStart: Int // Hour 0-23
    var quietHoursEnd: Int // Hour 0-23
    var enabled: Bool

    init(
        id: UUID = UUID(),
        leadDays: [Int] = [30, 14, 7, 2],
        quietHoursStart: Int = 22,
        quietHoursEnd: Int = 8,
        enabled: Bool = true
    ) {
        self.id = id
        self.leadDays = leadDays
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.enabled = enabled
    }
}
