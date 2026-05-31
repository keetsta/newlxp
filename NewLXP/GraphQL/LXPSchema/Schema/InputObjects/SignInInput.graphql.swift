// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct SignInInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      email: String,
      password: String
    ) {
      __data = InputDict([
        "email": email,
        "password": password
      ])
    }

    var email: String {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }

    var password: String {
      get { __data["password"] }
      set { __data["password"] = newValue }
    }
  }

}