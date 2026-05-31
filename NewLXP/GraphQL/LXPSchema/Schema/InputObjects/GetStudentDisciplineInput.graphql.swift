// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetStudentDisciplineInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      disciplineId: UUID,
      studentId: UUID
    ) {
      __data = InputDict([
        "disciplineId": disciplineId,
        "studentId": studentId
      ])
    }

    var disciplineId: UUID {
      get { __data["disciplineId"] }
      set { __data["disciplineId"] = newValue }
    }

    var studentId: UUID {
      get { __data["studentId"] }
      set { __data["studentId"] = newValue }
    }
  }

}