//
//  NotificationPreferencesContainer.swift
//  Stepic
//
//  Created by Alexander Karpov on 23.11.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Legacy class")
final class NotificationPreferencesContainer {
    private let streakNotificationsStorageManager: StreakNotificationsStorageManagerProtocol = StreakNotificationsStorageManager()

    var allowStreaksNotifications: Bool {
        get {
            self.streakNotificationsStorageManager.isStreakNotificationsEnabled
        }
        set {
            self.streakNotificationsStorageManager.isStreakNotificationsEnabled = newValue
        }
    }

    var streaksNotificationStartHourUTC: Int {
        get {
            self.streakNotificationsStorageManager.streakNotificationsStartHourUTC
        }
        set {
            self.streakNotificationsStorageManager.streakNotificationsStartHourUTC = newValue
        }
    }

    var streaksNotificationStartHourLocal: Int {
        self.streakNotificationsStorageManager.streakNotificationsStartHourLocal
    }
}
