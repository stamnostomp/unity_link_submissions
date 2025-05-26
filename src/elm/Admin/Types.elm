module Admin.Types exposing (..)

import Json.Decode as Decode
import Shared.Types exposing (..)



-- COPY THESE TYPE DEFINITIONS FROM YOUR CURRENT Admin.elm:
-- (Around lines 50-150)


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


type alias AdminUserForm =
    { email : String
    , password : String
    , confirmPassword : String
    , displayName : String
    , role : String
    , formError : Maybe String
    }



-- MODEL


type alias Student =
    { id : String
    , name : String
    , created : String
    , lastActive : String
    }


type alias Submission =
    { id : String
    , studentId : String
    , studentName : String
    , beltLevel : String
    , gameName : String
    , githubLink : String
    , notes : String
    , submissionDate : String
    , grade : Maybe Grade
    }


type alias Grade =
    { score : Int
    , feedback : String
    , gradedBy : String
    , gradingDate : String
    }


type alias User =
    { uid : String
    , email : String
    , displayName : String
    , role : String
    }


type alias Belt =
    { id : String
    , name : String
    , color : String
    , order : Int
    , gameOptions : List String
    }


type alias AdminUserForm =
    { email : String
    , password : String
    , confirmPassword : String
    , displayName : String
    , role : String
    , formError : Maybe String
    }


type alias AdminUser =
    { uid : String
    , email : String
    , displayName : String
    , role : String
    , createdBy : Maybe String
    , createdAt : Maybe String
    }



-- types


type AppState
    = NotAuthenticated
    | AuthenticatingWith String String
    | Authenticated User


type Page
    = SubmissionsPage
    | StudentRecordPage Student (List Submission)
    | CreateStudentPage
    | BeltManagementPage
    | AdminUsersPage -- New page type


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


type alias Model =
    { appState : AppState
    , page : Page
    , loginEmail : String
    , loginPassword : String
    , authError : Maybe String
    , submissions : List Submission
    , currentSubmission : Maybe Submission
    , currentStudent : Maybe Student
    , studentSubmissions : List Submission
    , loading : Bool
    , error : Maybe String
    , success : Maybe String
    , filterText : String
    , filterBelt : Maybe String
    , filterGraded : Maybe Bool
    , sortBy : SortBy
    , sortDirection : SortDirection
    , tempScore : String
    , tempFeedback : String
    , newStudentName : String
    , belts : List Belt
    , newBeltName : String
    , newBeltColor : String
    , newBeltOrder : String
    , newBeltGameOptions : String
    , editingBelt : Maybe Belt
    , students : List Student
    , studentFilterText : String
    , studentSortBy : StudentSortBy
    , studentSortDirection : SortDirection
    , editingStudent : Maybe Student
    , confirmDeleteStudent : Maybe Student
    , confirmDeleteSubmission : Maybe Submission
    , adminUserForm : AdminUserForm
    , showAdminUserForm : Bool
    , adminUserCreationResult : Maybe String
    , adminUsers : List AdminUser
    , editingAdminUser : Maybe AdminUser
    , confirmDeleteAdmin : Maybe AdminUser
    , adminUserDeletionResult : Maybe String
    , adminUserUpdateResult : Maybe String
    , showPasswordReset : Bool
    , passwordResetEmail : String
    , passwordResetMessage : Maybe String
    }



-- Helper function


initAdminUserForm : AdminUserForm
initAdminUserForm =
    { email = ""
    , password = ""
    , confirmPassword = ""
    , displayName = ""
    , role = "admin"
    , formError = Nothing
    }
