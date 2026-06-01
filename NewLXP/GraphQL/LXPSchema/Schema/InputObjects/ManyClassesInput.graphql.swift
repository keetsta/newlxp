// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct ManyClassesInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      filters: ManyClassesFilterInput,
      page: Int32? = nil,
      pageSize: Int32? = nil
    ) {
      __data = InputDict([
        "filters": filters,
        "page": page ?? GraphQLNullable.none,
        "pageSize": pageSize ?? GraphQLNullable.none
      ])
    }

    var filters: ManyClassesFilterInput {
      get { __data["filters"] }
      set { __data["filters"] = newValue }
    }

    var page: Int32? {
      get { __data["page"] }
      set { __data["page"] = newValue }
    }

    var pageSize: Int32? {
      get { __data["pageSize"] }
      set { __data["pageSize"] = newValue }
    }
  }

}