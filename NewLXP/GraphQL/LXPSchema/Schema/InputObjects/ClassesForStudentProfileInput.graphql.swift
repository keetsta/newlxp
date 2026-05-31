// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct ClassesForStudentProfileInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      buildingAreasIds: GraphQLNullable<[UUID]> = nil,
      disciplinesIds: GraphQLNullable<[UUID]> = nil,
      from: DateTime,
      learningGroupsIds: GraphQLNullable<[UUID]> = nil,
      studentId: UUID,
      to: DateTime
    ) {
      __data = InputDict([
        "buildingAreasIds": buildingAreasIds,
        "disciplinesIds": disciplinesIds,
        "from": from,
        "learningGroupsIds": learningGroupsIds,
        "studentId": studentId,
        "to": to
      ])
    }

    var buildingAreasIds: GraphQLNullable<[UUID]> {
      get { __data["buildingAreasIds"] }
      set { __data["buildingAreasIds"] = newValue }
    }

    var disciplinesIds: GraphQLNullable<[UUID]> {
      get { __data["disciplinesIds"] }
      set { __data["disciplinesIds"] = newValue }
    }

    var from: DateTime {
      get { __data["from"] }
      set { __data["from"] = newValue }
    }

    var learningGroupsIds: GraphQLNullable<[UUID]> {
      get { __data["learningGroupsIds"] }
      set { __data["learningGroupsIds"] = newValue }
    }

    var studentId: UUID {
      get { __data["studentId"] }
      set { __data["studentId"] = newValue }
    }

    var to: DateTime {
      get { __data["to"] }
      set { __data["to"] = newValue }
    }
  }

}