// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetStudentDisciplineQuery: GraphQLQuery {
    static let operationName: String = "GetStudentDiscipline"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetStudentDiscipline($input: GetStudentDisciplineInput!) { getStudentDiscipline(input: $input) { __typename discipline { __typename id name code studyHoursCount maxScore } learningGroupId sectionId disciplineScore averageAttendance { __typename allAttendance currentAttendance currentExistAttendance percent } averageScores { __typename currentScores maxScore grade deadlineScores } topics { __typename topicId topic { __typename id name order isCheckPoint maxScore studyHoursCount } status topicScore } } }"#
      ))

    public var input: GetStudentDisciplineInput

    public init(input: GetStudentDisciplineInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("getStudentDiscipline", GetStudentDiscipline.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetStudentDisciplineQuery.Data.self
      ] }

      var getStudentDiscipline: GetStudentDiscipline { __data["getStudentDiscipline"] }

      /// GetStudentDiscipline
      ///
      /// Parent Type: `StudentDiscipline`
      struct GetStudentDiscipline: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.StudentDiscipline }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("discipline", Discipline.self),
          .field("learningGroupId", LXPSchema.UUID?.self),
          .field("sectionId", LXPSchema.UUID?.self),
          .field("disciplineScore", Double.self),
          .field("averageAttendance", AverageAttendance.self),
          .field("averageScores", AverageScores.self),
          .field("topics", [Topic].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetStudentDisciplineQuery.Data.GetStudentDiscipline.self
        ] }

        var discipline: Discipline { __data["discipline"] }
        var learningGroupId: LXPSchema.UUID? { __data["learningGroupId"] }
        var sectionId: LXPSchema.UUID? { __data["sectionId"] }
        @available(*, deprecated, message: "Используйте scoreForAnsweredTasks")
        var disciplineScore: Double { __data["disciplineScore"] }
        var averageAttendance: AverageAttendance { __data["averageAttendance"] }
        var averageScores: AverageScores { __data["averageScores"] }
        var topics: [Topic] { __data["topics"] }

        /// GetStudentDiscipline.Discipline
        ///
        /// Parent Type: `Discipline`
        struct Discipline: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Discipline }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.UUID.self),
            .field("name", String.self),
            .field("code", String?.self),
            .field("studyHoursCount", Double.self),
            .field("maxScore", Double.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetStudentDisciplineQuery.Data.GetStudentDiscipline.Discipline.self
          ] }

          var id: LXPSchema.UUID { __data["id"] }
          var name: String { __data["name"] }
          var code: String? { __data["code"] }
          var studyHoursCount: Double { __data["studyHoursCount"] }
          var maxScore: Double { __data["maxScore"] }
        }

        /// GetStudentDiscipline.AverageAttendance
        ///
        /// Parent Type: `LearningGroupDisciplineAttendance`
        struct AverageAttendance: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.LearningGroupDisciplineAttendance }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("allAttendance", Double.self),
            .field("currentAttendance", Double.self),
            .field("currentExistAttendance", Double.self),
            .field("percent", Double.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetStudentDisciplineQuery.Data.GetStudentDiscipline.AverageAttendance.self
          ] }

          var allAttendance: Double { __data["allAttendance"] }
          var currentAttendance: Double { __data["currentAttendance"] }
          var currentExistAttendance: Double { __data["currentExistAttendance"] }
          var percent: Double { __data["percent"] }
        }

        /// GetStudentDiscipline.AverageScores
        ///
        /// Parent Type: `LearningGroupDisciplineScores`
        struct AverageScores: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.LearningGroupDisciplineScores }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("currentScores", Double.self),
            .field("maxScore", Double.self),
            .field("grade", Double.self),
            .field("deadlineScores", Double.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetStudentDisciplineQuery.Data.GetStudentDiscipline.AverageScores.self
          ] }

          var currentScores: Double { __data["currentScores"] }
          var maxScore: Double { __data["maxScore"] }
          var grade: Double { __data["grade"] }
          var deadlineScores: Double { __data["deadlineScores"] }
        }

        /// GetStudentDiscipline.Topic
        ///
        /// Parent Type: `StudentTopic`
        struct Topic: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.StudentTopic }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("topicId", LXPSchema.UUID.self),
            .field("topic", Topic.self),
            .field("status", GraphQLEnum<LXPSchema.TopicStatus>?.self),
            .field("topicScore", Double?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetStudentDisciplineQuery.Data.GetStudentDiscipline.Topic.self
          ] }

          var topicId: LXPSchema.UUID { __data["topicId"] }
          var topic: Topic { __data["topic"] }
          var status: GraphQLEnum<LXPSchema.TopicStatus>? { __data["status"] }
          var topicScore: Double? { __data["topicScore"] }

          /// GetStudentDiscipline.Topic.Topic
          ///
          /// Parent Type: `DisciplineTopic`
          struct Topic: LXPSchema.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.DisciplineTopic }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", LXPSchema.UUID.self),
              .field("name", String.self),
              .field("order", Double.self),
              .field("isCheckPoint", Bool.self),
              .field("maxScore", Double?.self),
              .field("studyHoursCount", Double.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetStudentDisciplineQuery.Data.GetStudentDiscipline.Topic.Topic.self
            ] }

            var id: LXPSchema.UUID { __data["id"] }
            var name: String { __data["name"] }
            var order: Double { __data["order"] }
            var isCheckPoint: Bool { __data["isCheckPoint"] }
            var maxScore: Double? { __data["maxScore"] }
            var studyHoursCount: Double { __data["studyHoursCount"] }
          }
        }
      }
    }
  }

}