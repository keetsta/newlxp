// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct ManyClassesFilterInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      buildingAreasIds: GraphQLNullable<[UUID]> = nil,
      byArchivedDiscipline: GraphQLNullable<Bool> = nil,
      childrenId: GraphQLNullable<UUID> = nil,
      classRoomsIds: GraphQLNullable<[UUID]> = nil,
      disciplinesIds: GraphQLNullable<[UUID]> = nil,
      interval: ManyClassesFilterDateIntervalInput,
      learningGroupsIds: GraphQLNullable<[UUID]> = nil,
      organizationsIds: GraphQLNullable<[UUID]> = nil,
      retakingGroupIds: GraphQLNullable<[UUID]> = nil,
      retakingGroupV2Ids: GraphQLNullable<[UUID]> = nil,
      roles: GraphQLNullable<[GraphQLEnum<Identity_RoleType>]> = nil,
      studentAttendance: GraphQLNullable<ManyClassesStudentAttendanceFilterInput> = nil,
      studentsIds: GraphQLNullable<[UUID]> = nil,
      suborganizationsIds: GraphQLNullable<[UUID]> = nil,
      teachersIds: GraphQLNullable<[UUID]> = nil
    ) {
      __data = InputDict([
        "buildingAreasIds": buildingAreasIds,
        "byArchivedDiscipline": byArchivedDiscipline,
        "childrenId": childrenId,
        "classRoomsIds": classRoomsIds,
        "disciplinesIds": disciplinesIds,
        "interval": interval,
        "learningGroupsIds": learningGroupsIds,
        "organizationsIds": organizationsIds,
        "retakingGroupIds": retakingGroupIds,
        "retakingGroupV2Ids": retakingGroupV2Ids,
        "roles": roles,
        "studentAttendance": studentAttendance,
        "studentsIds": studentsIds,
        "suborganizationsIds": suborganizationsIds,
        "teachersIds": teachersIds
      ])
    }

    var buildingAreasIds: GraphQLNullable<[UUID]> {
      get { __data["buildingAreasIds"] }
      set { __data["buildingAreasIds"] = newValue }
    }

    var byArchivedDiscipline: GraphQLNullable<Bool> {
      get { __data["byArchivedDiscipline"] }
      set { __data["byArchivedDiscipline"] = newValue }
    }

    var childrenId: GraphQLNullable<UUID> {
      get { __data["childrenId"] }
      set { __data["childrenId"] = newValue }
    }

    var classRoomsIds: GraphQLNullable<[UUID]> {
      get { __data["classRoomsIds"] }
      set { __data["classRoomsIds"] = newValue }
    }

    var disciplinesIds: GraphQLNullable<[UUID]> {
      get { __data["disciplinesIds"] }
      set { __data["disciplinesIds"] = newValue }
    }

    var interval: ManyClassesFilterDateIntervalInput {
      get { __data["interval"] }
      set { __data["interval"] = newValue }
    }

    var learningGroupsIds: GraphQLNullable<[UUID]> {
      get { __data["learningGroupsIds"] }
      set { __data["learningGroupsIds"] = newValue }
    }

    var organizationsIds: GraphQLNullable<[UUID]> {
      get { __data["organizationsIds"] }
      set { __data["organizationsIds"] = newValue }
    }

    var retakingGroupIds: GraphQLNullable<[UUID]> {
      get { __data["retakingGroupIds"] }
      set { __data["retakingGroupIds"] = newValue }
    }

    var retakingGroupV2Ids: GraphQLNullable<[UUID]> {
      get { __data["retakingGroupV2Ids"] }
      set { __data["retakingGroupV2Ids"] = newValue }
    }

    var roles: GraphQLNullable<[GraphQLEnum<Identity_RoleType>]> {
      get { __data["roles"] }
      set { __data["roles"] = newValue }
    }

    var studentAttendance: GraphQLNullable<ManyClassesStudentAttendanceFilterInput> {
      get { __data["studentAttendance"] }
      set { __data["studentAttendance"] = newValue }
    }

    var studentsIds: GraphQLNullable<[UUID]> {
      get { __data["studentsIds"] }
      set { __data["studentsIds"] = newValue }
    }

    var suborganizationsIds: GraphQLNullable<[UUID]> {
      get { __data["suborganizationsIds"] }
      set { __data["suborganizationsIds"] = newValue }
    }

    var teachersIds: GraphQLNullable<[UUID]> {
      get { __data["teachersIds"] }
      set { __data["teachersIds"] = newValue }
    }
  }

}