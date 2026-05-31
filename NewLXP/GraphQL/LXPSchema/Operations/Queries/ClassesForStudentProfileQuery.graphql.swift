// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension LXPSchema {
  struct ClassesForStudentProfileQuery: GraphQLQuery {
    static let operationName: String = "ClassesForStudentProfile"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query ClassesForStudentProfile($input: ClassesForStudentProfileInput!, $studentId: UUID!) { classesForStudentProfile(input: $input) { __typename id from to name isOnline meetingLink learningGroupId learningGroup { __typename id name } classroom { __typename id name buildingArea { __typename id name address } } discipline { __typename id name code } topics { __typename id name isCheckPoint } teachers { __typename id user { __typename id firstName lastName middleName } } attendance(studentId: $studentId) { __typename id status lateStatus reason } } }"#
      ))

    public var input: ClassesForStudentProfileInput
    public var studentId: UUID

    public init(
      input: ClassesForStudentProfileInput,
      studentId: UUID
    ) {
      self.input = input
      self.studentId = studentId
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "input": input,
      "studentId": studentId
    ] }

    struct Data: LXPSchema.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("classesForStudentProfile", [ClassesForStudentProfile].self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ClassesForStudentProfileQuery.Data.self
      ] }

      var classesForStudentProfile: [ClassesForStudentProfile] { __data["classesForStudentProfile"] }

      /// ClassesForStudentProfile
      ///
      /// Parent Type: `Class`
      struct ClassesForStudentProfile: LXPSchema.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Class }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", LXPSchema.UUID.self),
          .field("from", LXPSchema.DateTime.self),
          .field("to", LXPSchema.DateTime.self),
          .field("name", String?.self),
          .field("isOnline", Bool?.self),
          .field("meetingLink", String?.self),
          .field("learningGroupId", LXPSchema.UUID?.self),
          .field("learningGroup", LearningGroup?.self),
          .field("classroom", Classroom?.self),
          .field("discipline", Discipline?.self),
          .field("topics", [Topic].self),
          .field("teachers", [Teacher]?.self),
          .field("attendance", [Attendance]?.self, arguments: ["studentId": .variable("studentId")]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.self
        ] }

        var id: LXPSchema.UUID { __data["id"] }
        var from: LXPSchema.DateTime { __data["from"] }
        var to: LXPSchema.DateTime { __data["to"] }
        var name: String? { __data["name"] }
        var isOnline: Bool? { __data["isOnline"] }
        var meetingLink: String? { __data["meetingLink"] }
        var learningGroupId: LXPSchema.UUID? { __data["learningGroupId"] }
        var learningGroup: LearningGroup? { __data["learningGroup"] }
        var classroom: Classroom? { __data["classroom"] }
        var discipline: Discipline? { __data["discipline"] }
        var topics: [Topic] { __data["topics"] }
        var teachers: [Teacher]? { __data["teachers"] }
        var attendance: [Attendance]? { __data["attendance"] }

        /// ClassesForStudentProfile.LearningGroup
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.LearningGroup.self
          ] }

          var id: LXPSchema.UUID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// ClassesForStudentProfile.Classroom
        ///
        /// Parent Type: `Classroom`
        struct Classroom: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Classroom }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.UUID.self),
            .field("name", String.self),
            .field("buildingArea", BuildingArea?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.Classroom.self
          ] }

          var id: LXPSchema.UUID { __data["id"] }
          var name: String { __data["name"] }
          var buildingArea: BuildingArea? { __data["buildingArea"] }

          /// ClassesForStudentProfile.Classroom.BuildingArea
          ///
          /// Parent Type: `BuildingArea`
          struct BuildingArea: LXPSchema.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.BuildingArea }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", LXPSchema.UUID.self),
              .field("name", String.self),
              .field("address", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.Classroom.BuildingArea.self
            ] }

            var id: LXPSchema.UUID { __data["id"] }
            var name: String { __data["name"] }
            var address: String { __data["address"] }
          }
        }

        /// ClassesForStudentProfile.Discipline
        ///
        /// Parent Type: `Discipline`
        struct Discipline: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Discipline }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.UUID.self),
            .field("name", String.self),
            .field("code", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.Discipline.self
          ] }

          var id: LXPSchema.UUID { __data["id"] }
          var name: String { __data["name"] }
          var code: String? { __data["code"] }
        }

        /// ClassesForStudentProfile.Topic
        ///
        /// Parent Type: `DisciplineTopic`
        struct Topic: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.DisciplineTopic }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.UUID.self),
            .field("name", String.self),
            .field("isCheckPoint", Bool.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.Topic.self
          ] }

          var id: LXPSchema.UUID { __data["id"] }
          var name: String { __data["name"] }
          var isCheckPoint: Bool { __data["isCheckPoint"] }
        }

        /// ClassesForStudentProfile.Teacher
        ///
        /// Parent Type: `Teacher`
        struct Teacher: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.Teacher }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.ID.self),
            .field("user", User.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.Teacher.self
          ] }

          var id: LXPSchema.ID { __data["id"] }
          var user: User { __data["user"] }

          /// ClassesForStudentProfile.Teacher.User
          ///
          /// Parent Type: `User`
          struct User: LXPSchema.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.User }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", LXPSchema.ID.self),
              .field("firstName", String?.self),
              .field("lastName", String?.self),
              .field("middleName", String?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.Teacher.User.self
            ] }

            var id: LXPSchema.ID { __data["id"] }
            /// User first name
            var firstName: String? { __data["firstName"] }
            /// User last name
            var lastName: String? { __data["lastName"] }
            /// User middle name
            var middleName: String? { __data["middleName"] }
          }
        }

        /// ClassesForStudentProfile.Attendance
        ///
        /// Parent Type: `ClassAttendance`
        struct Attendance: LXPSchema.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { LXPSchema.Objects.ClassAttendance }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LXPSchema.UUID.self),
            .field("status", GraphQLEnum<LXPSchema.ClassAttendanceStatus>.self),
            .field("lateStatus", GraphQLEnum<LXPSchema.ClassAttendanceLateStatus>.self),
            .field("reason", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ClassesForStudentProfileQuery.Data.ClassesForStudentProfile.Attendance.self
          ] }

          var id: LXPSchema.UUID { __data["id"] }
          var status: GraphQLEnum<LXPSchema.ClassAttendanceStatus> { __data["status"] }
          var lateStatus: GraphQLEnum<LXPSchema.ClassAttendanceLateStatus> { __data["lateStatus"] }
          var reason: String? { __data["reason"] }
        }
      }
    }
  }

}