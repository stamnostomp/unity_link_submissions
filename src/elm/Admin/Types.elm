module Admin.Types exposing (..)

import Json.Decode as Decode
import Shared.Types exposing (..)



-- APPLICATION STATE


type AppState
    = NotAuthenticated
    | AuthenticatingWith String String
    | Authenticated User


type Page
    = SubmissionsPage
    | StudentRecordPage Student (List Submission)
    | StudentManagementPage
    | BeltManagementPage
    | AdminUsersPage
    | PointManagementPage



-- SORTING AND FILTERING


type SortBy
    = ByName
    | ByDate
    | ByBelt
    | ByGradeStatus


type SortDirection
    = Ascending
    | Descending


type StudentSortBy
    = ByStudentName
    | ByStudentCreated
    | ByStudentLastActive



-- FORMS


type alias AdminUserForm =
    { email : String
    , password : String
    , confirmPassword : String
    , displayName : String
    , role : String
    , formError : Maybe String
    }


initAdminUserForm : AdminUserForm
initAdminUserForm =
    { email = ""
    , password = ""
    , confirmPassword = ""
    , displayName = ""
    , role = "admin"
    , formError = Nothing
    }



-- MAIN MODEL


type alias Model =
    { -- App State
      appState : AppState
    , page : Page
    , loading : Bool
    , error : Maybe String
    , success : Maybe String

    -- Authentication
    , loginEmail : String
    , loginPassword : String
    , authError : Maybe String

    -- Data
    , submissions : List Submission
    , students : List Student
    , belts : List Belt
    , adminUsers : List AdminUser

    -- Point Management Data
    , studentPoints : List StudentPoints
    , pointRedemptions : List PointRedemption
    , pointRewards : List PointReward
    , selectedPointRedemption : Maybe PointRedemption

    -- Current Selection/Editing
    , currentSubmission : Maybe Submission
    , currentStudent : Maybe Student
    , studentSubmissions : List Submission
    , editingStudent : Maybe Student
    , editingBelt : Maybe Belt
    , editingAdminUser : Maybe AdminUser
    , editingReward : Maybe PointReward

    -- Filtering and Sorting
    , filterText : String
    , filterBelt : Maybe String
    , filterGraded : Maybe Bool
    , sortBy : SortBy
    , sortDirection : SortDirection
    , studentFilterText : String
    , studentSortBy : StudentSortBy
    , studentSortDirection : SortDirection

    -- Form States
    , tempScore : String
    , tempFeedback : String
    , newStudentName : String
    , newBeltName : String
    , newBeltColor : String
    , newBeltOrder : String
    , newBeltGameOptions : String
    , adminUserForm : AdminUserForm
    , showAdminUserForm : Bool

    -- Point Management Form States
    , newRewardName : String
    , newRewardDescription : String
    , newRewardCost : String
    , newRewardCategory : String
    , newRewardStock : String

    -- Point Management Modal States
    , showAwardPointsModal : Bool
    , awardPointsStudentId : String
    , awardPointsAmount : String
    , awardPointsReason : String

    -- Auto-award settings
    , autoAwardPoints : Bool

    -- Confirmation States
    , confirmDeleteStudent : Maybe Student
    , confirmDeleteSubmission : Maybe Submission
    , confirmDeleteAdmin : Maybe AdminUser
    , confirmDeleteReward : Maybe PointReward

    -- Result Messages
    , adminUserCreationResult : Maybe String
    , adminUserUpdateResult : Maybe String
    , adminUserDeletionResult : Maybe String

    -- Password Reset
    , showPasswordReset : Bool
    , passwordResetEmail : String
    , passwordResetMessage : Maybe String
    }



-- MESSAGES


