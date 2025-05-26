port module Shared.Ports exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode



-- Authentication ports


port signIn : Encode.Value -> Cmd msg


port signOut : () -> Cmd msg


port receiveAuthState : (Decode.Value -> msg) -> Sub msg


port receiveAuthResult : (Decode.Value -> msg) -> Sub msg



-- Password reset ports


port requestPasswordReset : String -> Cmd msg


port passwordResetResult : (Decode.Value -> msg) -> Sub msg



-- Submissions ports


port requestSubmissions : () -> Cmd msg


port receiveSubmissions : (Decode.Value -> msg) -> Sub msg


port saveGrade : Encode.Value -> Cmd msg


port gradeResult : (String -> msg) -> Sub msg


port deleteSubmission : String -> Cmd msg


port submissionDeleted : (Decode.Value -> msg) -> Sub msg



-- Student ports


port requestStudentRecord : String -> Cmd msg


port receiveStudentRecord : (Decode.Value -> msg) -> Sub msg


port createStudent : Encode.Value -> Cmd msg


port studentCreated : (Decode.Value -> msg) -> Sub msg


port requestAllStudents : () -> Cmd msg


port receiveAllStudents : (Decode.Value -> msg) -> Sub msg


port updateStudent : Encode.Value -> Cmd msg


port deleteStudent : String -> Cmd msg


port studentUpdated : (Decode.Value -> msg) -> Sub msg


port studentDeleted : (Decode.Value -> msg) -> Sub msg



-- Belt management ports


port requestBelts : () -> Cmd msg


port receiveBelts : (Decode.Value -> msg) -> Sub msg


port saveBelt : Encode.Value -> Cmd msg


port deleteBelt : String -> Cmd msg


port beltResult : (String -> msg) -> Sub msg



-- Admin user management ports


port createAdminUser : { email : String, password : String, displayName : String, role : String } -> Cmd msg


port adminUserCreated : (Decode.Value -> msg) -> Sub msg


port requestAllAdmins : () -> Cmd msg


port receiveAllAdmins : (Decode.Value -> msg) -> Sub msg


port deleteAdminUser : String -> Cmd msg


port adminUserDeleted : (Decode.Value -> msg) -> Sub msg


port updateAdminUser : Encode.Value -> Cmd msg


port adminUserUpdated : (Decode.Value -> msg) -> Sub msg
