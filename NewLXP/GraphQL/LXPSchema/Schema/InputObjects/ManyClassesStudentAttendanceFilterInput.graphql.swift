// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct ManyClassesStudentAttendanceFilterInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      status: GraphQLEnum<ClassAttendanceStatus>,
      studentId: UUID
    ) {
      __data = InputDict([
        "status": status,
        "studentId": studentId
      ])
    }

    var status: GraphQLEnum<ClassAttendanceStatus> {
      get { __data["status"] }
      set { __data["status"] = newValue }
    }

    var studentId: UUID {
      get { __data["studentId"] }
      set { __data["studentId"] = newValue }
    }
  }

}