// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct CreateAnswerInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      content: GraphQLNullable<String> = nil,
      contentBlockId: UUID,
      filesUrl: [String],
      text: String,
      topicId: UUID
    ) {
      __data = InputDict([
        "content": content,
        "contentBlockId": contentBlockId,
        "filesUrl": filesUrl,
        "text": text,
        "topicId": topicId
      ])
    }

    var content: GraphQLNullable<String> {
      get { __data["content"] }
      set { __data["content"] = newValue }
    }

    var contentBlockId: UUID {
      get { __data["contentBlockId"] }
      set { __data["contentBlockId"] = newValue }
    }

    var filesUrl: [String] {
      get { __data["filesUrl"] }
      set { __data["filesUrl"] = newValue }
    }

    var text: String {
      get { __data["text"] }
      set { __data["text"] = newValue }
    }

    var topicId: UUID {
      get { __data["topicId"] }
      set { __data["topicId"] = newValue }
    }
  }

}