type
    Msg
    -- Authentication
    = UpdateLoginEmail String
    | UpdateLoginPassword String
    | SubmitLogin
    | PerformSignOut
    | ReceivedAuthState (Result Decode.Error { user : Maybe User, isSignedIn : Bool })
    | ReceivedAuthResult (Result Decode.Error { success : Bool, message : String })
      -- Navigation
    | ShowSubmissionsPage
    | ShowStudentManagementPage
    | ShowBeltManagementPage
    | ShowAdminUsersPage
    | ShowPointManagementPage
    | CloseCurrentPage
      -- Password Reset
    | ShowPasswordReset
    | HidePasswordReset
    | UpdatePasswordResetEmail String
    | SubmitPasswordReset
    | PasswordResetResult (Result Decode.Error { success : Bool, message : String })
      -- Submissions
    | ReceiveSubmissions (Result Decode.Error (List Submission))
    | SelectSubmission Submission
    | CloseSubmission
    | UpdateFilterText String
    | UpdateFilterBelt String
    | UpdateFilterGraded String
    | UpdateSortBy SortBy
    | ToggleSortDirection
    | UpdateTempScore String
    | UpdateTempFeedback String
    | SubmitGrade
    | GradeResult String
    | RefreshSubmissions
    | DeleteSubmission Submission
    | ConfirmDeleteSubmission Submission
    | CancelDeleteSubmission
    | SubmissionDeleted (Result Decode.Error String)
    | UpdateAutoAwardPoints Bool
      -- Students
    | ViewStudentRecord String
    | ReceivedStudentRecord (Result Decode.Error { student : Student, submissions : List Submission })
    | CloseStudentRecord
    | UpdateNewStudentName String
    | CreateNewStudent
    | StudentCreated (Result Decode.Error Student)
    | RequestAllStudents
    | ReceiveAllStudents (Result Decode.Error (List Student))
    | UpdateStudentFilterText String
    | UpdateStudentSortBy StudentSortBy
    | ToggleStudentSortDirection
    | EditStudent Student
    | DeleteStudent Student
    | UpdateEditingStudentName String
    | SaveStudentEdit
    | CancelStudentEdit
    | ConfirmDeleteStudent Student
    | CancelDeleteStudent
    | StudentUpdated (Result Decode.Error Student)
    | StudentDeleted (Result Decode.Error String)
      -- Belts
    | ReceiveBelts (Result Decode.Error (List Belt))
    | UpdateNewBeltName String
    | UpdateNewBeltColor String
    | UpdateNewBeltOrder String
    | UpdateNewBeltGameOptions String
    | AddNewBelt
    | EditBelt Belt
    | CancelEditBelt
    | UpdateBelt
    | DeleteBelt String
    | BeltResult String
    | RefreshBelts
      -- Admin Users
    | ShowAdminUserForm
    | HideAdminUserForm
    | UpdateAdminUserEmail String
    | UpdateAdminUserPassword String
    | UpdateAdminUserConfirmPassword String
    | UpdateAdminUserDisplayName String
    | UpdateAdminUserRole String
    | SubmitAdminUserForm
    | AdminUserCreated (Result Decode.Error { success : Bool, message : String })
    | RequestAllAdmins
    | ReceiveAllAdmins (Result Decode.Error (List AdminUser))
    | EditAdminUser AdminUser
    | UpdateEditingAdminUserEmail String
    | UpdateEditingAdminUserDisplayName String
    | UpdateEditingAdminUserRole String
    | SaveAdminUserEdit
    | CancelAdminUserEdit
    | AdminUserUpdated (Result Decode.Error { success : Bool, message : String })
    | DeleteAdminUser AdminUser
    | ConfirmDeleteAdminUser AdminUser
    | CancelDeleteAdminUser
    | AdminUserDeleted (Result Decode.Error { success : Bool, message : String })
      -- Point Management
    | RequestStudentPoints
    | ReceiveStudentPoints (Result Decode.Error (List StudentPoints))
    | RequestPointRedemptions
    | ReceivePointRedemptions (Result Decode.Error (List PointRedemption))
    | RequestPointRewards
    | ReceivePointRewards (Result Decode.Error (List PointReward))
      -- Award Points
    | ShowAwardPointsModal String
    | HideAwardPointsModal
    | UpdateAwardPointsAmount String
    | UpdateAwardPointsReason String
    | SubmitAwardPoints
    | PointsAwarded (Result Decode.Error { success : Bool, message : String })
      -- Redemption Processing
    | ProcessRedemption PointRedemption RedemptionStatus
    | RedemptionProcessed (Result Decode.Error { success : Bool, message : String })
      -- Reward Management
    | UpdateNewRewardName String
    | UpdateNewRewardDescription String
    | UpdateNewRewardCost String
    | UpdateNewRewardCategory String
    | UpdateNewRewardStock String
    | AddNewReward
    | EditReward PointReward
    | CancelEditReward
    | UpdateReward
    | DeleteReward PointReward
    | ConfirmDeleteReward PointReward
    | CancelDeleteReward
    | RewardResult String
