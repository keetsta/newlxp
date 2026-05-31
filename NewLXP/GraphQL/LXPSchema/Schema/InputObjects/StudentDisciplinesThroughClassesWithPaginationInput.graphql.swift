// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct StudentDisciplinesThroughClassesWithPaginationInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      page: Int32? = nil,
      pageSize: Int32? = nil,
      studentId: UUID
    ) {
      __data = InputDict([
        "page": page ?? GraphQLNullable.none,
        "pageSize": pageSize ?? GraphQLNullable.none,
        "studentId": studentId
      ])
    }

    var page: Int32? {
      get { __data["page"] }
      set { __data["page"] = newValue }
    }

    var pageSize: Int32? {
      get { __data["pageSize"] }
      set { __data["pageSize"] = newValue }
    }

    var studentId: UUID {
      get { __data["studentId"] }
      set { __data["studentId"] = newValue }
    }
  }

}