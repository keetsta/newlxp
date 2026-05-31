// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct SignInQuery: GraphQLQuery {
    static let operationName: String = "SignIn"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SignIn($input: SignInInput!) { signIn(input: $input) { __typename accessToken refreshToken user { __typename id isLead } } }"#
      ))

    public var input: SignInInput

    public init(input: SignInInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("signIn", SignIn.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SignInQuery.Data.self
      ] }

      var signIn: SignIn { __data["signIn"] }

      /// SignIn
      ///
      /// Parent Type: `SignInPayload`
      struct SignIn: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.SignInPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("accessToken", String.self),
          .field("refreshToken", String.self),
          .field("user", User.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SignInQuery.Data.SignIn.self
        ] }

        var accessToken: String { __data["accessToken"] }
        var refreshToken: String { __data["refreshToken"] }
        var user: User { __data["user"] }

        /// SignIn.User
        ///
        /// Parent Type: `User`
        struct User: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.User }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.ID.self),
            .field("isLead", Bool.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SignInQuery.Data.SignIn.User.self
          ] }

          var id: LXPSchema.ID { __data["id"] }
          /// User is admin of the demo organization
          var isLead: Bool { __data["isLead"] }
        }
      }
    }
  }

}