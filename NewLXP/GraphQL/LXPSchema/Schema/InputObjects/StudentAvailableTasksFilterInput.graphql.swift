// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct StudentAvailableTasksFilterInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      deadlineDateLessThan: GraphQLNullable<DateTime> = nil,
      disciplineId: GraphQLNullable<UUID> = nil,
      fromArchivedDiscipline: GraphQLNullable<Bool> = nil,
      organizationId: GraphQLNullable<UUID> = nil,
      query: GraphQLNullable<String> = nil,
      status: GraphQLNullable<GraphQLEnum<StudentAvailableTaskStatus>> = nil
    ) {
      __data = InputDict([
        "deadlineDateLessThan": deadlineDateLessThan,
        "disciplineId": disciplineId,
        "fromArchivedDiscipline": fromArchivedDiscipline,
        "organizationId": organizationId,
        "query": query,
        "status": status
      ])
    }

    var deadlineDateLessThan: GraphQLNullable<DateTime> {
      get { __data["deadlineDateLessThan"] }
      set { __data["deadlineDateLessThan"] = newValue }
    }

    var disciplineId: GraphQLNullable<UUID> {
      get { __data["disciplineId"] }
      set { __data["disciplineId"] = newValue }
    }

    var fromArchivedDiscipline: GraphQLNullable<Bool> {
      get { __data["fromArchivedDiscipline"] }
      set { __data["fromArchivedDiscipline"] = newValue }
    }

    var organizationId: GraphQLNullable<UUID> {
      get { __data["organizationId"] }
      set { __data["organizationId"] = newValue }
    }

    var query: GraphQLNullable<String> {
      get { __data["query"] }
      set { __data["query"] = newValue }
    }

    var status: GraphQLNullable<GraphQLEnum<StudentAvailableTaskStatus>> {
      get { __data["status"] }
      set { __data["status"] = newValue }
    }
  }

}