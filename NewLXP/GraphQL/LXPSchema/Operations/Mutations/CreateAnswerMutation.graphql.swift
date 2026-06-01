// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct CreateAnswerMutation: GraphQLMutation {
    static let operationName: String = "CreateAnswer"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateAnswer($input: CreateAnswerInput!) { createAnswer(input: $input) { __typename id text content filesUrls createdAt taskId studentId } }"#
      ))

    public var input: CreateAnswerInput

    public init(input: CreateAnswerInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("createAnswer", CreateAnswer.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateAnswerMutation.Data.self
      ] }

      var createAnswer: CreateAnswer { __data["createAnswer"] }

      /// CreateAnswer
      ///
      /// Parent Type: `TaskAnswer`
      struct CreateAnswer: LXPSchema.SelectionSet {
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
          .field("taskId", LXPSchema.UUID.self),
          .field("studentId", LXPSchema.UUID.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateAnswerMutation.Data.CreateAnswer.self
        ] }

        var id: LXPSchema.UUID { __data["id"] }
        var text: String { __data["text"] }
        var content: String? { __data["content"] }
        var filesUrls: [String] { __data["filesUrls"] }
        var createdAt: LXPSchema.DateTime { __data["createdAt"] }
        var taskId: LXPSchema.UUID { __data["taskId"] }
        var studentId: LXPSchema.UUID { __data["studentId"] }
      }
    }
  }

}