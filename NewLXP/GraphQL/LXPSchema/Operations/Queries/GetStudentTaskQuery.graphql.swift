// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetStudentTaskQuery: GraphQLQuery {
    static let operationName: String = "GetStudentTask"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetStudentTask($input: GetStudentTaskInput!) { getStudentTask_v2(input: $input) { __typename id contentBlockId topicId studentId scoreInPercent studentAnswers { __typename id text content filesUrls createdAt isEdited taskId studentId comments { __typename id text filesUrls createdAt authorId isEdited } } } }"#
      ))

    public var input: GetStudentTaskInput

    public init(input: GetStudentTaskInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("getStudentTask_v2", GetStudentTask_v2?.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetStudentTaskQuery.Data.self
      ] }

      var getStudentTask_v2: GetStudentTask_v2? { __data["getStudentTask_v2"] }

      /// GetStudentTask_v2
      ///
      /// Parent Type: `Task`
      struct GetStudentTask_v2: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Task }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", LXPSchema.UUID.self),
          .field("contentBlockId", LXPSchema.UUID.self),
          .field("topicId", LXPSchema.UUID.self),
          .field("studentId", LXPSchema.UUID.self),
          .field("scoreInPercent", Double?.self),
          .field("studentAnswers", [StudentAnswer].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetStudentTaskQuery.Data.GetStudentTask_v2.self
        ] }

        var id: LXPSchema.UUID { __data["id"] }
        var contentBlockId: LXPSchema.UUID { __data["contentBlockId"] }
        var topicId: LXPSchema.UUID { __data["topicId"] }
        var studentId: LXPSchema.UUID { __data["studentId"] }
        var scoreInPercent: Double? { __data["scoreInPercent"] }
        var studentAnswers: [StudentAnswer] { __data["studentAnswers"] }

        /// GetStudentTask_v2.StudentAnswer
        ///
        /// Parent Type: `TaskAnswer`
        struct StudentAnswer: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.TaskAnswer }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.UUID.self),
            .field("text", String.self),
            .field("content", String?.self),
            .field("filesUrls", [String].self),
            .field("createdAt", LXPSchema.DateTime.self),
            .field("isEdited", Bool.self),
            .field("taskId", LXPSchema.UUID.self),
            .field("studentId", LXPSchema.UUID.self),
            .field("comments", [Comment].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetStudentTaskQuery.Data.GetStudentTask_v2.StudentAnswer.self
          ] }

          var id: LXPSchema.UUID { __data["id"] }
          var text: String { __data["text"] }
          var content: String? { __data["content"] }
          var filesUrls: [String] { __data["filesUrls"] }
          var createdAt: LXPSchema.DateTime { __data["createdAt"] }
          var isEdited: Bool { __data["isEdited"] }
          var taskId: LXPSchema.UUID { __data["taskId"] }
          var studentId: LXPSchema.UUID { __data["studentId"] }
          var comments: [Comment] { __data["comments"] }

          /// GetStudentTask_v2.StudentAnswer.Comment
          ///
          /// Parent Type: `TaskAnswerComment`
          struct Comment: LXPSchema.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.TaskAnswerComment }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", LXPSchema.UUID.self),
              .field("text", String.self),
              .field("filesUrls", [String].self),
              .field("createdAt", LXPSchema.DateTime.self),
              .field("authorId", LXPSchema.UUID.self),
              .field("isEdited", Bool.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetStudentTaskQuery.Data.GetStudentTask_v2.StudentAnswer.Comment.self
            ] }

            var id: LXPSchema.UUID { __data["id"] }
            var text: String { __data["text"] }
            var filesUrls: [String] { __data["filesUrls"] }
            var createdAt: LXPSchema.DateTime { __data["createdAt"] }
            var authorId: LXPSchema.UUID { __data["authorId"] }
            var isEdited: Bool { __data["isEdited"] }
          }
        }
      }
    }
  }

}