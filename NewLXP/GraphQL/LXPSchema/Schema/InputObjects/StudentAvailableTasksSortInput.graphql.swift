// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct StudentAvailableTasksSortInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      deadlineDate: GraphQLNullable<GraphQLEnum<SortType>> = nil
    ) {
      __data = InputDict([
        "deadlineDate": deadlineDate
      ])
    }

    var deadlineDate: GraphQLNullable<GraphQLEnum<SortType>> {
      get { __data["deadlineDate"] }
      set { __data["deadlineDate"] = newValue }
    }
  }

}