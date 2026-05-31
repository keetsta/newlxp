// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct RefreshTokenQuery: GraphQLQuery {
    static let operationName: String = "RefreshToken"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query RefreshToken($input: RefreshTokenInput!) { refreshToken(input: $input) { __typename accessToken refreshToken } }"#
      ))

    public var input: RefreshTokenInput

    public init(input: RefreshTokenInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("refreshToken", RefreshToken.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RefreshTokenQuery.Data.self
      ] }

      var refreshToken: RefreshToken { __data["refreshToken"] }

      /// RefreshToken
      ///
      /// Parent Type: `RefreshTokenPayload`
      struct RefreshToken: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.RefreshTokenPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("accessToken", String.self),
          .field("refreshToken", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RefreshTokenQuery.Data.RefreshToken.self
        ] }

        var accessToken: String { __data["accessToken"] }
        var refreshToken: String { __data["refreshToken"] }
      }
    }
  }

}