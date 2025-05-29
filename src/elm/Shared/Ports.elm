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



-- Request student points data


port requestStudentPoints : () -> Cmd msg



-- Receive student points data


port receiveStudentPoints : (Decode.Value -> msg) -> Sub msg



-- Award points to a student


port awardPoints : { studentId : String, points : Int, reason : String } -> Cmd msg



-- Receive result of awarding points


port pointsAwarded : (Decode.Value -> msg) -> Sub msg



-- Request point redemptions


port requestPointRedemptions : () -> Cmd msg



-- Receive point redemptions


port receivePointRedemptions : (Decode.Value -> msg) -> Sub msg



-- Process a redemption (approve, fulfill, cancel)


port processRedemption : { redemptionId : String, status : String, processedBy : String } -> Cmd msg



-- Receive result of processing redemption


port redemptionProcessed : (Decode.Value -> msg) -> Sub msg



-- Request point rewards


port requestPointRewards : () -> Cmd msg



-- Receive point rewards


port receivePointRewards : (Decode.Value -> msg) -> Sub msg



-- Save point reward (add/update)


port savePointReward : Encode.Value -> Cmd msg



-- Delete point reward


port deletePointReward : String -> Cmd msg



-- Receive result of reward operations


port pointRewardResult : (String -> msg) -> Sub msg
