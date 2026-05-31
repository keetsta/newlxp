// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct StudentAvailableTasksQuery: GraphQLQuery {
    static let operationName: String = "StudentAvailableTasks"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query StudentAvailableTasks($input: StudentAvailableTasksInput!) { studentAvailableTasks(input: $input) { __typename page perPage total totalPages hasMore items { __typename contentBlockId kind taskDeadline passDate testAvailableFrom testAvailableTo topic { __typename id name isCheckPoint } contentBlock { __typename ... on TaskDisciplineTopicContentBlock { id name maxScore } ... on TestDisciplineTopicContentBlock { id name maxScore } ... on InfoDisciplineTopicContentBlock { id name } } } } }"#
      ))

    public var input: StudentAvailableTasksInput

    public init(input: StudentAvailableTasksInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("studentAvailableTasks", StudentAvailableTasks.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        StudentAvailableTasksQuery.Data.self
      ] }

      var studentAvailableTasks: StudentAvailableTasks { __data["studentAvailableTasks"] }

      /// StudentAvailableTasks
      ///
      /// Parent Type: `StudentAvailableTasksPayload`
      struct StudentAvailableTasks: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.StudentAvailableTasksPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("page", Int.self),
          .field("perPage", Int.self),
          .field("total", Int.self),
          .field("totalPages", Int.self),
          .field("hasMore", Bool.self),
          .field("items", [Item].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          StudentAvailableTasksQuery.Data.StudentAvailableTasks.self
        ] }

        var page: Int { __data["page"] }
        var perPage: Int { __data["perPage"] }
        var total: Int { __data["total"] }
        var totalPages: Int { __data["totalPages"] }
        var hasMore: Bool { __data["hasMore"] }
        var items: [Item] { __data["items"] }

        /// StudentAvailableTasks.Item
        ///
        /// Parent Type: `StudentContentBlock`
        struct Item: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.StudentContentBlock }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("contentBlockId", LXPSchema.UUID.self),
            .field("kind", GraphQLEnum<LXPSchema.DisciplineTopicContentBlockKind>.self),
            .field("taskDeadline", LXPSchema.DateTime?.self),
            .field("passDate", LXPSchema.DateTime?.self),
            .field("testAvailableFrom", LXPSchema.DateTime?.self),
            .field("testAvailableTo", LXPSchema.DateTime?.self),
            .field("topic", Topic.self),
            .field("contentBlock", ContentBlock.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.self
          ] }

          var contentBlockId: LXPSchema.UUID { __data["contentBlockId"] }
          var kind: GraphQLEnum<LXPSchema.DisciplineTopicContentBlockKind> { __data["kind"] }
          var taskDeadline: LXPSchema.DateTime? { __data["taskDeadline"] }
          var passDate: LXPSchema.DateTime? { __data["passDate"] }
          @available(*, deprecated, message: "Use testInterval instead")
          var testAvailableFrom: LXPSchema.DateTime? { __data["testAvailableFrom"] }
          @available(*, deprecated, message: "Use testInterval instead")
          var testAvailableTo: LXPSchema.DateTime? { __data["testAvailableTo"] }
          var topic: Topic { __data["topic"] }
          var contentBlock: ContentBlock { __data["contentBlock"] }

          /// StudentAvailableTasks.Item.Topic
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
              .field("isCheckPoint", Bool.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.Topic.self
            ] }

            var id: LXPSchema.UUID { __data["id"] }
            var name: String { __data["name"] }
            var isCheckPoint: Bool { __data["isCheckPoint"] }
          }

          /// StudentAvailableTasks.Item.ContentBlock
          ///
          /// Parent Type: `DisciplineTopicContentBlock`
          struct ContentBlock: LXPSchema.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { LXPSchema.Unions.DisciplineTopicContentBlock }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .inlineFragment(AsTaskDisciplineTopicContentBlock.self),
              .inlineFragment(AsTestDisciplineTopicContentBlock.self),
              .inlineFragment(AsInfoDisciplineTopicContentBlock.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock.self
            ] }

            var asTaskDisciplineTopicContentBlock: AsTaskDisciplineTopicContentBlock? { _asInlineFragment() }
            var asTestDisciplineTopicContentBlock: AsTestDisciplineTopicContentBlock? { _asInlineFragment() }
            var asInfoDisciplineTopicContentBlock: AsInfoDisciplineTopicContentBlock? { _asInlineFragment() }

            /// StudentAvailableTasks.Item.ContentBlock.AsTaskDisciplineTopicContentBlock
            ///
            /// Parent Type: `TaskDisciplineTopicContentBlock`
            struct AsTaskDisciplineTopicContentBlock: LXPSchema.InlineFragment {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              typealias RootEntityType = StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock
              static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.TaskDisciplineTopicContentBlock }
              static var __selections: [ApolloAPI.Selection] { [
                .field("id", LXPSchema.UUID.self),
                .field("name", String.self),
                .field("maxScore", Double?.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock.self,
                StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock.AsTaskDisciplineTopicContentBlock.self
              ] }

              var id: LXPSchema.UUID { __data["id"] }
              var name: String { __data["name"] }
              var maxScore: Double? { __data["maxScore"] }
            }

            /// StudentAvailableTasks.Item.ContentBlock.AsTestDisciplineTopicContentBlock
            ///
            /// Parent Type: `TestDisciplineTopicContentBlock`
            struct AsTestDisciplineTopicContentBlock: LXPSchema.InlineFragment {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              typealias RootEntityType = StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock
              static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.TestDisciplineTopicContentBlock }
              static var __selections: [ApolloAPI.Selection] { [
                .field("id", LXPSchema.UUID.self),
                .field("name", String.self),
                .field("maxScore", Double?.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock.self,
                StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock.AsTestDisciplineTopicContentBlock.self
              ] }

              var id: LXPSchema.UUID { __data["id"] }
              var name: String { __data["name"] }
              var maxScore: Double? { __data["maxScore"] }
            }

            /// StudentAvailableTasks.Item.ContentBlock.AsInfoDisciplineTopicContentBlock
            ///
            /// Parent Type: `InfoDisciplineTopicContentBlock`
            struct AsInfoDisciplineTopicContentBlock: LXPSchema.InlineFragment {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              typealias RootEntityType = StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock
              static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.InfoDisciplineTopicContentBlock }
              static var __selections: [ApolloAPI.Selection] { [
                .field("id", LXPSchema.UUID.self),
                .field("name", String.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock.self,
                StudentAvailableTasksQuery.Data.StudentAvailableTasks.Item.ContentBlock.AsInfoDisciplineTopicContentBlock.self
              ] }

              var id: LXPSchema.UUID { __data["id"] }
              var name: String { __data["name"] }
            }
          }
        }
      }
    }
  }

}