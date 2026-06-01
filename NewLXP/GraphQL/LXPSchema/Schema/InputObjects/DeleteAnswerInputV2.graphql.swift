// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct DeleteAnswerInputV2: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      answerId: UUID,
      contentBlockId: UUID,
      studentId: UUID,
      topicId: UUID
    ) {
      __data = InputDict([
        "answerId": answerId,
        "contentBlockId": contentBlockId,
        "studentId": studentId,
        "topicId": topicId
      ])
    }

    var answerId: UUID {
      get { __data["answerId"] }
      set { __data["answerId"] = newValue }
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