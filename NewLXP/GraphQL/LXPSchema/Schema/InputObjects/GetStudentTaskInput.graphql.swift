// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetStudentTaskInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      contentBlockId: UUID,
      studentId: UUID,
      topicId: UUID
    ) {
      __data = InputDict([
        "contentBlockId": contentBlockId,
        "studentId": studentId,
        "topicId": topicId
      ])
    }

    var contentBlockId: UUID {
      get { __data["contentBlockId"] }
      set { __data["contentBlockId"] = newValue }
    }

    var studentId: UUID {
      get { __data["studentId"] }
      set { __data["studentId"] = newValue }
    }

    var topicId: UUID {
      get { __data["topicId"] }
      set { __data["topicId"] = newValue }
    }
  }

}