// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

protocol LXPSchema_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == LXPSchema.SchemaMetadata {}

protocol LXPSchema_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == LXPSchema.SchemaMetadata {}

protocol LXPSchema_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == LXPSchema.SchemaMetadata {}

protocol LXPSchema_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == LXPSchema.SchemaMetadata {}

extension LXPSchema {
  typealias SelectionSet = LXPSchema_SelectionSet

  typealias InlineFragment = LXPSchema_InlineFragment

  typealias MutableSelectionSet = LXPSchema_MutableSelectionSet

  typealias MutableInlineFragment = LXPSchema_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "BuildingArea": return LXPSchema.Objects.BuildingArea
      case "Class": return LXPSchema.Objects.Class
      case "ClassAttendance": return LXPSchema.Objects.ClassAttendance
      case "Classroom": return LXPSchema.Objects.Classroom
      case "Discipline": return LXPSchema.Objects.Discipline
      case "DisciplineTopic": return LXPSchema.Objects.DisciplineTopic
      case "DisciplineTopicContent": return LXPSchema.Objects.DisciplineTopicContent
      case "GetStudentTopicPayload": return LXPSchema.Objects.GetStudentTopicPayload
      case "InfoDisciplineTopicContentBlock": return LXPSchema.Objects.InfoDisciplineTopicContentBlock
      case "LearningGroup": return LXPSchema.Objects.LearningGroup
      case "Query": return LXPSchema.Objects.Query
      case "RefreshTokenPayload": return LXPSchema.Objects.RefreshTokenPayload
      case "SignInPayload": return LXPSchema.Objects.SignInPayload
      case "Specialty": return LXPSchema.Objects.Specialty
      case "Student": return LXPSchema.Objects.Student
      case "StudentAvailableTasksPayload": return LXPSchema.Objects.StudentAvailableTasksPayload
      case "StudentContentBlock": return LXPSchema.Objects.StudentContentBlock
      case "StudentDiscipline": return LXPSchema.Objects.StudentDiscipline
      case "StudentDisciplinesByClassesPayload": return LXPSchema.Objects.StudentDisciplinesByClassesPayload
      case "StudentLearningGroup": return LXPSchema.Objects.StudentLearningGroup
      case "StudentSpecialty": return LXPSchema.Objects.StudentSpecialty
      case "StudentSuborganization": return LXPSchema.Objects.StudentSuborganization
      case "StudentTopic": return LXPSchema.Objects.StudentTopic
      case "Suborganization": return LXPSchema.Objects.Suborganization
      case "TaskDisciplineTopicContentBlock": return LXPSchema.Objects.TaskDisciplineTopicContentBlock
      case "Teacher": return LXPSchema.Objects.Teacher
      case "TestDisciplineTopicContentBlock": return LXPSchema.Objects.TestDisciplineTopicContentBlock
      case "User": return LXPSchema.Objects.User
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}