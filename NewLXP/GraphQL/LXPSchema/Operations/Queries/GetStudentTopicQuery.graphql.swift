// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetStudentTopicQuery: GraphQLQuery {
    static let operationName: String = "GetStudentTopic"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetStudentTopic($input: GetStudentTopicInput!) { getStudentTopic(input: $input) { __typename topic { __typename topicId topic { __typename id name order isCheckPoint maxScore studyHoursCount content { __typename howStudyIt } } status topicScore contentBlocks { __typename contentBlockId kind taskDeadline passDate testAvailableFrom testAvailableTo testScore contentBlock { __typename ... on InfoDisciplineTopicContentBlock { id name body order } ... on TaskDisciplineTopicContentBlock { id name body maxScore order } ... on TestDisciplineTopicContentBlock { id name body maxScore order } } } } } }"#
      ))

    public var input: GetStudentTopicInput

    public init(input: GetStudentTopicInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("getStudentTopic", GetStudentTopic.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetStudentTopicQuery.Data.self
      ] }

      var getStudentTopic: GetStudentTopic { __data["getStudentTopic"] }

      /// GetStudentTopic
      ///
      /// Parent Type: `GetStudentTopicPayload`
      struct GetStudentTopic: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.GetStudentTopicPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("topic", Topic.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetStudentTopicQuery.Data.GetStudentTopic.self
        ] }

        var topic: Topic { __data["topic"] }

        /// GetStudentTopic.Topic
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
            .field("contentBlocks", [ContentBlock].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetStudentTopicQuery.Data.GetStudentTopic.Topic.self
          ] }

          var topicId: LXPSchema.UUID { __data["topicId"] }
          var topic: Topic { __data["topic"] }
          var status: GraphQLEnum<LXPSchema.TopicStatus>? { __data["status"] }
          var topicScore: Double? { __data["topicScore"] }
          var contentBlocks: [ContentBlock] { __data["contentBlocks"] }

          /// GetStudentTopic.Topic.Topic
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
              .field("content", Content.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetStudentTopicQuery.Data.GetStudentTopic.Topic.Topic.self
            ] }

            var id: LXPSchema.UUID { __data["id"] }
            var name: String { __data["name"] }
            var order: Double { __data["order"] }
            var isCheckPoint: Bool { __data["isCheckPoint"] }
            var maxScore: Double? { __data["maxScore"] }
            var studyHoursCount: Double { __data["studyHoursCount"] }
            var content: Content { __data["content"] }

            /// GetStudentTopic.Topic.Topic.Content
            ///
            /// Parent Type: `DisciplineTopicContent`
            struct Content: LXPSchema.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.DisciplineTopicContent }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("howStudyIt", String.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetStudentTopicQuery.Data.GetStudentTopic.Topic.Topic.Content.self
              ] }

              var howStudyIt: String { __data["howStudyIt"] }
            }
          }

          /// GetStudentTopic.Topic.ContentBlock
          ///
          /// Parent Type: `StudentContentBlock`
          struct ContentBlock: LXPSchema.SelectionSet {
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
              .field("testScore", Double?.self),
              .field("contentBlock", ContentBlock.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.self
            ] }

            var contentBlockId: LXPSchema.UUID { __data["contentBlockId"] }
            var kind: GraphQLEnum<LXPSchema.DisciplineTopicContentBlockKind> { __data["kind"] }
            var taskDeadline: LXPSchema.DateTime? { __data["taskDeadline"] }
            var passDate: LXPSchema.DateTime? { __data["passDate"] }
            @available(*, deprecated, message: "Use testInterval instead")
            var testAvailableFrom: LXPSchema.DateTime? { __data["testAvailableFrom"] }
            @available(*, deprecated, message: "Use testInterval instead")
            var testAvailableTo: LXPSchema.DateTime? { __data["testAvailableTo"] }
            var testScore: Double? { __data["testScore"] }
            var contentBlock: ContentBlock { __data["contentBlock"] }

            /// GetStudentTopic.Topic.ContentBlock.ContentBlock
            ///
            /// Parent Type: `DisciplineTopicContentBlock`
            struct ContentBlock: LXPSchema.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { LXPSchema.Unions.DisciplineTopicContentBlock }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .inlineFragment(AsInfoDisciplineTopicContentBlock.self),
                .inlineFragment(AsTaskDisciplineTopicContentBlock.self),
                .inlineFragment(AsTestDisciplineTopicContentBlock.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock.self
              ] }

              var asInfoDisciplineTopicContentBlock: AsInfoDisciplineTopicContentBlock? { _asInlineFragment() }
              var asTaskDisciplineTopicContentBlock: AsTaskDisciplineTopicContentBlock? { _asInlineFragment() }
              var asTestDisciplineTopicContentBlock: AsTestDisciplineTopicContentBlock? { _asInlineFragment() }

              /// GetStudentTopic.Topic.ContentBlock.ContentBlock.AsInfoDisciplineTopicContentBlock
              ///
              /// Parent Type: `InfoDisciplineTopicContentBlock`
              struct AsInfoDisciplineTopicContentBlock: LXPSchema.InlineFragment {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                typealias RootEntityType = GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock
                static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.InfoDisciplineTopicContentBlock }
                static var __selections: [ApolloAPI.Selection] { [
                  .field("id", LXPSchema.UUID.self),
                  .field("name", String.self),
                  .field("body", String.self),
                  .field("order", Double.self),
                ] }
                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock.self,
                  GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock.AsInfoDisciplineTopicContentBlock.self
                ] }

                var id: LXPSchema.UUID { __data["id"] }
                var name: String { __data["name"] }
                var body: String { __data["body"] }
                var order: Double { __data["order"] }
              }

              /// GetStudentTopic.Topic.ContentBlock.ContentBlock.AsTaskDisciplineTopicContentBlock
              ///
              /// Parent Type: `TaskDisciplineTopicContentBlock`
              struct AsTaskDisciplineTopicContentBlock: LXPSchema.InlineFragment {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                typealias RootEntityType = GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock
                static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.TaskDisciplineTopicContentBlock }
                static var __selections: [ApolloAPI.Selection] { [
                  .field("id", LXPSchema.UUID.self),
                  .field("name", String.self),
                  .field("body", String.self),
                  .field("maxScore", Double?.self),
                  .field("order", Double.self),
                ] }
                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock.self,
                  GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock.AsTaskDisciplineTopicContentBlock.self
                ] }

                var id: LXPSchema.UUID { __data["id"] }
                var name: String { __data["name"] }
                var body: String { __data["body"] }
                var maxScore: Double? { __data["maxScore"] }
                var order: Double { __data["order"] }
              }

              /// GetStudentTopic.Topic.ContentBlock.ContentBlock.AsTestDisciplineTopicContentBlock
              ///
              /// Parent Type: `TestDisciplineTopicContentBlock`
              struct AsTestDisciplineTopicContentBlock: LXPSchema.InlineFragment {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                typealias RootEntityType = GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock
                static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.TestDisciplineTopicContentBlock }
                static var __selections: [ApolloAPI.Selection] { [
                  .field("id", LXPSchema.UUID.self),
                  .field("name", String.self),
                  .field("body", String.self),
                  .field("maxScore", Double?.self),
                  .field("order", Double.self),
                ] }
                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock.self,
                  GetStudentTopicQuery.Data.GetStudentTopic.Topic.ContentBlock.ContentBlock.AsTestDisciplineTopicContentBlock.self
                ] }

                var id: LXPSchema.UUID { __data["id"] }
                var name: String { __data["name"] }
                var body: String { __data["body"] }
                var maxScore: Double? { __data["maxScore"] }
                var order: Double { __data["order"] }
              }
            }
          }
        }
      }
    }
  }

}