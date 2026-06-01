// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetFileUploadUrlQuery: GraphQLQuery {
    static let operationName: String = "GetFileUploadUrl"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetFileUploadUrl($input: GetFileUploadUrlInput!) { getFileUploadUrl(input: $input) { __typename url } }"#
      ))

    public var input: GetFileUploadUrlInput

    public init(input: GetFileUploadUrlInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("getFileUploadUrl", GetFileUploadUrl.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetFileUploadUrlQuery.Data.self
      ] }

      var getFileUploadUrl: GetFileUploadUrl { __data["getFileUploadUrl"] }

      /// GetFileUploadUrl
      ///
      /// Parent Type: `GetFileUploadUrlPayload`
      struct GetFileUploadUrl: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.GetFileUploadUrlPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("url", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetFileUploadUrlQuery.Data.GetFileUploadUrl.self
        ] }

        var url: String { __data["url"] }
      }
    }
  }

}