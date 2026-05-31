// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct StudentAvailableTasksInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      filters: GraphQLNullable<StudentAvailableTasksFilterInput> = nil,
      page: Int32? = nil,
      pageSize: Int32? = nil,
      sorts: StudentAvailableTasksSortInput? = nil,
      studentId: UUID
    ) {
      __data = InputDict([
        "filters": filters,
        "page": page ?? GraphQLNullable.none,
        "pageSize": pageSize ?? GraphQLNullable.none,
        "sorts": sorts ?? GraphQLNullable.none,
        "studentId": studentId
      ])
    }

    var filters: GraphQLNullable<StudentAvailableTasksFilterInput> {
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

    var sorts: StudentAvailableTasksSortInput? {
      get { __data["sorts"] }
      set { __data["sorts"] = newValue }
    }

    var studentId: UUID {
      get { __data["studentId"] }
      set { __data["studentId"] = newValue }
    }
  }

}