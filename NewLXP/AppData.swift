import Foundation
import SwiftUI

enum MockData {
    static let profile = Profile(
        lastName: "",
        firstName: "",
        middleName: "",
        email: "",
        organization: "",
        department: "",
        group: "",
        speciality: "",
        learningGroupId: nil,
        groupMates: []
    )

    static let disciplines: [Discipline] = []
    static let assignments: [Assignment] = []
    static let diary: [DiaryEntry] = []
}
