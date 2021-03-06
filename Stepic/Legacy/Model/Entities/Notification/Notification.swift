//
//  Notification.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 26.09.2017.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import CoreData
import Foundation
import PromiseKit
import SwiftyJSON

final class Notification: NSManagedObject, JSONSerializable, IDFetchable {
    typealias IdType = Int

    required convenience init(json: JSON) {
        self.init()
        initialize(json)
    }

    func initialize(_ json: JSON) {
        id = json["id"].intValue
        htmlText = json["html_text"].stringValue
        time = Parser.shared.dateFromTimedateJSON(json["time"])
        isMuted = json["is_muted"].boolValue
        isFavorite = json["is_favorite"].boolValue

        managedStatus = json["is_unread"].boolValue ? NotificationStatus.unread.rawValue : NotificationStatus.read.rawValue
        managedType = json["type"].stringValue
        managedAction = json["action"].stringValue

        level = json["level"].stringValue
        priority = json["priority"].stringValue
    }

    func update(json: JSON) {
        initialize(json)
    }

    var json: JSON {
        [
            "id": id as AnyObject,
            "html_text": htmlText as AnyObject,
            "is_unread": (status == .unread) as AnyObject,
            "is_muted": isMuted as AnyObject,
            "is_favorite": isFavorite as AnyObject,
            "type": type.rawValue as AnyObject,
            "action": action.rawValue as AnyObject,
            "level": level as AnyObject,
            "priority": priority as AnyObject
        ]
    }
}

enum NotificationStatus: String {
    case unread = "unread"
    case read = "read"
}

enum NotificationType: String {
    var localizedName: String {
        switch self {
        case .comments: return NSLocalizedString("NotificationsComments", comment: "")
        case .review: return NSLocalizedString("NotificationsReviews", comment: "")
        case .teach: return NSLocalizedString("NotificationsTeaching", comment: "")
        case .`default`: return NSLocalizedString("NotificationsOther", comment: "")
        case .learn: return NSLocalizedString("NotificationsLearning", comment: "")
        }
    }

    case comments = "comments"
    case learn = "learn"
    case `default` = "default"
    case review = "review"
    case teach = "teach"
}

enum NotificationAction: String {
    case opened = "opened"
    case replied = "replied"
    case softDeadlineApproach = "soft_deadline_approach"
    case hardDeadlineApproach = "hard_deadline_approach"
    case unknown = "unknown"
    case issuedCertificate = "issued_certificate"
}
