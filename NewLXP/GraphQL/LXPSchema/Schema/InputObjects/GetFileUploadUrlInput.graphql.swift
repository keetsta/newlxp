// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetFileUploadUrlInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      fileExtension: GraphQLNullable<GraphQLEnum<FileExtension>> = nil,
      fileExtensionV2: GraphQLNullable<String> = nil,
      fileName: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "fileExtension": fileExtension,
        "fileExtensionV2": fileExtensionV2,
        "fileName": fileName
      ])
    }

    var fileExtension: GraphQLNullable<GraphQLEnum<FileExtension>> {
      get { __data["fileExtension"] }
      set { __data["fileExtension"] = newValue }
    }

    var fileExtensionV2: GraphQLNullable<String> {
      get { __data["fileExtensionV2"] }
      set { __data["fileExtensionV2"] = newValue }
    }

    var fileName: GraphQLNullable<String> {
      get { __data["fileName"] }
      set { __data["fileName"] = newValue }
    }
  }

}