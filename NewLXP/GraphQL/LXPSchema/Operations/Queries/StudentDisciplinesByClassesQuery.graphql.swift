// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct StudentDisciplinesByClassesQuery: GraphQLQuery {
    static let operationName: String = "StudentDisciplinesByClasses"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query StudentDisciplinesByClasses($input: StudentDisciplinesThroughClassesWithPaginationInput!) { studentDisciplinesThroughClassesWithPagination(input: $input) { __typename page perPage total totalPages hasMore items { __typename id name code studyHoursCount maxScore } } }"#
      ))

    public var input: StudentDisciplinesThroughClassesWithPaginationInput

    public init(input: StudentDisciplinesThroughClassesWithPaginationInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("studentDisciplinesThroughClassesWithPagination", StudentDisciplinesThroughClassesWithPagination.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        StudentDisciplinesByClassesQuery.Data.self
      ] }

      /// Дисциплины, по которым назначены занятия для студента
      var studentDisciplinesThroughClassesWithPagination: StudentDisciplinesThroughClassesWithPagination { __data["studentDisciplinesThroughClassesWithPagination"] }

      /// StudentDisciplinesThroughClassesWithPagination
      ///
      /// Parent Type: `StudentDisciplinesByClassesPayload`
      struct StudentDisciplinesThroughClassesWithPagination: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.StudentDisciplinesByClassesPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("page", Int.self),
          .field("perPage", Int.self),
          .field("total", Int.self),
          .field("totalPages", Int.self),
          .field("hasMore", Bool.self),
          .field("items", [Item].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          StudentDisciplinesByClassesQuery.Data.StudentDisciplinesThroughClassesWithPagination.self
        ] }

        var page: Int { __data["page"] }
        var perPage: Int { __data["perPage"] }
        var total: Int { __data["total"] }
        var totalPages: Int { __data["totalPages"] }
        var hasMore: Bool { __data["hasMore"] }
        var items: [Item] { __data["items"] }

        /// StudentDisciplinesThroughClassesWithPagination.Item
        ///
        /// Parent Type: `Discipline`
        struct Item: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Discipline }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.UUID.self),
            .field("name", String.self),
            .field("code", String?.self),
            .field("studyHoursCount", Double.self),
            .field("maxScore", Double.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            StudentDisciplinesByClassesQuery.Data.StudentDisciplinesThroughClassesWithPagination.Item.self
          ] }

          var id: LXPSchema.UUID { __data["id"] }
          var name: String { __data["name"] }
          var code: String? { __data["code"] }
          var studyHoursCount: Double { __data["studyHoursCount"] }
          var maxScore: Double { __data["maxScore"] }
        }
      }
    }
  }

}