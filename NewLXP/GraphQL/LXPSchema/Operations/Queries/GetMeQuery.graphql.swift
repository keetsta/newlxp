// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct GetMeQuery: GraphQLQuery {
    static let operationName: String = "GetMe"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetMe { getMe { __typename id email firstName lastName middleName avatar isLead student { __typename id learningGroups { __typename learningGroup { __typename id name students { __typename id firstName lastName middleName email avatar } } } studentSpecialties { __typename specialtyId specialty { __typename id name code } } suborganizations_V2 { __typename suborganization { __typename id name } } } } }"#
      ))

    public init() {}

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("getMe", GetMe.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetMeQuery.Data.self
      ] }

      var getMe: GetMe { __data["getMe"] }

      /// GetMe
      ///
      /// Parent Type: `User`
      struct GetMe: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.User }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", LXPSchema.ID.self),
          .field("email", String.self),
          .field("firstName", String?.self),
          .field("lastName", String?.self),
          .field("middleName", String?.self),
          .field("avatar", String?.self),
          .field("isLead", Bool.self),
          .field("student", Student?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetMeQuery.Data.GetMe.self
        ] }

        var id: LXPSchema.ID { __data["id"] }
        /// User email
        var email: String { __data["email"] }
        /// User first name
        var firstName: String? { __data["firstName"] }
        /// User last name
        var lastName: String? { __data["lastName"] }
        /// User middle name
        var middleName: String? { __data["middleName"] }
        /// User avatar URL
        var avatar: String? { __data["avatar"] }
        /// User is admin of the demo organization
        var isLead: Bool { __data["isLead"] }
        var student: Student? { __data["student"] }

        /// GetMe.Student
        ///
        /// Parent Type: `Student`
        struct Student: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Student }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.ID.self),
            .field("learningGroups", [LearningGroup].self),
            .field("studentSpecialties", [StudentSpecialty].self),
            .field("suborganizations_V2", [Suborganizations_V2].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetMeQuery.Data.GetMe.Student.self
          ] }

          var id: LXPSchema.ID { __data["id"] }
          var learningGroups: [LearningGroup] { __data["learningGroups"] }
          var studentSpecialties: [StudentSpecialty] { __data["studentSpecialties"] }
          var suborganizations_V2: [Suborganizations_V2] { __data["suborganizations_V2"] }

          /// GetMe.Student.LearningGroup
          ///
          /// Parent Type: `StudentLearningGroup`
          struct LearningGroup: LXPSchema.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.StudentLearningGroup }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("learningGroup", LearningGroup.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetMeQuery.Data.GetMe.Student.LearningGroup.self
            ] }

            var learningGroup: LearningGroup { __data["learningGroup"] }

            /// GetMe.Student.LearningGroup.LearningGroup
            ///
            /// Parent Type: `LearningGroup`
            struct LearningGroup: LXPSchema.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.LearningGroup }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", LXPSchema.UUID.self),
                .field("name", String.self),
                .field("students", [Student].self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetMeQuery.Data.GetMe.Student.LearningGroup.LearningGroup.self
              ] }

              var id: LXPSchema.UUID { __data["id"] }
              var name: String { __data["name"] }
              var students: [Student] { __data["students"] }

              /// GetMe.Student.LearningGroup.LearningGroup.Student
              ///
              /// Parent Type: `User`
              struct Student: LXPSchema.SelectionSet {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.User }
                static var __selections: [ApolloAPI.Selection] { [
                  .field("__typename", String.self),
                  .field("id", LXPSchema.ID.self),
                  .field("firstName", String?.self),
                  .field("lastName", String?.self),
                  .field("middleName", String?.self),
                  .field("email", String.self),
                  .field("avatar", String?.self),
                ] }
                static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  GetMeQuery.Data.GetMe.Student.LearningGroup.LearningGroup.Student.self
                ] }

                var id: LXPSchema.ID { __data["id"] }
                /// User first name
                var firstName: String? { __data["firstName"] }
                /// User last name
                var lastName: String? { __data["lastName"] }
                /// User middle name
                var middleName: String? { __data["middleName"] }
                /// User email
                var email: String { __data["email"] }
                /// User avatar URL
                var avatar: String? { __data["avatar"] }
              }
            }
          }

          /// GetMe.Student.StudentSpecialty
          ///
          /// Parent Type: `StudentSpecialty`
          struct StudentSpecialty: LXPSchema.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.StudentSpecialty }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("specialtyId", LXPSchema.ID.self),
              .field("specialty", Specialty.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetMeQuery.Data.GetMe.Student.StudentSpecialty.self
            ] }

            var specialtyId: LXPSchema.ID { __data["specialtyId"] }
            var specialty: Specialty { __data["specialty"] }

            /// GetMe.Student.StudentSpecialty.Specialty
            ///
            /// Parent Type: `Specialty`
            struct Specialty: LXPSchema.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Specialty }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", LXPSchema.UUID.self),
                .field("name", String.self),
                .field("code", String.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetMeQuery.Data.GetMe.Student.StudentSpecialty.Specialty.self
              ] }

              var id: LXPSchema.UUID { __data["id"] }
              var name: String { __data["name"] }
              var code: String { __data["code"] }
            }
          }

          /// GetMe.Student.Suborganizations_V2
          ///
          /// Parent Type: `StudentSuborganization`
          struct Suborganizations_V2: LXPSchema.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.StudentSuborganization }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("suborganization", Suborganization.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetMeQuery.Data.GetMe.Student.Suborganizations_V2.self
            ] }

            var suborganization: Suborganization { __data["suborganization"] }

            /// GetMe.Student.Suborganizations_V2.Suborganization
            ///
            /// Parent Type: `Suborganization`
            struct Suborganization: LXPSchema.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Suborganization }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", LXPSchema.ID.self),
                .field("name", String.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetMeQuery.Data.GetMe.Student.Suborganizations_V2.Suborganization.self
              ] }

              var id: LXPSchema.ID { __data["id"] }
              var name: String { __data["name"] }
            }
          }
        }
      }
    }
  }

}