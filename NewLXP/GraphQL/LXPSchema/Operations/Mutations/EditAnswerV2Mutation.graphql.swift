// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct EditAnswerV2Mutation: GraphQLMutation {
    static let operationName: String = "EditAnswerV2"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation EditAnswerV2($input: EditAnswerInputV2!) { editAnswerV2(input: $input) { __typename id text content filesUrls createdAt isEdited taskId studentId } }"#
      ))

    public var input: EditAnswerInputV2

    public init(input: EditAnswerInputV2) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("editAnswerV2", EditAnswerV2.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EditAnswerV2Mutation.Data.self
      ] }

      var editAnswerV2: EditAnswerV2 { __data["editAnswerV2"] }

      /// EditAnswerV2
      ///
      /// Parent Type: `TaskAnswer`
      struct EditAnswerV2: LXPSchema.SelectionSet {
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
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EditAnswerV2Mutation.Data.EditAnswerV2.self
        ] }

        var id: LXPSchema.UUID { __data["id"] }
        var text: String { __data["text"] }
        var content: String? { __data["content"] }
        var filesUrls: [String] { __data["filesUrls"] }
        var createdAt: LXPSchema.DateTime { __data["createdAt"] }
        var isEdited: Bool { __data["isEdited"] }
        var taskId: LXPSchema.UUID { __data["taskId"] }
        var studentId: LXPSchema.UUID { __data["studentId"] }
      }
    }
  }

}