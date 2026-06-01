import Foundation
import SwiftUI

enum MockData {
    static let profile = Profile(
        lastName: "",
        firstName: "",
        middleName: "",
        email: "",
        avatar: nil,
        organization: "",
        department: "",
        group: "",
        speciality: "",
        learningGroupId: nil,
        groupMates: []
    )

    static let disciplines: [Discipline] = []
    static let assignments: [Assignment] = []
}
