// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetStudentTopicInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      studentId: UUID,
      topicId: UUID
    ) {
      __data = InputDict([
        "studentId": studentId,
        "topicId": topicId
      ])
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