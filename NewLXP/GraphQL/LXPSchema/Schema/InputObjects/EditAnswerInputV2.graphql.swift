// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct EditAnswerInputV2: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      answerId: UUID,
      content: GraphQLNullable<String> = nil,
      contentBlockId: UUID,
      filesUrl: GraphQLNullable<[String]> = nil,
      studentId: UUID,
      text: GraphQLNullable<String> = nil,
      topicId: UUID
    ) {
      __data = InputDict([
        "answerId": answerId,
        "content": content,
        "contentBlockId": contentBlockId,
        "filesUrl": filesUrl,
        "studentId": studentId,
        "text": text,
        "topicId": topicId
      ])
    }

    var answerId: UUID {
      get { __data["answerId"] }
      set { __data["answerId"] = newValue }
    }

    var content: GraphQLNullable<String> {
      get { __data["content"] }
      set { __data["content"] = newValue }
    }

    var contentBlockId: UUID {
      get { __data["contentBlockId"] }
      set { __data["contentBlockId"] = newValue }
    }

    var filesUrl: GraphQLNullable<[String]> {
      get { __data["filesUrl"] }
      set { __data["filesUrl"] = newValue }
    }

    var studentId: UUID {
      get { __data["studentId"] }
      set { __data["studentId"] = newValue }
    }

    var text: GraphQLNullable<String> {
      get { __data["text"] }
      set { __data["text"] = newValue }
    }

    var topicId: UUID {
      get { __data["topicId"] }
      set { __data["topicId"] = newValue }
    }
  }

}