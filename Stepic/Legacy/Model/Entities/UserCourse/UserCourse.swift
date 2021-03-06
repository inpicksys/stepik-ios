import CoreData
import Foundation
import SwiftyJSON

final class UserCourse: NSManagedObject, JSONSerializable, IDFetchable {
    typealias IdType = Int

    var json: JSON {
        [
            JSONKey.isFavorite.rawValue: self.isFavorite,
            JSONKey.isArchived.rawValue: self.isArchived,
            JSONKey.course.rawValue: self.courseID
        ]
    }

    required convenience init(json: JSON) {
        self.init()
        self.update(json: json)
        NotificationCenter.default.post(name: .userCourseDidCreateNotification, object: self)
    }

    func update(json: JSON) {
        self.id = json[JSONKey.id.rawValue].intValue
        self.userID = json[JSONKey.user.rawValue].intValue
        self.courseID = json[JSONKey.course.rawValue].intValue
        self.isFavorite = json[JSONKey.isFavorite.rawValue].boolValue
        self.isArchived = json[JSONKey.isArchived.rawValue].boolValue
        self.lastViewed = Parser.shared.dateFromTimedateJSON(json[JSONKey.lastViewed.rawValue]) ?? Date()
    }

    func hasEqualId(json: JSON) -> Bool {
        self.id == json[JSONKey.id.rawValue].int
    }

    override func prepareForDeletion() {
        super.prepareForDeletion()
        NotificationCenter.default.post(name: .userCourseDidDeleteNotification, object: self)
    }

    override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)

        if Self.observableKeys.contains(key) {
            NotificationCenter.default.post(name: .userCourseDidChangeNotification, object: self)
        }
    }

    enum JSONKey: String {
        case id
        case user
        case course
        case isFavorite = "is_favorite"
        case isArchived = "is_archived"
        case lastViewed = "last_viewed"
    }
}

extension Foundation.Notification.Name {
    static let userCourseDidChangeNotification = NSNotification.Name("userCourseDidChangeNotification")
    static let userCourseDidCreateNotification = NSNotification.Name("userCourseDidCreateNotification")
    static let userCourseDidDeleteNotification = NSNotification.Name("userCourseDidDeleteNotification")
}
