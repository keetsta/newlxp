// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct ManyClassesFilterDateIntervalInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      from: DateTime,
      to: DateTime
    ) {
      __data = InputDict([
        "from": from,
        "to": to
      ])
    }

    var from: DateTime {
      get { __data["from"] }
      set { __data["from"] = newValue }
    }

    var to: DateTime {
      get { __data["to"] }
      set { __data["to"] = newValue }
    }
  }

}