import Foundation

protocol CourseListDataBackUpdateServiceDelegate: AnyObject {
    /// Tells the delegate that the specified course is updated.
    func courseListDataBackUpdateService(
        _ service: CourseListDataBackUpdateServiceProtocol,
        didUpdateCourse course: Course
    )
    /// Tells the delegate that the specified course is deleted.
    func courseListDataBackUpdateService(
        _ service: CourseListDataBackUpdateServiceProtocol,
        didDeleteCourse course: Course
    )
    /// Tells the delegate that the specified course is inserted.
    func courseListDataBackUpdateService(
        _ service: CourseListDataBackUpdateServiceProtocol,
        didInsertCourse course: Course
    )
    /// Tells the delegate that the specified user course is updated.
    func courseListDataBackUpdateService(
        _ service: CourseListDataBackUpdateServiceProtocol,
        didUpdateUserCourse userCourse: UserCourse
    )
}

protocol CourseListDataBackUpdateServiceProtocol: AnyObject {
    var delegate: CourseListDataBackUpdateServiceDelegate? { get set }
}

final class CourseListDataBackUpdateService: CourseListDataBackUpdateServiceProtocol {
    private let courseListType: CourseListType
    private let dataBackUpdateService: DataBackUpdateServiceProtocol

    weak var delegate: CourseListDataBackUpdateServiceDelegate?

    private var isUserCoursesCourseListType: Bool {
        self.courseListType is EnrolledCourseListType
            || self.courseListType is FavoriteCourseListType
            || self.courseListType is ArchivedCourseListType
    }

    init(
        courseListType: CourseListType,
        dataBackUpdateService: DataBackUpdateServiceProtocol
    ) {
        self.courseListType = courseListType
        self.dataBackUpdateService = dataBackUpdateService
        self.dataBackUpdateService.delegate = self
    }
}

extension CourseListDataBackUpdateService: DataBackUpdateServiceDelegate {
    func dataBackUpdateService(
        _ dataBackUpdateService: DataBackUpdateService,
        didReport update: DataBackUpdateDescription,
        for target: DataBackUpdateTarget
    ) {
        guard case .course(let course) = target else {
            return
        }

        // If progress state was updated then refresh course with data
        if update.contains(.progress) {
            self.delegate?.courseListDataBackUpdateService(self, didUpdateCourse: course)
        }

        if update.contains(.enrollment) {
            self.handleCourse(course, didUpdateEnrollment: update)
        }

        // If isArchived or isFavorite state was updated then handle specified update and refresh course list
        if update.contains(.courseIsArchived) || update.contains(.courseIsFavorite) {
            self.handleCourse(course, didUpdateUserCourses: update)
        }
    }

    func dataBackUpdateService(
        _ dataBackUpdateService: DataBackUpdateService,
        didReport refreshedTarget: DataBackUpdateTarget
    ) {
        guard case .userCourse(let userCourse) = refreshedTarget else {
            return
        }

        self.delegate?.courseListDataBackUpdateService(self, didUpdateUserCourse: userCourse)
    }

    // MARK: Private Helpers

    private func handleCourse(_ course: Course, didUpdateEnrollment update: DataBackUpdateDescription) {
        if self.isUserCoursesCourseListType {
            if course.enrolled && self.courseListType is EnrolledCourseListType {
                self.delegate?.courseListDataBackUpdateService(self, didInsertCourse: course)
            } else {
                self.delegate?.courseListDataBackUpdateService(self, didDeleteCourse: course)
            }
        } else {
            self.delegate?.courseListDataBackUpdateService(self, didUpdateCourse: course)
        }
    }

    private func handleCourse(_ course: Course, didUpdateUserCourses update: DataBackUpdateDescription) {
        guard course.enrolled, self.isUserCoursesCourseListType else {
            return
        }

        if update.contains(.courseIsArchived) {
            if self.courseListType is EnrolledCourseListType {
                if course.isArchived {
                    self.delegate?.courseListDataBackUpdateService(self, didDeleteCourse: course)
                } else {
                    self.delegate?.courseListDataBackUpdateService(self, didInsertCourse: course)
                }
            } else if self.courseListType is ArchivedCourseListType {
                if course.isArchived {
                    self.delegate?.courseListDataBackUpdateService(self, didInsertCourse: course)
                } else {
                    self.delegate?.courseListDataBackUpdateService(self, didDeleteCourse: course)
                }
            }
        }

        if update.contains(.courseIsFavorite) {
            if self.courseListType is FavoriteCourseListType {
                if course.isFavorite {
                    self.delegate?.courseListDataBackUpdateService(self, didInsertCourse: course)
                } else {
                    self.delegate?.courseListDataBackUpdateService(self, didDeleteCourse: course)
                }
            }
        }
    }
}
