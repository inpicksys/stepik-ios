import Foundation
import PromiseKit

protocol CourseListNetworkServiceProtocol: AnyObject {
    func fetch(page: Int) -> Promise<([Course], Meta)>
}

class BaseCourseListNetworkService {
    let coursesAPI: CoursesAPI

    init(coursesAPI: CoursesAPI) {
        self.coursesAPI = coursesAPI
    }

    enum Error: Swift.Error {
        case fetchFailed
    }
}

final class UserCoursesCourseListNetworkService: BaseCourseListNetworkService, CourseListNetworkServiceProtocol {
    let type: CourseListType
    private let userCoursesAPI: UserCoursesAPI

    private var fetchParams: (isArchived: Bool?, isFavorite: Bool?) {
        if self.type is EnrolledCourseListType {
            return (false, nil)
        } else if self.type is FavoriteCourseListType {
            return (nil, true)
        } else if self.type is ArchivedCourseListType {
            return (true, nil)
        } else {
            fatalError("Unsupported course list type")
        }
    }

    init(
        type: CourseListType,
        coursesAPI: CoursesAPI,
        userCoursesAPI: UserCoursesAPI
    ) {
        self.type = type
        self.userCoursesAPI = userCoursesAPI
        super.init(coursesAPI: coursesAPI)
    }

    func fetch(page: Int = 1) -> Promise<([Course], Meta)> {
        Promise { seal in
            let (isArchived, isFavorite) = self.fetchParams
            self.userCoursesAPI.retrieve(page: page, isArchived: isArchived, isFavorite: isFavorite).then {
                userCoursesInfo -> Promise<([Course], [UserCourse], Meta)> in
                // Cause we can't pass empty ids list to courses endpoint
                if userCoursesInfo.0.isEmpty {
                    return Promise.value(([], [], Meta.oneAndOnlyPage))
                }

                return self.coursesAPI
                    .retrieve(ids: userCoursesInfo.0.map { $0.courseID })
                    .map { ($0, userCoursesInfo.0, userCoursesInfo.1) }
            }.done { courses, info, meta in
                let orderedCourses = courses.reordered(
                    order: info.map { $0.courseID },
                    transform: { $0.id }
                )

                let userCourseByCourseID: [Course.IdType: UserCourse] = info.reduce(into: [:], { $0[$1.courseID] = $1 })
                for course in orderedCourses {
                    if let userCourse = userCourseByCourseID[course.id] {
                        userCourse.course = course
                    }
                }
                CoreDataHelper.shared.save()

                seal.fulfill((orderedCourses, meta))
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }
}

final class PopularCourseListNetworkService: BaseCourseListNetworkService, CourseListNetworkServiceProtocol {
    let type: PopularCourseListType

    init(type: PopularCourseListType, coursesAPI: CoursesAPI) {
        self.type = type
        super.init(coursesAPI: coursesAPI)
    }

    func fetch(page: Int = 1) -> Promise<([Course], Meta)> {
        Promise { seal in
            self.coursesAPI.retrieve(
                isCataloged: true,
                order: .activityDesc,
                language: self.type.language.popularCoursesParameter,
                page: page
            ).done { result in
                seal.fulfill(result)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }
}

final class TagCourseListNetworkService: BaseCourseListNetworkService, CourseListNetworkServiceProtocol {
    let type: TagCourseListType

    init(type: TagCourseListType, coursesAPI: CoursesAPI) {
        self.type = type
        super.init(coursesAPI: coursesAPI)
    }

    func fetch(page: Int = 1) -> Promise<([Course], Meta)> {
        Promise { seal in
            self.coursesAPI.retrieve(
                tag: self.type.id,
                order: .activityDesc,
                language: self.type.language.languageString,
                page: page
            ).done { result in
                seal.fulfill(result)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }
}

final class CollectionCourseListNetworkService: BaseCourseListNetworkService, CourseListNetworkServiceProtocol {
    let type: CollectionCourseListType

    init(type: CollectionCourseListType, coursesAPI: CoursesAPI) {
        self.type = type
        super.init(coursesAPI: coursesAPI)
    }

    func fetch(page: Int = 1) -> Promise<([Course], Meta)> {
        let finalMeta = Meta.oneAndOnlyPage
        return Promise { seal in
            self.coursesAPI.retrieve(
                ids: self.type.ids
            ).done { courses in
                let courses = courses.reordered(order: self.type.ids, transform: { $0.id })
                seal.fulfill((courses, finalMeta))
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }
}

final class SearchResultCourseListNetworkService: BaseCourseListNetworkService, CourseListNetworkServiceProtocol {
    let type: SearchResultCourseListType
    private let searchResultsAPI: SearchResultsAPI

    init(
        type: SearchResultCourseListType,
        coursesAPI: CoursesAPI,
        searchResultsAPI: SearchResultsAPI
    ) {
        self.type = type
        self.searchResultsAPI = searchResultsAPI
        super.init(coursesAPI: coursesAPI)
    }

    func fetch(page: Int) -> Promise<([Course], Meta)> {
        Promise { seal in
            self.searchResultsAPI.searchCourse(
                query: self.type.query,
                language: self.type.language,
                page: page
            ).then { result, meta -> Promise<([Course.IdType], Meta, [Course])> in
                let ids = result.compactMap { $0.courseId }
                return self.coursesAPI
                    .retrieve(ids: ids)
                    .map { (ids, meta, $0) }
            }.done { ids, meta, courses in
                let resultCourses = courses.reordered(order: ids, transform: { $0.id })
                seal.fulfill((resultCourses, meta))
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }
}

final class TeacherCourseListNetworkService: BaseCourseListNetworkService, CourseListNetworkServiceProtocol {
    let type: TeacherCourseListType

    init(type: TeacherCourseListType, coursesAPI: CoursesAPI) {
        self.type = type
        super.init(coursesAPI: coursesAPI)
    }

    func fetch(page: Int) -> Promise<([Course], Meta)> {
        Promise { seal in
            self.coursesAPI.retrieve(
                teacher: self.type.teacherID,
                order: .popularityDesc,
                page: page
            ).done { result in
                seal.fulfill(result)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }
}
