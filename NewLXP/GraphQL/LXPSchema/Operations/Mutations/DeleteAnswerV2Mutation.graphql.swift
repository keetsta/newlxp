// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct DeleteAnswerV2Mutation: GraphQLMutation {
    static let operationName: String = "DeleteAnswerV2"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeleteAnswerV2($input: DeleteAnswerInputV2!) { deleteAnswerV2(input: $input) }"#
      ))

    public var input: DeleteAnswerInputV2

    public init(input: DeleteAnswerInputV2) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deleteAnswerV2", LXPSchema.Void.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeleteAnswerV2Mutation.Data.self
      ] }

      var deleteAnswerV2: LXPSchema.Void { __data["deleteAnswerV2"] }
    }
  }

}