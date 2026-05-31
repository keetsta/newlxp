// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct RefreshTokenInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      token: String
    ) {
      __data = InputDict([
        "token": token
      ])
    }

    var token: String {
      get { __data["token"] }
      set { __data["token"] = newValue }
    }
  }

}