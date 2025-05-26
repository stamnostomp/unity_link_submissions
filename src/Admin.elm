port module Admin exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- PORTS


port requestSubmissions : () -> Cmd msg


port receiveSubmissions : (Decode.Value -> msg) -> Sub msg


port saveGrade : Encode.Value -> Cmd msg


port gradeResult : (String -> msg) -> Sub msg



-- Authentication ports


port signIn : Encode.Value -> Cmd msg


port signOut : () -> Cmd msg


port receiveAuthState : (Decode.Value -> msg) -> Sub msg


port receiveAuthResult : (Decode.Value -> msg) -> Sub msg



-- Student record ports


port requestStudentRecord : String -> Cmd msg


port receiveStudentRecord : (Decode.Value -> msg) -> Sub msg



-- Student creation ports


port createStudent : Encode.Value -> Cmd msg


port studentCreated : (Decode.Value -> msg) -> Sub msg



-- Student listing ports


port requestAllStudents : () -> Cmd msg


port receiveAllStudents : (Decode.Value -> msg) -> Sub msg



-- Student edit/delete ports


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



-- Submission deletion ports


port deleteSubmission : String -> Cmd msg


port submissionDeleted : (Decode.Value -> msg) -> Sub msg



-- Admin user creation ports


port createAdminUser : { email : String, password : String, displayName : String, role : String } -> Cmd msg


port adminUserCreated : (Decode.Value -> msg) -> Sub msg



-- Ports for admin user management


port requestAllAdmins : () -> Cmd msg


port receiveAllAdmins : (Decode.Value -> msg) -> Sub msg


port deleteAdminUser : String -> Cmd msg


port adminUserDeleted : (Decode.Value -> msg) -> Sub msg


port updateAdminUser : Encode.Value -> Cmd msg


port adminUserUpdated : (Decode.Value -> msg) -> Sub msg



-- Ports for password reset


port requestPasswordReset : String -> Cmd msg


port passwordResetResult : (Decode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
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



-- Initialize the admin user form


initAdminUserForm : AdminUserForm
initAdminUserForm =
    { email = ""
    , password = ""
    , confirmPassword = ""
    , displayName = ""
    , role = "admin"
    , formError = Nothing
    }


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


init : () -> ( Model, Cmd Msg )
init _ =
    ( { appState = NotAuthenticated
      , page = SubmissionsPage
      , loginEmail = ""
      , loginPassword = ""
      , authError = Nothing
      , submissions = []
      , currentSubmission = Nothing
      , currentStudent = Nothing
      , studentSubmissions = []
      , loading = False
      , error = Nothing
      , success = Nothing
      , filterText = ""
      , filterBelt = Nothing
      , filterGraded = Nothing
      , sortBy = ByDate
      , sortDirection = Descending
      , tempScore = ""
      , tempFeedback = ""
      , newStudentName = ""
      , belts = []
      , newBeltName = ""
      , newBeltColor = "#000000"
      , newBeltOrder = ""
      , newBeltGameOptions = ""
      , editingBelt = Nothing
      , students = []
      , studentFilterText = ""
      , studentSortBy = ByStudentName
      , studentSortDirection = Ascending
      , editingStudent = Nothing
      , confirmDeleteStudent = Nothing
      , confirmDeleteSubmission = Nothing
      , adminUserForm = initAdminUserForm
      , showAdminUserForm = False
      , adminUserCreationResult = Nothing
      , adminUsers = []
      , editingAdminUser = Nothing
      , confirmDeleteAdmin = Nothing
      , adminUserDeletionResult = Nothing
      , adminUserUpdateResult = Nothing
      , showPasswordReset = False
      , passwordResetEmail = ""
      , passwordResetMessage = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = UpdateLoginEmail String
    | UpdateLoginPassword String
    | SubmitLogin
    | PerformSignOut
    | ReceivedAuthState (Result Decode.Error { user : Maybe User, isSignedIn : Bool })
    | ReceivedAuthResult (Result Decode.Error { success : Bool, message : String })
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
    | ViewStudentRecord String
    | ReceivedStudentRecord (Result Decode.Error { student : Student, submissions : List Submission })
    | CloseStudentRecord
    | ShowCreateStudentForm
    | CloseCreateStudentForm
    | UpdateNewStudentName String
    | CreateNewStudent
    | StudentCreated (Result Decode.Error Student)
    | ShowBeltManagement
    | CloseBeltManagement
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
    | DeleteSubmission Submission
    | ConfirmDeleteSubmission Submission
    | CancelDeleteSubmission
    | SubmissionDeleted (Result Decode.Error String)
    | ShowAdminUsersPage
    | ReturnToSubmissionsPage
    | ShowAdminUserForm
    | HideAdminUserForm
    | UpdateAdminUserEmail String
    | UpdateAdminUserPassword String
    | UpdateAdminUserConfirmPassword String
    | UpdateAdminUserDisplayName String
    | SubmitAdminUserForm
    | AdminUserCreated (Result Decode.Error { success : Bool, message : String })
    | RequestAllAdmins
    | ReceiveAllAdmins (Result Decode.Error (List AdminUser))
    | EditAdminUser AdminUser
    | UpdateEditingAdminUserEmail String
    | UpdateEditingAdminUserDisplayName String
    | SaveAdminUserEdit
    | CancelAdminUserEdit
    | AdminUserUpdated (Result Decode.Error { success : Bool, message : String })
    | DeleteAdminUser AdminUser
    | ConfirmDeleteAdminUser AdminUser
    | CancelDeleteAdminUser
    | AdminUserDeleted (Result Decode.Error { success : Bool, message : String })
    | UpdateAdminUserRole String
    | UpdateEditingAdminUserRole String
    | ShowPasswordReset
    | HidePasswordReset
    | UpdatePasswordResetEmail String
    | SubmitPasswordReset
    | PasswordResetResult (Result Decode.Error { success : Bool, message : String })


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowPasswordReset ->
            ( { model | showPasswordReset = True, passwordResetEmail = model.loginEmail }, Cmd.none )

        HidePasswordReset ->
            ( { model | showPasswordReset = False, passwordResetMessage = Nothing }, Cmd.none )

        UpdatePasswordResetEmail email ->
            ( { model | passwordResetEmail = email }, Cmd.none )

        SubmitPasswordReset ->
            if String.isEmpty model.passwordResetEmail then
                ( { model | passwordResetMessage = Just "Please enter your email address" }, Cmd.none )

            else
                ( { model | passwordResetMessage = Nothing, loading = True }
                , requestPasswordReset model.passwordResetEmail
                )

        PasswordResetResult result ->
            case result of
                Ok resetResult ->
                    ( { model
                        | passwordResetMessage = Just resetResult.message
                        , loading = False
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | passwordResetMessage = Just ("Error: " ++ Decode.errorToString error)
                        , loading = False
                      }
                    , Cmd.none
                    )

        UpdateEditingAdminUserRole role ->
            case model.editingAdminUser of
                Just adminUser ->
                    let
                        updatedAdminUser =
                            { adminUser | role = role }
                    in
                    ( { model | editingAdminUser = Just updatedAdminUser }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateLoginEmail email ->
            ( { model | loginEmail = email }, Cmd.none )

        UpdateLoginPassword password ->
            ( { model | loginPassword = password }, Cmd.none )

        SubmitLogin ->
            if String.isEmpty model.loginEmail || String.isEmpty model.loginPassword then
                ( { model | authError = Just "Please enter both email and password" }, Cmd.none )

            else
                ( { model
                    | appState = AuthenticatingWith model.loginEmail model.loginPassword
                    , authError = Nothing
                    , loading = True
                  }
                , signIn (encodeCredentials model.loginEmail model.loginPassword)
                )

        PerformSignOut ->
            ( { model | appState = NotAuthenticated, loading = True }, signOut () )

        ReceivedAuthState result ->
            case result of
                Ok authState ->
                    if authState.isSignedIn then
                        case authState.user of
                            Just user ->
                                ( { model
                                    | appState = Authenticated user
                                    , loading = True
                                    , authError = Nothing
                                  }
                                , Cmd.batch [ requestSubmissions (), requestBelts () ]
                                )

                            Nothing ->
                                ( { model | appState = NotAuthenticated, loading = False }, Cmd.none )

                    else
                        ( { model | appState = NotAuthenticated, loading = False }, Cmd.none )

                Err error ->
                    ( { model | appState = NotAuthenticated, authError = Just (Decode.errorToString error), loading = False }, Cmd.none )

        ReceivedAuthResult result ->
            case result of
                Ok authResult ->
                    if authResult.success then
                        ( { model | loading = True }, Cmd.none )

                    else
                        ( { model
                            | appState = NotAuthenticated
                            , authError = Just authResult.message
                            , loading = False
                          }
                        , Cmd.none
                        )

                Err error ->
                    ( { model
                        | appState = NotAuthenticated
                        , authError = Just (Decode.errorToString error)
                        , loading = False
                      }
                    , Cmd.none
                    )

        ReceiveSubmissions result ->
            case result of
                Ok submissions ->
                    ( { model | submissions = submissions, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        SelectSubmission submission ->
            let
                tempScore =
                    submission.grade
                        |> Maybe.map (\g -> String.fromInt g.score)
                        |> Maybe.withDefault ""

                tempFeedback =
                    submission.grade
                        |> Maybe.map .feedback
                        |> Maybe.withDefault ""
            in
            ( { model
                | currentSubmission = Just submission
                , tempScore = tempScore
                , tempFeedback = tempFeedback
              }
            , Cmd.none
            )

        CloseSubmission ->
            ( { model | currentSubmission = Nothing }, Cmd.none )

        UpdateFilterText text ->
            ( { model | filterText = text }, Cmd.none )

        UpdateFilterBelt belt ->
            let
                filterBelt =
                    if belt == "all" then
                        Nothing

                    else
                        Just belt
            in
            ( { model | filterBelt = filterBelt }, Cmd.none )

        UpdateFilterGraded status ->
            let
                filterGraded =
                    case status of
                        "all" ->
                            Nothing

                        "graded" ->
                            Just True

                        "ungraded" ->
                            Just False

                        _ ->
                            Nothing
            in
            ( { model | filterGraded = filterGraded }, Cmd.none )

        UpdateSortBy sortBy ->
            ( { model | sortBy = sortBy }, Cmd.none )

        ToggleSortDirection ->
            let
                newDirection =
                    case model.sortDirection of
                        Ascending ->
                            Descending

                        Descending ->
                            Ascending
            in
            ( { model | sortDirection = newDirection }, Cmd.none )

        UpdateTempScore score ->
            ( { model | tempScore = score }, Cmd.none )

        UpdateTempFeedback feedback ->
            ( { model | tempFeedback = feedback }, Cmd.none )

        SubmitGrade ->
            case model.currentSubmission of
                Just submission ->
                    let
                        scoreResult =
                            String.toInt model.tempScore
                    in
                    case scoreResult of
                        Just score ->
                            if score < 0 || score > 100 then
                                ( { model | error = Just "Score must be between 0 and 100" }, Cmd.none )

                            else
                                let
                                    -- Current date will be set on the server side
                                    grade =
                                        { score = score
                                        , feedback = model.tempFeedback
                                        , gradedBy = getUserEmail model
                                        , gradingDate = "2025-03-03" -- This will be overwritten on the server
                                        }

                                    gradeData =
                                        Encode.object
                                            [ ( "submissionId", Encode.string submission.id )
                                            , ( "grade", encodeGrade grade )
                                            ]
                                in
                                ( { model | loading = True, error = Nothing, success = Nothing }
                                , saveGrade gradeData
                                )

                        Nothing ->
                            ( { model | error = Just "Please enter a valid score (0-100)" }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        GradeResult result ->
            if String.startsWith "Error:" result then
                ( { model | error = Just result, loading = False, success = Nothing }, Cmd.none )

            else
                ( { model | success = Just "Grade saved successfully", loading = False, error = Nothing }
                , requestSubmissions ()
                )

        RefreshSubmissions ->
            ( { model | loading = True }, requestSubmissions () )

        ViewStudentRecord studentId ->
            ( { model | loading = True, page = SubmissionsPage }
            , requestStudentRecord studentId
            )

        ReceivedStudentRecord result ->
            case result of
                Ok { student, submissions } ->
                    ( { model
                        | loading = False
                        , currentStudent = Just student
                        , studentSubmissions = submissions
                        , page = StudentRecordPage student submissions
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Failed to load student record: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        CloseStudentRecord ->
            ( { model
                | page = SubmissionsPage
                , currentStudent = Nothing
                , studentSubmissions = []
              }
            , Cmd.none
            )

        CloseCreateStudentForm ->
            ( { model | page = SubmissionsPage }, Cmd.none )

        UpdateNewStudentName name ->
            ( { model | newStudentName = name }, Cmd.none )

        CreateNewStudent ->
            let
                trimmedName =
                    String.trim model.newStudentName
            in
            if String.isEmpty trimmedName then
                ( { model | error = Just "Please enter a student name" }, Cmd.none )

            else if not (isValidNameFormat trimmedName) then
                ( { model | error = Just "Please enter the name in the format firstname.lastname (e.g., tyler.smith)" }, Cmd.none )

            else
                ( { model | loading = True, error = Nothing }
                , createStudent (encodeNewStudent trimmedName)
                )

        StudentCreated result ->
            case result of
                Ok student ->
                    ( { model
                        | page = StudentRecordPage student []
                        , loading = False
                        , success = Just ("Student record for " ++ student.name ++ " created successfully")
                        , currentStudent = Just student
                        , studentSubmissions = []
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error creating student: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        ShowBeltManagement ->
            ( { model
                | page = BeltManagementPage
                , newBeltName = ""
                , newBeltColor = "#000000"
                , newBeltOrder = ""
                , newBeltGameOptions = ""
                , editingBelt = Nothing
                , error = Nothing
                , success = Nothing
              }
            , requestBelts ()
            )

        CloseBeltManagement ->
            ( { model | page = SubmissionsPage }, Cmd.none )

        ReceiveBelts result ->
            case result of
                Ok belts ->
                    ( { model | belts = belts, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        UpdateNewBeltName name ->
            ( { model | newBeltName = name }, Cmd.none )

        UpdateNewBeltColor color ->
            ( { model | newBeltColor = color }, Cmd.none )

        UpdateNewBeltOrder order ->
            ( { model | newBeltOrder = order }, Cmd.none )

        UpdateNewBeltGameOptions options ->
            ( { model | newBeltGameOptions = options }, Cmd.none )

        AddNewBelt ->
            if String.trim model.newBeltName == "" then
                ( { model | error = Just "Please enter a belt name" }, Cmd.none )

            else
                let
                    orderResult =
                        String.toInt model.newBeltOrder
                in
                case orderResult of
                    Just order ->
                        let
                            gameOptions =
                                model.newBeltGameOptions
                                    |> String.split ","
                                    |> List.map String.trim
                                    |> List.filter (not << String.isEmpty)

                            beltId =
                                model.newBeltName
                                    |> String.toLower
                                    |> String.replace " " "-"

                            newBelt =
                                { id = beltId
                                , name = model.newBeltName
                                , color = model.newBeltColor
                                , order = order
                                , gameOptions = gameOptions
                                }
                        in
                        ( { model | loading = True, error = Nothing }
                        , saveBelt (encodeBelt newBelt)
                        )

                    Nothing ->
                        ( { model | error = Just "Please enter a valid order number" }, Cmd.none )

        EditBelt belt ->
            ( { model
                | editingBelt = Just belt
                , newBeltName = belt.name
                , newBeltColor = belt.color
                , newBeltOrder = String.fromInt belt.order
                , newBeltGameOptions = String.join ", " belt.gameOptions
              }
            , Cmd.none
            )

        CancelEditBelt ->
            ( { model
                | editingBelt = Nothing
                , newBeltName = ""
                , newBeltColor = "#000000"
                , newBeltOrder = ""
                , newBeltGameOptions = ""
              }
            , Cmd.none
            )

        UpdateBelt ->
            case model.editingBelt of
                Just belt ->
                    if String.trim model.newBeltName == "" then
                        ( { model | error = Just "Please enter a belt name" }, Cmd.none )

                    else
                        let
                            orderResult =
                                String.toInt model.newBeltOrder
                        in
                        case orderResult of
                            Just order ->
                                let
                                    gameOptions =
                                        model.newBeltGameOptions
                                            |> String.split ","
                                            |> List.map String.trim
                                            |> List.filter (not << String.isEmpty)

                                    updatedBelt =
                                        { id = belt.id
                                        , name = model.newBeltName
                                        , color = model.newBeltColor
                                        , order = order
                                        , gameOptions = gameOptions
                                        }
                                in
                                ( { model | loading = True, error = Nothing }
                                , saveBelt (encodeBelt updatedBelt)
                                )

                            Nothing ->
                                ( { model | error = Just "Please enter a valid order number" }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        DeleteBelt beltId ->
            ( { model | loading = True }
            , deleteBelt beltId
            )

        BeltResult result ->
            if String.startsWith "Error:" result then
                ( { model
                    | error = Just result
                    , loading = False
                    , success = Nothing
                  }
                , Cmd.none
                )

            else
                ( { model
                    | success = Just result
                    , loading = False
                    , error = Nothing
                    , editingBelt = Nothing
                    , newBeltName = ""
                    , newBeltColor = "#000000"
                    , newBeltOrder = ""
                    , newBeltGameOptions = ""
                  }
                , requestBelts ()
                )

        RefreshBelts ->
            ( { model | loading = True }, requestBelts () )

        ShowCreateStudentForm ->
            ( { model | page = CreateStudentPage, newStudentName = "" }, requestAllStudents () )

        RequestAllStudents ->
            ( { model | loading = True }, requestAllStudents () )

        ReceiveAllStudents result ->
            case result of
                Ok students ->
                    ( { model | students = students, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        UpdateStudentFilterText text ->
            ( { model | studentFilterText = text }, Cmd.none )

        UpdateStudentSortBy sortBy ->
            ( { model | studentSortBy = sortBy }, Cmd.none )

        ToggleStudentSortDirection ->
            let
                newDirection =
                    case model.studentSortDirection of
                        Ascending ->
                            Descending

                        Descending ->
                            Ascending
            in
            ( { model | studentSortDirection = newDirection }, Cmd.none )

        EditStudent student ->
            ( { model | editingStudent = Just student }, Cmd.none )

        UpdateEditingStudentName name ->
            case model.editingStudent of
                Just student ->
                    let
                        updatedStudent =
                            { student | name = name }
                    in
                    ( { model | editingStudent = Just updatedStudent }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveStudentEdit ->
            case model.editingStudent of
                Just student ->
                    if String.trim student.name == "" then
                        ( { model | error = Just "Please enter a student name" }, Cmd.none )

                    else if not (isValidNameFormat student.name) then
                        ( { model | error = Just "Please enter the name in the format firstname.lastname" }, Cmd.none )

                    else
                        ( { model | loading = True, error = Nothing, editingStudent = Nothing }
                        , updateStudent (encodeStudentUpdate student)
                        )

                Nothing ->
                    ( model, Cmd.none )

        CancelStudentEdit ->
            ( { model | editingStudent = Nothing, error = Nothing }, Cmd.none )

        DeleteStudent student ->
            ( { model | confirmDeleteStudent = Just student }, Cmd.none )

        ConfirmDeleteStudent student ->
            ( { model | loading = True, confirmDeleteStudent = Nothing }
            , deleteStudent student.id
            )

        CancelDeleteStudent ->
            ( { model | confirmDeleteStudent = Nothing }, Cmd.none )

        StudentUpdated result ->
            case result of
                Ok student ->
                    let
                        updatedStudents =
                            List.map
                                (\s ->
                                    if s.id == student.id then
                                        student

                                    else
                                        s
                                )
                                model.students
                    in
                    ( { model
                        | loading = False
                        , success = Just ("Student " ++ student.name ++ " updated successfully")
                        , students = updatedStudents
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error updating student: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        StudentDeleted result ->
            case result of
                Ok studentId ->
                    let
                        updatedStudents =
                            List.filter (\s -> s.id /= studentId) model.students
                    in
                    ( { model
                        | loading = False
                        , success = Just "Student deleted successfully"
                        , students = updatedStudents
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error deleting student: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        DeleteSubmission submission ->
            ( { model | confirmDeleteSubmission = Just submission }, Cmd.none )

        ConfirmDeleteSubmission submission ->
            ( { model | loading = True, confirmDeleteSubmission = Nothing }
            , deleteSubmission submission.id
            )

        CancelDeleteSubmission ->
            ( { model | confirmDeleteSubmission = Nothing }, Cmd.none )

        SubmissionDeleted result ->
            case result of
                Ok submissionId ->
                    let
                        updatedSubmissions =
                            List.filter (\s -> s.id /= submissionId) model.submissions
                    in
                    ( { model
                        | loading = False
                        , success = Just "Submission deleted successfully"
                        , submissions = updatedSubmissions
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error deleting submission: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        -- Admin User Management
        ShowAdminUsersPage ->
            if isSuperUser model then
                -- Set the page, reset any previous results, set loading to true, and request admin users
                ( { model
                    | page = AdminUsersPage
                    , adminUserCreationResult = Nothing
                    , adminUserUpdateResult = Nothing
                    , adminUserDeletionResult = Nothing
                    , loading = True -- Set loading to true while data is being fetched
                  }
                , requestAllAdmins ()
                  -- Immediately request admin users
                )

            else
                ( { model | error = Just "You don't have permission to access admin management." }, Cmd.none )

        ReturnToSubmissionsPage ->
            ( { model
                | page = SubmissionsPage
                , adminUserCreationResult = Nothing
                , adminUserUpdateResult = Nothing
                , adminUserDeletionResult = Nothing
                , showAdminUserForm = False
                , editingAdminUser = Nothing
                , confirmDeleteAdmin = Nothing
              }
            , Cmd.none
            )

        ShowAdminUserForm ->
            ( { model | showAdminUserForm = True, adminUserForm = initAdminUserForm }, Cmd.none )

        HideAdminUserForm ->
            ( { model | showAdminUserForm = False }, Cmd.none )

        UpdateAdminUserEmail email ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | email = email }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        UpdateAdminUserPassword password ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | password = password }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        UpdateAdminUserConfirmPassword confirmPassword ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | confirmPassword = confirmPassword }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        UpdateAdminUserDisplayName displayName ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | displayName = displayName }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        SubmitAdminUserForm ->
            let
                form =
                    model.adminUserForm

                -- Basic validation
                validationError =
                    if String.isEmpty form.email then
                        Just "Email is required"

                    else if not (String.contains "@" form.email) then
                        Just "Please enter a valid email address"

                    else if String.isEmpty form.password then
                        Just "Password is required"

                    else if String.length form.password < 6 then
                        Just "Password must be at least 6 characters"

                    else if form.password /= form.confirmPassword then
                        Just "Passwords do not match"

                    else
                        Nothing

                updatedForm =
                    { form | formError = validationError }
            in
            case validationError of
                Just _ ->
                    ( { model | adminUserForm = updatedForm }, Cmd.none )

                Nothing ->
                    ( { model | adminUserForm = updatedForm, loading = True }
                    , createAdminUser
                        { email = form.email
                        , password = form.password
                        , displayName = form.displayName
                        , role = form.role
                        }
                    )

        UpdateAdminUserRole role ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | role = role }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        AdminUserCreated result ->
            case result of
                Ok adminResult ->
                    let
                        message =
                            if adminResult.success then
                                "Success: " ++ adminResult.message

                            else
                                "Error: " ++ adminResult.message
                    in
                    ( { model
                        | adminUserCreationResult = Just message
                        , showAdminUserForm =
                            if adminResult.success then
                                False

                            else
                                model.showAdminUserForm
                        , loading = False
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | adminUserCreationResult = Just ("Error: " ++ Decode.errorToString error)
                        , loading = False
                      }
                    , Cmd.none
                    )

        RequestAllAdmins ->
            ( { model | loading = True, adminUserDeletionResult = Nothing, adminUserUpdateResult = Nothing }
            , requestAllAdmins ()
            )

        ReceiveAllAdmins result ->
            case result of
                Ok adminUsers ->
                    ( { model | adminUsers = adminUsers, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        EditAdminUser adminUser ->
            ( { model | editingAdminUser = Just adminUser }, Cmd.none )

        UpdateEditingAdminUserEmail email ->
            case model.editingAdminUser of
                Just adminUser ->
                    let
                        updatedAdminUser =
                            { adminUser | email = email }
                    in
                    ( { model | editingAdminUser = Just updatedAdminUser }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateEditingAdminUserDisplayName displayName ->
            case model.editingAdminUser of
                Just adminUser ->
                    let
                        updatedAdminUser =
                            { adminUser | displayName = displayName }
                    in
                    ( { model | editingAdminUser = Just updatedAdminUser }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveAdminUserEdit ->
            case model.editingAdminUser of
                Just adminUser ->
                    if String.trim adminUser.email == "" then
                        ( { model | error = Just "Email cannot be empty" }, Cmd.none )

                    else if not (String.contains "@" adminUser.email) then
                        ( { model | error = Just "Please enter a valid email address" }, Cmd.none )

                    else
                        -- Add debug info
                        let
                            _ =
                                { uid = adminUser.uid
                                , email = adminUser.email
                                , displayName = adminUser.displayName
                                , role = adminUser.role
                                }
                        in
                        ( { model | loading = True, editingAdminUser = Nothing, error = Nothing }
                        , updateAdminUser (encodeAdminUserUpdate adminUser)
                        )

                Nothing ->
                    ( model, Cmd.none )

        CancelAdminUserEdit ->
            ( { model | editingAdminUser = Nothing, error = Nothing }, Cmd.none )

        AdminUserUpdated result ->
            case result of
                Ok updateResult ->
                    ( { model
                        | loading = False
                        , adminUserUpdateResult = Just updateResult.message
                      }
                    , if updateResult.success then
                        requestAllAdmins ()

                      else
                        Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error updating admin user: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        DeleteAdminUser adminUser ->
            ( { model | confirmDeleteAdmin = Just adminUser }, Cmd.none )

        ConfirmDeleteAdminUser adminUser ->
            ( { model | loading = True, confirmDeleteAdmin = Nothing }
            , deleteAdminUser adminUser.uid
            )

        CancelDeleteAdminUser ->
            ( { model | confirmDeleteAdmin = Nothing }, Cmd.none )

        AdminUserDeleted result ->
            case result of
                Ok deleteResult ->
                    ( { model
                        | loading = False
                        , adminUserDeletionResult = Just deleteResult.message
                      }
                    , if deleteResult.success then
                        requestAllAdmins ()

                      else
                        Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error deleting admin user: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveAuthState (decodeAuthState >> ReceivedAuthState)
        , receiveAuthResult (decodeAuthResult >> ReceivedAuthResult)
        , receiveSubmissions (decodeSubmissionsResponse >> ReceiveSubmissions)
        , receiveStudentRecord (decodeStudentRecordResponse >> ReceivedStudentRecord)
        , studentCreated (decodeStudentResponse >> StudentCreated)
        , receiveBelts (decodeBeltsResponse >> ReceiveBelts)
        , receiveAllStudents (decodeStudentsResponse >> ReceiveAllStudents)
        , studentUpdated (decodeStudentResponse >> StudentUpdated)
        , studentDeleted (decodeStudentDeletedResponse >> StudentDeleted)
        , submissionDeleted (decodeSubmissionDeletedResponse >> SubmissionDeleted)
        , gradeResult GradeResult
        , beltResult BeltResult
        , adminUserCreated (decodeAdminCreationResult >> AdminUserCreated)
        , receiveAllAdmins (decodeAdminUsersResponse >> ReceiveAllAdmins)
        , adminUserDeleted (decodeAdminActionResult >> AdminUserDeleted)
        , adminUserUpdated (decodeAdminActionResult >> AdminUserUpdated)
        , passwordResetResult (decodePasswordResetResult >> PasswordResetResult)
        ]


decodePasswordResetResult : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodePasswordResetResult value =
    let
        decoder =
            Decode.map2 (\success message -> { success = success, message = message })
                (Decode.field "success" Decode.bool)
                (Decode.field "message" Decode.string)
    in
    Decode.decodeValue decoder value


decodeAdminCreationResult : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodeAdminCreationResult value =
    Decode.decodeValue
        (Decode.map2 (\success message -> { success = success, message = message })
            (Decode.field "success" Decode.bool)
            (Decode.field "message" Decode.string)
        )
        value


adminUserDecoder : Decoder AdminUser
adminUserDecoder =
    Decode.map6 AdminUser
        (Decode.field "uid" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.oneOf
            [ Decode.field "role" Decode.string
            , Decode.succeed "admin" -- Default to adimn
            ]
        )
        (Decode.maybe (Decode.field "createdBy" Decode.string))
        (Decode.maybe (Decode.field "createdAt" Decode.string))


decodeAdminUsersResponse : Decode.Value -> Result Decode.Error (List AdminUser)
decodeAdminUsersResponse value =
    Decode.decodeValue (Decode.list adminUserDecoder) value


decodeAdminActionResult : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodeAdminActionResult value =
    Decode.decodeValue
        (Decode.map2 (\success message -> { success = success, message = message })
            (Decode.field "success" Decode.bool)
            (Decode.field "message" Decode.string)
        )
        value


decodeStudentsResponse : Decode.Value -> Result Decode.Error (List Student)
decodeStudentsResponse value =
    Decode.decodeValue (Decode.list studentDecoder) value


decodeStudentDeletedResponse : Decode.Value -> Result Decode.Error String
decodeStudentDeletedResponse value =
    Decode.decodeValue Decode.string value


decodeSubmissionDeletedResponse : Decode.Value -> Result Decode.Error String
decodeSubmissionDeletedResponse value =
    Decode.decodeValue Decode.string value


decodeSubmissionsResponse : Decode.Value -> Result Decode.Error (List Submission)
decodeSubmissionsResponse value =
    Decode.decodeValue (Decode.list submissionDecoder) value


submissionDecoder : Decoder Submission
submissionDecoder =
    Decode.map6
        (\id gameBelt gameName githubLink notes submissionDate ->
            { id = id
            , studentId = "" -- Temporary value, will be filled in later
            , studentName = "Unknown" -- Default value, will be overridden if available
            , beltLevel = gameBelt
            , gameName = gameName
            , githubLink = githubLink
            , notes = notes
            , submissionDate = submissionDate
            , grade = Nothing
            }
        )
        (Decode.field "id" Decode.string)
        (Decode.field "beltLevel" Decode.string)
        (Decode.field "gameName" Decode.string)
        (Decode.field "githubLink" Decode.string)
        (Decode.field "notes" Decode.string)
        (Decode.field "submissionDate" Decode.string)
        |> Decode.andThen
            (\submission ->
                -- Try to get studentId if it exists
                Decode.maybe (Decode.field "studentId" Decode.string)
                    |> Decode.map
                        (\maybeStudentId ->
                            case maybeStudentId of
                                Just studentId ->
                                    { submission | studentId = studentId }

                                Nothing ->
                                    -- If no studentId, use a default based on the submission ID
                                    { submission | studentId = submission.id }
                        )
            )
        |> Decode.andThen
            (\submission ->
                -- Try to get studentName if it exists
                Decode.maybe (Decode.field "studentName" Decode.string)
                    |> Decode.map
                        (\maybeStudentName ->
                            case maybeStudentName of
                                Just studentName ->
                                    { submission | studentName = studentName }

                                Nothing ->
                                    -- If no studentName, derive it from studentId
                                    { submission | studentName = capitalizeWords (String.replace "-" " " submission.studentId) }
                        )
            )
        |> Decode.andThen
            (\submission ->
                -- Finally check for a grade
                Decode.maybe (Decode.field "grade" gradeDecoder)
                    |> Decode.map (\grade -> { submission | grade = grade })
            )


gradeDecoder : Decoder Grade
gradeDecoder =
    Decode.map4 Grade
        (Decode.field "score" Decode.int)
        (Decode.field "feedback" Decode.string)
        (Decode.field "gradedBy" Decode.string)
        (Decode.field "gradingDate" Decode.string)


studentDecoder : Decoder Student
studentDecoder =
    Decode.map4 Student
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "created" Decode.string)
        (Decode.field "lastActive" Decode.string)


beltDecoder : Decoder Belt
beltDecoder =
    Decode.map5 Belt
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "color" Decode.string)
        (Decode.field "order" Decode.int)
        (Decode.field "gameOptions" (Decode.list Decode.string))


decodeBeltsResponse : Decode.Value -> Result Decode.Error (List Belt)
decodeBeltsResponse value =
    Decode.decodeValue (Decode.list beltDecoder) value


decodeStudentRecordResponse : Decode.Value -> Result Decode.Error { student : Student, submissions : List Submission }
decodeStudentRecordResponse value =
    let
        decoder =
            Decode.map2 (\student submissions -> { student = student, submissions = submissions })
                (Decode.field "student" studentDecoder)
                (Decode.field "submissions" (Decode.list submissionDecoder))
    in
    Decode.decodeValue decoder value


userDecoder : Decoder User
userDecoder =
    Decode.map4 User
        (Decode.field "uid" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.oneOf
            [ Decode.field "role" Decode.string
            , Decode.succeed "admin" -- default to adimn role
            ]
        )


decodeStudentResponse : Decode.Value -> Result Decode.Error Student
decodeStudentResponse value =
    Decode.decodeValue studentDecoder value


decodeAuthState : Decode.Value -> Result Decode.Error { user : Maybe User, isSignedIn : Bool }
decodeAuthState value =
    let
        decoder =
            Decode.map2 (\user isSignedIn -> { user = user, isSignedIn = isSignedIn })
                (Decode.field "user" (Decode.nullable userDecoder))
                (Decode.field "isSignedIn" Decode.bool)
    in
    Decode.decodeValue decoder value


decodeAuthResult : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodeAuthResult value =
    let
        decoder =
            Decode.map2 (\success message -> { success = success, message = message })
                (Decode.field "success" Decode.bool)
                (Decode.field "message" Decode.string)
    in
    Decode.decodeValue decoder value


encodeCredentials : String -> String -> Encode.Value
encodeCredentials email password =
    Encode.object
        [ ( "email", Encode.string email )
        , ( "password", Encode.string password )
        ]


encodeGrade : Grade -> Encode.Value
encodeGrade grade =
    Encode.object
        [ ( "score", Encode.int grade.score )
        , ( "feedback", Encode.string grade.feedback )
        , ( "gradedBy", Encode.string grade.gradedBy )
        , ( "gradingDate", Encode.string grade.gradingDate )
        ]


encodeNewStudent : String -> Encode.Value
encodeNewStudent name =
    Encode.object
        [ ( "name", Encode.string name ) ]


encodeBelt : Belt -> Encode.Value
encodeBelt belt =
    Encode.object
        [ ( "id", Encode.string belt.id )
        , ( "name", Encode.string belt.name )
        , ( "color", Encode.string belt.color )
        , ( "order", Encode.int belt.order )
        , ( "gameOptions", Encode.list Encode.string belt.gameOptions )
        ]


encodeStudentUpdate : Student -> Encode.Value
encodeStudentUpdate student =
    Encode.object
        [ ( "id", Encode.string student.id )
        , ( "name", Encode.string student.name )
        ]


encodeAdminUserUpdate : AdminUser -> Encode.Value
encodeAdminUserUpdate adminUser =
    Encode.object
        [ ( "uid", Encode.string adminUser.uid )
        , ( "email", Encode.string adminUser.email )
        , ( "displayName", Encode.string adminUser.displayName )
        , ( "role", Encode.string adminUser.role )
        ]



-- HELPERS


formatDate : String -> String
formatDate dateString =
    -- Check if it's ISO format
    if String.contains "T" dateString then
        -- Extract just the date and time parts without milliseconds/timezone
        let
            dateParts =
                dateString
                    |> String.split "T"
                    |> List.take 2

            date =
                Maybe.withDefault "" (List.head dateParts)

            time =
                case List.drop 1 dateParts |> List.head of
                    Just timeStr ->
                        -- Take just HH:MM part of the time
                        String.split ":" timeStr
                            |> List.take 2
                            |> String.join ":"

                    Nothing ->
                        ""
        in
        date ++ " " ++ time

    else
        -- If not ISO format, return as is
        dateString


isSuperUser : Model -> Bool
isSuperUser model =
    case model.appState of
        Authenticated user ->
            user.role == "superuser"

        _ ->
            False


truncateGamesList : List String -> String
truncateGamesList games =
    let
        maxGamesToShow =
            3

        totalGames =
            List.length games

        displayGames =
            if totalGames <= maxGamesToShow then
                games

            else
                List.take maxGamesToShow games ++ [ "..." ++ String.fromInt (totalGames - maxGamesToShow) ++ " more" ]
    in
    String.join ", " displayGames


applyStudentFilters : Model -> List Student
applyStudentFilters model =
    model.students
        |> List.filter (filterStudentByText model.studentFilterText)
        |> sortStudents model.studentSortBy model.studentSortDirection


filterStudentByText : String -> Student -> Bool
filterStudentByText filterText student =
    if String.isEmpty filterText then
        True

    else
        let
            lowercaseFilter =
                String.toLower filterText

            containsFilter text =
                String.contains lowercaseFilter (String.toLower text)
        in
        containsFilter student.name || containsFilter student.id


sortStudents : StudentSortBy -> SortDirection -> List Student -> List Student
sortStudents sortBy direction students =
    let
        sortFunction =
            case sortBy of
                ByStudentName ->
                    \a b -> compare a.name b.name

                ByStudentCreated ->
                    \a b -> compare a.created b.created

                ByStudentLastActive ->
                    \a b -> compare a.lastActive b.lastActive

        sortedList =
            List.sortWith sortFunction students
    in
    case direction of
        Ascending ->
            sortedList

        Descending ->
            List.reverse sortedList


getStudentSortButtonClass : Model -> StudentSortBy -> String
getStudentSortButtonClass model sortType =
    let
        baseClass =
            "px-3 py-1 rounded text-sm"
    in
    if model.studentSortBy == sortType then
        baseClass ++ " bg-blue-100 text-blue-800 font-medium"

    else
        baseClass ++ " text-gray-600 hover:bg-gray-100"


getUserEmail : Model -> String
getUserEmail model =
    case model.appState of
        Authenticated user ->
            user.email

        _ ->
            "unknown@example.com"



--helper function to check name is correct format


isValidNameFormat : String -> Bool
isValidNameFormat name =
    let
        parts =
            String.split "." name
    in
    List.length parts
        == 2
        && List.all (\part -> String.length part > 0) parts



--helper to format the display name properly


formatDisplayName : String -> String
formatDisplayName name =
    let
        parts =
            String.split "." name

        firstName =
            List.head parts |> Maybe.withDefault ""

        lastName =
            List.drop 1 parts |> List.head |> Maybe.withDefault ""

        capitalizedFirst =
            String.toUpper (String.left 1 firstName) ++ String.dropLeft 1 firstName

        capitalizedLast =
            String.toUpper (String.left 1 lastName) ++ String.dropLeft 1 lastName
    in
    capitalizedFirst ++ " " ++ capitalizedLast



-- Helper function to capitalize words in a string


capitalizeWords : String -> String
capitalizeWords str =
    String.join " " (List.map capitalizeWord (String.split " " str))


capitalizeWord : String -> String
capitalizeWord word =
    case String.uncons word of
        Just ( firstChar, rest ) ->
            String.cons (Char.toUpper firstChar) rest

        Nothing ->
            ""


applyFilters : Model -> List Submission
applyFilters model =
    model.submissions
        |> List.filter (filterByText model.filterText)
        |> List.filter (filterByBelt model.filterBelt)
        |> List.filter (filterByGraded model.filterGraded)
        |> sortSubmissions model.sortBy model.sortDirection


filterByText : String -> Submission -> Bool
filterByText filterText submission =
    if String.isEmpty filterText then
        True

    else
        let
            lowercaseFilter =
                String.toLower filterText

            containsFilter text =
                String.contains lowercaseFilter (String.toLower text)
        in
        containsFilter submission.studentName
            || containsFilter submission.gameName
            || containsFilter submission.beltLevel


filterByBelt : Maybe String -> Submission -> Bool
filterByBelt maybeBelt submission =
    case maybeBelt of
        Just belt ->
            submission.beltLevel == belt

        Nothing ->
            True


filterByGraded : Maybe Bool -> Submission -> Bool
filterByGraded maybeGraded submission =
    case maybeGraded of
        Just isGraded ->
            case submission.grade of
                Just _ ->
                    isGraded

                Nothing ->
                    not isGraded

        Nothing ->
            True


sortSubmissions : SortBy -> SortDirection -> List Submission -> List Submission
sortSubmissions sortBy direction submissions =
    let
        sortFunction =
            case sortBy of
                ByName ->
                    \a b -> compare a.studentName b.studentName

                ByDate ->
                    \a b -> compare a.submissionDate b.submissionDate

                ByBelt ->
                    \a b -> compare a.beltLevel b.beltLevel

                ByGradeStatus ->
                    \a b ->
                        case ( a.grade, b.grade ) of
                            ( Just _, Nothing ) ->
                                LT

                            ( Nothing, Just _ ) ->
                                GT

                            _ ->
                                compare a.submissionDate b.submissionDate

        sortedList =
            List.sortWith sortFunction submissions
    in
    case direction of
        Ascending ->
            sortedList

        Descending ->
            List.reverse sortedList



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-gray-300 py-6 flex flex-col" ]
        [ div [ class "max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 w-full" ]
            [ -- h1 [ class "text-3xl font-bold text-gray-900 mb-8 text-center" ] [ text "Game Submission Admin" ]
              viewContent model
            ]
        ]


viewContent : Model -> Html Msg
viewContent model =
    case model.appState of
        NotAuthenticated ->
            viewLoginForm model

        AuthenticatingWith _ _ ->
            viewLoadingAuthentication

        Authenticated user ->
            div []
                [ div [ class "bg-white shadow rounded-lg mb-6 p-4 flex justify-between items-center" ]
                    [ div [ class "flex items-center" ]
                        [ div [ class "bg-blue-100 text-blue-800 p-2 rounded-full mr-3" ]
                            [ text (String.left 1 user.displayName |> String.toUpper) ]
                        , div []
                            [ p [ class "text-sm font-medium text-gray-900" ] [ text user.displayName ]
                            , p [ class "text-xs text-gray-500" ] [ text user.email ]
                            ]
                        ]
                    , div [ class "flex space-x-2" ]
                        [ if isSuperUser model then
                            button
                                [ onClick ShowAdminUsersPage
                                , class "px-3 py-1 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 focus:outline-none"
                                ]
                                [ text "Manage Admins" ]

                          else
                            text ""

                        -- Don't show button for regular admins
                        , button
                            [ onClick PerformSignOut
                            , class "px-3 py-1 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                            ]
                            [ text "Sign Out" ]
                        ]
                    ]
                , if model.loading then
                    div [ class "flex justify-center my-12" ]
                        [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" ] [] ]

                  else
                    div []
                        [ viewMessages model
                        , viewCurrentPage model
                        ]
                , case model.currentSubmission of
                    Just submission ->
                        viewSubmissionModal model submission

                    Nothing ->
                        text ""
                , case model.confirmDeleteSubmission of
                    Just submission ->
                        viewConfirmDeleteSubmissionModal submission

                    Nothing ->
                        text ""
                ]


viewCurrentPage : Model -> Html Msg
viewCurrentPage model =
    case model.page of
        SubmissionsPage ->
            div []
                [ viewFilters model
                , viewSubmissionList model
                ]

        StudentRecordPage student submissions ->
            viewStudentRecordPage model student submissions

        CreateStudentPage ->
            viewCreateStudentPage model

        BeltManagementPage ->
            viewBeltManagementPage model

        AdminUsersPage ->
            viewAdminUsersPage model


viewAdminUsersPage : Model -> Html Msg
viewAdminUsersPage model =
    div [ class "space-y-6" ]
        [ div [ class "bg-white shadow rounded-lg p-6" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-900" ]
                    [ text "Admin User Management" ]
                , button
                    [ onClick ReturnToSubmissionsPage
                    , class "text-gray-500 hover:text-gray-700 flex items-center"
                    ]
                    [ span [ class "mr-1" ] [ text "←" ]
                    , text "Back to Submissions"
                    ]
                ]
            ]
        , div [ class "bg-white shadow rounded-lg p-6" ]
            [ viewAdminUserCreationResult model.adminUserCreationResult
            , viewAdminUserUpdateResult model.adminUserUpdateResult
            , viewAdminUserDeletionResult model.adminUserDeletionResult
            , if model.showAdminUserForm then
                viewAdminUserForm model.adminUserForm

              else
                div [ class "text-center py-8" ]
                    [ p [ class "text-gray-500 mb-4" ]
                        [ text "Create additional admin users who will have access to this admin dashboard." ]
                    , button
                        [ onClick ShowAdminUserForm
                        , class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                        ]
                        [ text "Create New Admin User" ]
                    ]
            ]
        , viewAdminUsersList model
        , viewAdminUserEditModal model
        , viewConfirmDeleteAdminModal model
        , div [ class "bg-yellow-50 shadow rounded-lg p-6 border-l-4 border-yellow-400" ]
            [ h3 [ class "text-lg font-medium text-yellow-800 mb-2" ] [ text "Security Information" ]
            , p [ class "text-yellow-700 mb-2" ]
                [ text "All admin users have full access to the system. Only create accounts for trusted instructors who need to manage student submissions and belt progression." ]
            , p [ class "text-yellow-700" ]
                [ text "Admin users will be able to:" ]
            , ul [ class "list-disc list-inside text-yellow-700 mt-2 ml-4 space-y-1" ]
                [ li [] [ text "Grade student submissions" ]
                , li [] [ text "Manage belt progression levels" ]
                , li [] [ text "Create and manage student accounts" ]
                , li [] [ text "Create other admin users" ]
                ]
            ]
        ]


viewAdminUserDeletionResult : Maybe String -> Html Msg
viewAdminUserDeletionResult maybeResult =
    case maybeResult of
        Just result ->
            if String.startsWith "Success" result then
                div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ]
                    [ p [ class "text-sm text-green-700" ] [ text result ] ]

            else
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                    [ p [ class "text-sm text-red-700" ] [ text result ] ]

        Nothing ->
            text ""


viewAdminUserUpdateResult : Maybe String -> Html Msg
viewAdminUserUpdateResult maybeResult =
    case maybeResult of
        Just result ->
            if String.startsWith "Success" result then
                div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ]
                    [ p [ class "text-sm text-green-700" ] [ text result ] ]

            else
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                    [ p [ class "text-sm text-red-700" ] [ text result ] ]

        Nothing ->
            text ""


viewAdminUserForm : AdminUserForm -> Html Msg
viewAdminUserForm form =
    div [ class "bg-white rounded-lg border border-gray-200 overflow-hidden" ]
        [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Create New Admin User" ] ]
        , div [ class "p-6" ]
            [ case form.formError of
                Just error ->
                    div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                        [ p [ class "text-sm text-red-700" ] [ text error ] ]

                Nothing ->
                    text ""
            , div [ class "space-y-4" ]
                [ div []
                    [ label [ for "adminEmail", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Email Address" ]
                    , input
                        [ type_ "email"
                        , id "adminEmail"
                        , placeholder "admin@example.com"
                        , value form.email
                        , onInput UpdateAdminUserEmail
                        , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        []
                    ]
                , div []
                    [ label [ for "adminDisplayName", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Display Name (optional)" ]
                    , input
                        [ type_ "text"
                        , id "adminDisplayName"
                        , placeholder "Admin User"
                        , value form.displayName
                        , onInput UpdateAdminUserDisplayName
                        , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        []
                    ]
                , div []
                    [ label [ for "adminPassword", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Password" ]
                    , input
                        [ type_ "password"
                        , id "adminPassword"
                        , placeholder "••••••••"
                        , value form.password
                        , onInput UpdateAdminUserPassword
                        , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        []
                    , p [ class "mt-1 text-xs text-gray-500" ] [ text "Password must be at least 6 characters" ]
                    ]
                , div []
                    [ label [ for "adminConfirmPassword", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Confirm Password" ]
                    , input
                        [ type_ "password"
                        , id "adminConfirmPassword"
                        , placeholder "••••••••"
                        , value form.confirmPassword
                        , onInput UpdateAdminUserConfirmPassword
                        , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        []
                    ]

                -- Add role selection dropdown
                , div []
                    [ label [ for "adminRole", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Role:" ]
                    , select
                        [ id "adminRole"
                        , value form.role
                        , onInput UpdateAdminUserRole
                        , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        [ option [ value "admin" ] [ text "Regular Admin" ]
                        , option [ value "superuser" ] [ text "Superuser" ]
                        ]
                    , p [ class "mt-1 text-xs text-gray-500" ]
                        [ text "Superusers can manage other admin accounts." ]
                    ]
                ]
            , div [ class "mt-6 flex justify-end space-x-3" ]
                [ button
                    [ onClick HideAdminUserForm
                    , class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                    ]
                    [ text "Cancel" ]
                , button
                    [ onClick SubmitAdminUserForm
                    , class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none"
                    ]
                    [ text "Create Admin User" ]
                ]
            ]
        ]


viewAdminUsersList : Model -> Html Msg
viewAdminUsersList model =
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ div [ class "flex justify-between items-center mb-4" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Current Admin Users" ]
            , button
                [ onClick RequestAllAdmins
                , class "px-3 py-1 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                ]
                [ text "Refresh" ]
            ]
        , if model.loading then
            div [ class "flex justify-center my-6" ]
                [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" ] [] ]

          else if List.isEmpty model.adminUsers then
            div [ class "text-center py-12 bg-gray-50 rounded-lg" ]
                [ p [ class "text-gray-500" ] [ text "No admin users found. The first admin user may have been created through Firebase directly." ] ]

          else
            div [ class "overflow-x-auto bg-white" ]
                [ table [ class "min-w-full divide-y divide-gray-200" ]
                    [ thead [ class "bg-gray-50" ]
                        [ tr []
                            [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Email" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Display Name" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-20" ] [ text "Role" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Created By" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Created At" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-32" ] [ text "Actions" ]
                            ]
                        ]
                    , tbody [ class "bg-white divide-y divide-gray-200" ]
                        (List.map viewAdminUserRow model.adminUsers)
                    ]
                ]
        ]


viewAdminUserRow : AdminUser -> Html Msg
viewAdminUserRow admin =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm font-medium text-gray-900 truncate max-w-xs" ] [ text admin.email ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500 truncate max-w-xs" ] [ text admin.displayName ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ viewRoleBadge admin.role ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500 truncate max-w-xs" ] [ text (Maybe.withDefault "Unknown" admin.createdBy) ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500" ]
                [ text (formatDate (Maybe.withDefault "Unknown" admin.createdAt)) ]
            ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium" ]
            [ div [ class "flex space-x-2" ]
                [ button
                    [ onClick (EditAdminUser admin)
                    , class "flex-1 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center"
                    ]
                    [ text "Edit" ]
                , button
                    [ onClick (DeleteAdminUser admin)
                    , class "flex-1 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center"
                    ]
                    [ text "Delete" ]
                ]
            ]
        ]


viewRoleBadge : String -> Html Msg
viewRoleBadge role =
    let
        ( bgColor, textColor ) =
            if role == "superuser" then
                ( "bg-purple-100", "text-purple-800" )

            else
                ( "bg-blue-100", "text-blue-800" )
    in
    span [ class ("inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium " ++ bgColor ++ " " ++ textColor) ]
        [ text role ]


viewAdminUserCreationResult : Maybe String -> Html Msg
viewAdminUserCreationResult maybeResult =
    case maybeResult of
        Just result ->
            if String.startsWith "Success" result then
                div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ]
                    [ p [ class "text-sm text-green-700" ] [ text result ] ]

            else
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                    [ p [ class "text-sm text-red-700" ] [ text result ] ]

        Nothing ->
            text ""


viewAdminUserEditModal : Model -> Html Msg
viewAdminUserEditModal model =
    case model.editingAdminUser of
        Just adminUser ->
            div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
                [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                    [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
                        [ h2 [ class "text-lg font-medium text-gray-900" ]
                            [ text ("Edit Admin User: " ++ adminUser.email) ]
                        ]
                    , div [ class "p-6" ]
                        [ div [ class "space-y-4" ]
                            [ div []
                                [ label [ for "adminEmail", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Email Address" ]
                                , input
                                    [ type_ "email"
                                    , id "adminEmail"
                                    , placeholder "admin@example.com"
                                    , value adminUser.email
                                    , onInput UpdateEditingAdminUserEmail
                                    , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                    ]
                                    []
                                ]
                            , div []
                                [ label [ for "adminDisplayName", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Display Name" ]
                                , input
                                    [ type_ "text"
                                    , id "adminDisplayName"
                                    , placeholder "Admin User"
                                    , value adminUser.displayName
                                    , onInput UpdateEditingAdminUserDisplayName
                                    , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                    ]
                                    []
                                ]

                            -- Role dropdown with enhanced styling and current role display
                            , div []
                                [ label [ for "editAdminRole", class "block text-sm font-medium text-gray-700 mb-1" ]
                                    [ text "Role:" ]
                                , div [ class "mb-2 text-xs text-gray-500" ]
                                    [ text ("Current role: " ++ adminUser.role) ]
                                , select
                                    [ id "editAdminRole"
                                    , value adminUser.role
                                    , onInput UpdateEditingAdminUserRole
                                    , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                    ]
                                    [ option [ value "admin" ] [ text "Regular Admin" ]
                                    , option [ value "superuser" ] [ text "Superuser" ]
                                    ]
                                , p [ class "mt-1 text-xs text-gray-500" ]
                                    [ text "Only superusers can manage other admin accounts" ]
                                ]
                            , div [ class "pt-2 flex justify-end space-x-3" ]
                                [ button
                                    [ onClick CancelAdminUserEdit
                                    , class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                                    ]
                                    [ text "Cancel" ]
                                , button
                                    [ onClick SaveAdminUserEdit
                                    , class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none"
                                    ]
                                    [ text "Save Changes" ]
                                ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""


viewConfirmDeleteAdminModal : Model -> Html Msg
viewConfirmDeleteAdminModal model =
    case model.confirmDeleteAdmin of
        Just adminUser ->
            div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
                [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                    [ div [ class "px-6 py-4 bg-red-50 border-b border-gray-200" ]
                        [ h2 [ class "text-lg font-medium text-red-700" ] [ text "Confirm Delete" ] ]
                    , div [ class "p-6" ]
                        [ p [ class "mb-4 text-gray-700" ]
                            [ text ("Are you sure you want to delete the admin user " ++ adminUser.email ++ "?") ]
                        , p [ class "mb-6 text-red-600 font-medium" ]
                            [ text "This action cannot be undone and will revoke this user's access to the admin panel." ]
                        , div [ class "flex justify-end space-x-3" ]
                            [ button
                                [ onClick CancelDeleteAdminUser
                                , class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                                ]
                                [ text "Cancel" ]
                            , button
                                [ onClick (ConfirmDeleteAdminUser adminUser)
                                , class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none"
                                ]
                                [ text "Delete Admin User" ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""


viewLoginForm : Model -> Html Msg
viewLoginForm model =
    div [ class "bg-white shadow rounded-lg max-w-md mx-auto p-6" ]
        [ h2 [ class "text-xl font-medium text-gray-900 mb-6 text-center" ] [ text "Sign in to Admin Panel" ]
        , case model.authError of
            Just errorMsg ->
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                    [ p [ class "text-sm text-red-700" ] [ text errorMsg ] ]

            Nothing ->
                text ""
        , div [ class "space-y-4" ]
            [ div []
                [ label [ for "email", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Email Address" ]
                , input
                    [ type_ "email"
                    , id "email"
                    , placeholder "admin@example.com"
                    , value model.loginEmail
                    , onInput UpdateLoginEmail
                    , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    []
                ]
            , div []
                [ label [ for "password", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Password" ]
                , input
                    [ type_ "password"
                    , id "password"
                    , placeholder "••••••••"
                    , value model.loginPassword
                    , onInput UpdateLoginPassword
                    , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    []
                ]
            , div [ class "pt-2" ]
                [ button
                    [ onClick SubmitLogin
                    , class "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    ]
                    [ text "Sign In" ]
                ]
            , div [ class "text-center mt-4" ]
                [ p [ class "text-xs text-gray-500" ]
                    [ text "This admin panel requires authentication. Please contact your administrator if you need access." ]
                ]
            , div [ class "text-center mt-2" ]
                [ button
                    [ onClick ShowPasswordReset
                    , class "text-sm text-blue-600 hover:text-blue-800"
                    ]
                    [ text "Forgot Password?" ]
                ]
            ]

        -- Password Reset Modal
        , if model.showPasswordReset then
            div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
                [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                    [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
                        [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Reset Password" ] ]
                    , div [ class "p-6" ]
                        [ p [ class "mb-4 text-sm text-gray-600" ]
                            [ text "Enter your email address and we'll send you a password reset link." ]
                        , case model.passwordResetMessage of
                            Just message ->
                                if String.startsWith "Error" message then
                                    div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                                        [ p [ class "text-sm text-red-700" ] [ text message ] ]

                                else
                                    div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ]
                                        [ p [ class "text-sm text-green-700" ] [ text message ] ]

                            Nothing ->
                                text ""
                        , div [ class "mb-4" ]
                            [ label [ for "resetEmail", class "block text-sm font-medium text-gray-700 mb-1" ]
                                [ text "Email Address" ]
                            , input
                                [ type_ "email"
                                , id "resetEmail"
                                , value model.passwordResetEmail
                                , onInput UpdatePasswordResetEmail
                                , placeholder "admin@example.com"
                                , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                ]
                                []
                            ]
                        , div [ class "flex justify-end space-x-3" ]
                            [ button
                                [ onClick HidePasswordReset
                                , class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                                ]
                                [ text "Cancel" ]
                            , button
                                [ onClick SubmitPasswordReset
                                , class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none"
                                ]
                                [ text "Send Reset Link" ]
                            ]
                        ]
                    ]
                ]

          else
            text ""
        ]


viewLoadingAuthentication : Html Msg
viewLoadingAuthentication =
    div [ class "bg-white shadow rounded-lg max-w-md mx-auto p-6 text-center" ]
        [ div [ class "flex justify-center my-6" ]
            [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" ] [] ]
        , p [ class "text-gray-600" ] [ text "Signing you in..." ]
        ]


viewMessages : Model -> Html Msg
viewMessages model =
    div []
        [ case model.error of
            Just errorMsg ->
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                    [ p [ class "text-sm text-red-700" ] [ text errorMsg ] ]

            Nothing ->
                text ""
        , case model.success of
            Just successMsg ->
                div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ]
                    [ p [ class "text-sm text-green-700" ] [ text successMsg ] ]

            Nothing ->
                text ""
        ]


viewFilters : Model -> Html Msg
viewFilters model =
    div [ class "bg-white shadow rounded-lg mb-6 p-4" ]
        [ div [ class "flex items-center justify-between mb-4" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Game Submissions" ]
            , div [ class "flex space-x-2" ]
                [ button
                    [ onClick ShowCreateStudentForm
                    , class "ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    ]
                    [ text "Manage Students" ]
                , button
                    [ onClick ShowBeltManagement
                    , class "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    ]
                    [ text "Manage Belts" ]
                ]
            ]
        , div [ class "flex flex-col md:flex-row md:items-center md:justify-between mb-4 gap-4" ]
            [ div [ class "flex-1" ]
                [ label [ for "filterText", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Search" ]
                , input
                    [ type_ "text"
                    , id "filterText"
                    , placeholder "Search by name or game"
                    , value model.filterText
                    , onInput UpdateFilterText
                    , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    []
                ]
            , div [ class "w-full md:w-auto flex flex-col md:flex-row gap-4" ]
                [ div [ class "flex-1 md:w-40" ]
                    [ label [ for "filterBelt", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Belt" ]
                    , select
                        [ id "filterBelt"
                        , onInput UpdateFilterBelt
                        , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        ([ option [ value "all" ] [ text "All Belts" ] ]
                            ++ List.map (\belt -> option [ value belt.name ] [ text belt.name ]) model.belts
                        )
                    ]
                , div [ class "flex-1 md:w-40" ]
                    [ label [ for "filterGraded", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Status" ]
                    , select
                        [ id "filterGraded"
                        , onInput UpdateFilterGraded
                        , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        [ option [ value "all" ] [ text "All Status" ]
                        , option [ value "graded" ] [ text "Graded" ]
                        , option [ value "ungraded" ] [ text "Ungraded" ]
                        ]
                    ]
                ]
            ]
        , div [ class "flex flex-col sm:flex-row justify-between items-center" ]
            [ div [ class "flex items-center gap-2 mb-2 sm:mb-0" ]
                [ span [ class "text-sm text-gray-500" ] [ text "Sort by:" ]
                , button
                    [ onClick (UpdateSortBy ByName)
                    , class (getSortButtonClass model ByName)
                    ]
                    [ text "Name" ]
                , button
                    [ onClick (UpdateSortBy ByDate)
                    , class (getSortButtonClass model ByDate)
                    ]
                    [ text "Date" ]
                , button
                    [ onClick (UpdateSortBy ByBelt)
                    , class (getSortButtonClass model ByBelt)
                    ]
                    [ text "Belt" ]
                , button
                    [ onClick (UpdateSortBy ByGradeStatus)
                    , class (getSortButtonClass model ByGradeStatus)
                    ]
                    [ text "Grade Status" ]
                , button
                    [ onClick ToggleSortDirection
                    , class "ml-2 px-2 py-1 rounded text-gray-600 hover:bg-gray-100"
                    ]
                    [ text
                        (if model.sortDirection == Ascending then
                            "↑"

                         else
                            "↓"
                        )
                    ]
                ]
            , div [ class "flex items-center" ]
                [ button
                    [ onClick RefreshSubmissions
                    , class "flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                    ]
                    [ text "Refresh" ]
                , span [ class "ml-4 text-sm text-gray-500" ]
                    [ text ("Total: " ++ String.fromInt (List.length (applyFilters model)) ++ " submissions") ]
                ]
            ]
        ]


getSortButtonClass : Model -> SortBy -> String
getSortButtonClass model sortType =
    let
        baseClass =
            "px-3 py-1 rounded text-sm"
    in
    if model.sortBy == sortType then
        baseClass ++ " bg-blue-100 text-blue-800 font-medium"

    else
        baseClass ++ " text-gray-600 hover:bg-gray-100"


viewSubmissionList : Model -> Html Msg
viewSubmissionList model =
    let
        filteredSubmissions =
            applyFilters model
    in
    if List.isEmpty filteredSubmissions then
        div [ class "text-center py-12 bg-white rounded-lg shadow" ]
            [ p [ class "text-gray-500" ] [ text "No submissions found matching your filters." ] ]

    else
        div [ class "overflow-x-auto bg-white shadow rounded-lg" ]
            [ table [ class "min-w-full divide-y divide-gray-200" ]
                [ thead [ class "bg-gray-50" ]
                    [ tr []
                        [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Student" ]
                        , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Game" ]
                        , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Belt" ]
                        , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Submitted" ]
                        , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Grade" ]
                        , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Actions" ]
                        ]
                    ]
                , tbody [ class "bg-white divide-y divide-gray-200" ]
                    (List.map viewSubmissionRow filteredSubmissions)
                ]
            ]


viewSubmissionRow : Submission -> Html Msg
viewSubmissionRow submission =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm font-medium text-gray-900" ] [ text (formatDisplayName submission.studentName) ]
            , div [ class "text-xs text-gray-500" ] [ text ("ID: " ++ submission.studentId) ]
            ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-900" ] [ text submission.gameName ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-900" ] [ text submission.beltLevel ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500" ] [ text submission.submissionDate ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ viewGradeBadge submission.grade ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-2" ]
            [ button
                [ onClick (SelectSubmission submission)
                , class "w-24 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center"
                ]
                [ text
                    (if submission.grade == Nothing then
                        "Grade"

                     else
                        "View/Edit"
                    )
                ]
            , button
                [ onClick (ViewStudentRecord submission.studentId)
                , class "w-24 px-2 py-1 bg-green-100 text-green-700 rounded hover:bg-green-200 transition text-center"
                ]
                [ text "Student" ]
            , button
                [ onClick (DeleteSubmission submission)
                , class "w-24 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center"
                ]
                [ text "Delete" ]
            ]
        ]


viewGradeBadge : Maybe Grade -> Html Msg
viewGradeBadge maybeGrade =
    case maybeGrade of
        Just grade ->
            let
                ( bgColor, textColor ) =
                    if grade.score >= 90 then
                        ( "bg-green-100", "text-green-800" )

                    else if grade.score >= 70 then
                        ( "bg-blue-100", "text-blue-800" )

                    else if grade.score >= 60 then
                        ( "bg-yellow-100", "text-yellow-800" )

                    else
                        ( "bg-red-100", "text-red-800" )
            in
            span [ class ("inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium " ++ bgColor ++ " " ++ textColor) ]
                [ text (String.fromInt grade.score ++ "/100") ]

        Nothing ->
            span [ class "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800" ]
                [ text "Ungraded" ]


viewConfirmDeleteSubmissionModal : Submission -> Html Msg
viewConfirmDeleteSubmissionModal submission =
    div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
        [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
            [ div [ class "px-6 py-4 bg-red-50 border-b border-gray-200" ]
                [ h2 [ class "text-lg font-medium text-red-700" ] [ text "Confirm Delete" ] ]
            , div [ class "p-6" ]
                [ p [ class "mb-6 text-gray-700" ]
                    [ text ("Are you sure you want to delete the submission for " ++ formatDisplayName submission.studentName ++ "'s " ++ submission.gameName ++ "? This action cannot be undone.") ]
                , div [ class "flex justify-end space-x-3" ]
                    [ button
                        [ onClick CancelDeleteSubmission
                        , class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                        ]
                        [ text "Cancel" ]
                    , button
                        [ onClick (ConfirmDeleteSubmission submission)
                        , class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none"
                        ]
                        [ text "Delete Submission" ]
                    ]
                ]
            ]
        ]


viewStudentRecordPage : Model -> Student -> List Submission -> Html Msg
viewStudentRecordPage model student submissions =
    div [ class "space-y-6" ]
        [ div [ class "bg-white shadow rounded-lg p-6" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-900" ]
                    [ text ("Student Record: " ++ formatDisplayName student.name) ]
                , button
                    [ onClick CloseStudentRecord
                    , class "text-gray-500 hover:text-gray-700 flex items-center"
                    ]
                    [ span [ class "mr-1" ] [ text "←" ]
                    , text "Back to Submissions"
                    ]
                ]
            , div [ class "mt-4 grid grid-cols-1 md:grid-cols-3 gap-4" ]
                [ div [ class "bg-gray-50 p-4 rounded-md" ]
                    [ h3 [ class "text-sm font-medium text-gray-700" ] [ text "Student ID" ]
                    , p [ class "mt-1 text-lg" ] [ text student.id ]
                    ]
                , div [ class "bg-gray-50 p-4 rounded-md" ]
                    [ h3 [ class "text-sm font-medium text-gray-700" ] [ text "Joined" ]
                    , p [ class "mt-1 text-lg" ] [ text student.created ]
                    ]
                , div [ class "bg-gray-50 p-4 rounded-md" ]
                    [ h3 [ class "text-sm font-medium text-gray-700" ] [ text "Last Active" ]
                    , p [ class "mt-1 text-lg" ] [ text student.lastActive ]
                    ]
                ]
            ]
        , div [ class "bg-white shadow rounded-lg overflow-hidden" ]
            [ div [ class "px-6 py-4 border-b border-gray-200" ]
                [ h3 [ class "text-lg font-medium text-gray-900" ]
                    [ text ("All Submissions (" ++ String.fromInt (List.length submissions) ++ ")") ]
                ]
            , if List.isEmpty submissions then
                div [ class "p-6 text-center" ]
                    [ p [ class "text-gray-500" ] [ text "No submissions found for this student." ] ]

              else
                div [ class "overflow-x-auto" ]
                    [ table [ class "min-w-full divide-y divide-gray-200" ]
                        [ thead [ class "bg-gray-50" ]
                            [ tr []
                                [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Game" ]
                                , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Belt" ]
                                , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Submitted" ]
                                , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Grade" ]
                                , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Actions" ]
                                ]
                            ]
                        , tbody [ class "bg-white divide-y divide-gray-200" ]
                            (List.map viewStudentSubmissionRow submissions)
                        ]
                    ]
            ]
        ]


viewStudentSubmissionRow : Submission -> Html Msg
viewStudentSubmissionRow submission =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm font-medium text-gray-900" ] [ text submission.gameName ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-900" ] [ text submission.beltLevel ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500" ] [ text submission.submissionDate ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ viewGradeBadge submission.grade ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-2" ]
            [ button
                [ onClick (SelectSubmission submission)
                , class "w-24 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center"
                ]
                [ text
                    (if submission.grade == Nothing then
                        "Grade"

                     else
                        "View/Edit"
                    )
                ]
            , button
                [ onClick (DeleteSubmission submission)
                , class "w-24 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center"
                ]
                [ text "Delete" ]
            ]
        ]


viewCreateStudentPage : Model -> Html Msg
viewCreateStudentPage model =
    div [ class "space-y-6" ]
        [ div [ class "bg-white shadow rounded-lg p-6" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-900" ]
                    [ text "Student Management" ]
                , button
                    [ onClick CloseCreateStudentForm
                    , class "text-gray-500 hover:text-gray-700 flex items-center"
                    ]
                    [ span [ class "mr-1" ] [ text "←" ]
                    , text "Back to Submissions"
                    ]
                ]
            , div [ class "mt-6 space-y-6" ]
                [ div [ class "space-y-2" ]
                    [ h3 [ class "text-lg font-medium text-gray-900 mb-3" ] [ text "Create New Student" ]
                    , label [ for "studentName", class "block text-sm font-medium text-gray-700" ] [ text "Student Name:" ]
                    , input
                        [ type_ "text"
                        , id "studentName"
                        , value model.newStudentName
                        , onInput UpdateNewStudentName
                        , placeholder "firstname.lastname (e.g., tyler.smith)"
                        , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        []
                    , p [ class "text-sm text-gray-500 mt-1" ]
                        [ text "Name must be in format: firstname.lastname" ]
                    ]
                , div [ class "mt-6" ]
                    [ button
                        [ onClick CreateNewStudent
                        , class "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                        ]
                        [ text "Create Student Record" ]
                    ]
                ]
            ]

        -- Student listing section
        , div [ class "bg-white shadow rounded-lg p-6 mt-6" ]
            [ h3 [ class "text-lg font-medium text-gray-900 mb-4" ] [ text "Student Directory" ]
            , div [ class "mb-4" ]
                [ div [ class "flex items-center justify-between mb-4" ]
                    [ div [ class "flex-1 max-w-md" ]
                        [ label [ for "studentFilterText", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Search Students" ]
                        , input
                            [ type_ "text"
                            , id "studentFilterText"
                            , placeholder "Search by name or ID"
                            , value model.studentFilterText
                            , onInput UpdateStudentFilterText
                            , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                            ]
                            []
                        ]
                    , div [ class "flex items-center ml-4 self-end" ]
                        [ button
                            [ onClick RequestAllStudents
                            , class "flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                            ]
                            [ text "Refresh" ]
                        ]
                    ]
                , div [ class "flex items-center mt-2" ]
                    [ span [ class "text-sm text-gray-500 mr-2" ] [ text "Sort by:" ]
                    , button
                        [ onClick (UpdateStudentSortBy ByStudentName)
                        , class (getStudentSortButtonClass model ByStudentName)
                        ]
                        [ text "Name" ]
                    , button
                        [ onClick (UpdateStudentSortBy ByStudentCreated)
                        , class (getStudentSortButtonClass model ByStudentCreated)
                        ]
                        [ text "Created" ]
                    , button
                        [ onClick (UpdateStudentSortBy ByStudentLastActive)
                        , class (getStudentSortButtonClass model ByStudentLastActive)
                        ]
                        [ text "Last Active" ]
                    , button
                        [ onClick ToggleStudentSortDirection
                        , class "ml-2 px-2 py-1 rounded text-gray-600 hover:bg-gray-100"
                        ]
                        [ text
                            (if model.studentSortDirection == Ascending then
                                "↑"

                             else
                                "↓"
                            )
                        ]
                    , span [ class "ml-4 text-sm text-gray-500" ]
                        [ text ("Total: " ++ String.fromInt (List.length (applyStudentFilters model)) ++ " students") ]
                    ]
                ]
            , if model.loading then
                div [ class "flex justify-center my-12" ]
                    [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" ] [] ]

              else if List.isEmpty (applyStudentFilters model) then
                div [ class "text-center py-12 bg-gray-50 rounded-lg" ]
                    [ p [ class "text-gray-500" ] [ text "No students found matching your filters." ] ]

              else
                div [ class "overflow-x-auto bg-white" ]
                    [ table [ class "min-w-full divide-y divide-gray-200" ]
                        [ thead [ class "bg-gray-50" ]
                            [ tr []
                                [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Name" ]
                                , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Student ID" ]
                                , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Created" ]
                                , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Last Active" ]
                                , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Actions" ]
                                ]
                            ]
                        , tbody [ class "bg-white divide-y divide-gray-200" ]
                            (List.map viewStudentRow (applyStudentFilters model))
                        ]
                    ]
            ]

        -- Student edit modal
        , case model.editingStudent of
            Just student ->
                viewEditStudentModal model student

            Nothing ->
                text ""

        -- Confirm delete modal
        , case model.confirmDeleteStudent of
            Just student ->
                viewConfirmDeleteModal student

            Nothing ->
                text ""
        ]


viewStudentRow : Student -> Html Msg
viewStudentRow student =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm font-medium text-gray-900" ] [ text (formatDisplayName student.name) ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500" ] [ text student.id ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500" ] [ text student.created ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500" ] [ text student.lastActive ] ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-2" ]
            [ button
                [ onClick (ViewStudentRecord student.id)
                , class "w-29 px-2 py-1 bg-green-100 text-green-700 rounded hover:bg-green-200 transition text-center"
                ]
                [ text "View Records" ]
            , button
                [ onClick (EditStudent student)
                , class "w-24 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center"
                ]
                [ text "Edit" ]
            , button
                [ onClick (DeleteStudent student)
                , class "w-24 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center"
                ]
                [ text "Delete" ]
            ]
        ]


viewEditStudentModal : Model -> Student -> Html Msg
viewEditStudentModal model student =
    div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
        [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
            [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
                [ h2 [ class "text-lg font-medium text-gray-900" ] [ text "Edit Student" ] ]
            , div [ class "p-6" ]
                [ div [ class "space-y-4" ]
                    [ div []
                        [ label [ for "editStudentName", class "block text-sm font-medium text-gray-700" ] [ text "Student Name:" ]
                        , input
                            [ type_ "text"
                            , id "editStudentName"
                            , value student.name
                            , onInput UpdateEditingStudentName
                            , placeholder "firstname.lastname"
                            , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                            ]
                            []
                        , p [ class "text-sm text-gray-500 mt-1" ]
                            [ text "Name must be in format: firstname.lastname" ]
                        ]
                    , div [ class "pt-2 flex justify-end space-x-3" ]
                        [ button
                            [ onClick CancelStudentEdit
                            , class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                            ]
                            [ text "Cancel" ]
                        , button
                            [ onClick SaveStudentEdit
                            , class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none"
                            ]
                            [ text "Save Changes" ]
                        ]
                    ]
                ]
            ]
        ]


viewConfirmDeleteModal : Student -> Html Msg
viewConfirmDeleteModal student =
    div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
        [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
            [ div [ class "px-6 py-4 bg-red-50 border-b border-gray-200" ]
                [ h2 [ class "text-lg font-medium text-red-700" ] [ text "Confirm Delete" ] ]
            , div [ class "p-6" ]
                [ p [ class "mb-4 text-gray-700" ]
                    [ text ("Are you sure you want to delete the student record for " ++ formatDisplayName student.name ++ "?") ]
                , p [ class "mb-6 text-red-600 font-medium" ]
                    [ text "This will permanently delete the student AND all their game submissions. This action cannot be undone." ]
                , div [ class "flex justify-end space-x-3" ]
                    [ button
                        [ onClick CancelDeleteStudent
                        , class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                        ]
                        [ text "Cancel" ]
                    , button
                        [ onClick (ConfirmDeleteStudent student)
                        , class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none"
                        ]
                        [ text "Delete Student & Submissions" ]
                    ]
                ]
            ]
        ]


viewBeltManagementPage : Model -> Html Msg
viewBeltManagementPage model =
    div [ class "space-y-6" ]
        [ div [ class "bg-white shadow rounded-lg p-6" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-900" ]
                    [ text "Belt Management" ]
                , button
                    [ onClick CloseBeltManagement
                    , class "text-gray-500 hover:text-gray-700 flex items-center"
                    ]
                    [ span [ class "mr-1" ] [ text "←" ]
                    , text "Back to Submissions"
                    ]
                ]
            , div [ class "mt-6" ]
                [ div [ class "bg-white overflow-hidden shadow-sm rounded-lg border border-gray-200" ]
                    [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
                        [ h3 [ class "text-lg font-medium text-gray-900" ]
                            [ text
                                (case model.editingBelt of
                                    Just belt ->
                                        "Edit Belt: " ++ belt.name

                                    Nothing ->
                                        "Add New Belt"
                                )
                            ]
                        ]
                    , div [ class "p-6" ]
                        [ div [ class "grid grid-cols-1 md:grid-cols-2 gap-4" ]
                            [ div [ class "space-y-2" ]
                                [ label [ for "beltName", class "block text-sm font-medium text-gray-700" ] [ text "Belt Name:" ]
                                , input
                                    [ type_ "text"
                                    , id "beltName"
                                    , value model.newBeltName
                                    , onInput UpdateNewBeltName
                                    , placeholder "e.g. White Belt, Yellow Belt"
                                    , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                    ]
                                    []
                                ]
                            , div [ class "space-y-2" ]
                                [ label [ for "beltColor", class "block text-sm font-medium text-gray-700" ] [ text "Belt Color:" ]
                                , div [ class "flex items-center space-x-2" ]
                                    [ input
                                        [ type_ "color"
                                        , id "beltColor"
                                        , value model.newBeltColor
                                        , onInput UpdateNewBeltColor
                                        , class "h-8 w-8 border border-gray-300 rounded"
                                        ]
                                        []
                                    , input
                                        [ type_ "text"
                                        , value model.newBeltColor
                                        , onInput UpdateNewBeltColor
                                        , placeholder "#000000"
                                        , class "flex-1 mt-1 border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                        ]
                                        []
                                    ]
                                ]
                            , div [ class "space-y-2" ]
                                [ label [ for "beltOrder", class "block text-sm font-medium text-gray-700" ] [ text "Display Order:" ]
                                , input
                                    [ type_ "number"
                                    , id "beltOrder"
                                    , value model.newBeltOrder
                                    , onInput UpdateNewBeltOrder
                                    , placeholder "1, 2, 3, etc."
                                    , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                    ]
                                    []
                                ]
                            , div [ class "space-y-2" ]
                                [ label [ for "gameOptions", class "block text-sm font-medium text-gray-700" ] [ text "Game Options (comma separated):" ]
                                , textarea
                                    [ id "gameOptions"
                                    , value model.newBeltGameOptions
                                    , onInput UpdateNewBeltGameOptions
                                    , placeholder "Game 1, Game 2, Game 3"
                                    , rows 3
                                    , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                    ]
                                    []
                                ]
                            ]
                        , div [ class "mt-6 flex space-x-3" ]
                            [ case model.editingBelt of
                                Just belt ->
                                    div [ class "flex space-x-3 w-full" ]
                                        [ button
                                            [ onClick UpdateBelt
                                            , class "flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                                            ]
                                            [ text "Update Belt" ]
                                        , button
                                            [ onClick CancelEditBelt
                                            , class "py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                                            ]
                                            [ text "Cancel" ]
                                        ]

                                Nothing ->
                                    button
                                        [ onClick AddNewBelt
                                        , class "w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                                        ]
                                        [ text "Add Belt" ]
                            ]
                        ]
                    ]
                ]
            , div [ class "mt-8" ]
                [ div [ class "flex justify-between items-center mb-4" ]
                    [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Current Belts" ]
                    , button
                        [ onClick RefreshBelts
                        , class "py-1 px-3 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                        ]
                        [ text "Refresh" ]
                    ]
                , if List.isEmpty model.belts then
                    div [ class "text-center py-12 bg-gray-50 rounded-lg border border-gray-200" ]
                        [ p [ class "text-gray-500" ] [ text "No belts configured yet. Add your first belt above." ] ]

                  else
                    div [ class "bg-white shadow overflow-hidden sm:rounded-lg border border-gray-200" ]
                        [ ul [ class "divide-y divide-gray-200" ]
                            (List.map (viewBeltRow model) (List.sortBy .order model.belts))
                        ]
                ]
            ]
        ]


viewBeltRow : Model -> Belt -> Html Msg
viewBeltRow model belt =
    li [ class "py-4 px-6 flex items-center justify-between hover:bg-gray-50" ]
        [ div [ class "flex items-center space-x-4" ]
            [ div
                [ class "w-8 h-8 rounded-full border border-gray-300 flex-shrink-0"
                , style "background-color" belt.color
                ]
                []
            , div [ class "flex-1 min-w-0" ]
                [ div [ class "flex items-center" ]
                    [ p [ class "text-sm font-medium text-gray-900 truncate" ]
                        [ text belt.name ]
                    , span [ class "ml-2 text-xs text-gray-500" ]
                        [ text ("Order: " ++ String.fromInt belt.order) ]
                    ]
                , p [ class "text-xs text-gray-500 truncate" ]
                    [ text ("Games: " ++ truncateGamesList belt.gameOptions) ]
                ]
            ]
        , div [ class "flex space-x-2 ml-2 flex-shrink-0" ]
            [ button
                [ onClick (EditBelt belt)
                , class "px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition"
                ]
                [ text "Edit" ]
            , button
                [ onClick (DeleteBelt belt.id)
                , class "px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition"
                ]
                [ text "Delete" ]
            ]
        ]


viewSubmissionModal : Model -> Submission -> Html Msg
viewSubmissionModal model submission =
    div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
        [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-4xl w-full m-4 max-h-[90vh] flex flex-col" ]
            [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200 flex justify-between items-center" ]
                [ h2 [ class "text-lg font-medium text-gray-900" ]
                    [ text (submission.studentName ++ "'s Submission") ]
                , button
                    [ onClick CloseSubmission
                    , class "text-gray-400 hover:text-gray-500"
                    ]
                    [ text "×" ]
                ]
            , div [ class "px-6 py-2 bg-blue-50 border-b border-gray-200" ]
                [ button
                    [ onClick (ViewStudentRecord submission.studentId)
                    , class "text-sm text-blue-600 hover:text-blue-800"
                    ]
                    [ text ("View all submissions for " ++ submission.studentName) ]
                ]
            , div [ class "p-6 overflow-y-auto flex-grow" ]
                [ div [ class "grid grid-cols-1 md:grid-cols-2 gap-6" ]
                    [ div [ class "space-y-6" ]
                        [ div []
                            [ h3 [ class "text-lg font-medium text-gray-900 mb-3" ] [ text "Submission Details" ]
                            , div [ class "bg-gray-50 rounded-lg p-4 space-y-3" ]
                                [ div []
                                    [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Student Name:" ]
                                    , p [ class "mt-1 text-sm text-gray-900" ] [ text submission.studentName ]
                                    ]
                                , div []
                                    [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Student ID:" ]
                                    , p [ class "mt-1 text-sm text-gray-900" ] [ text submission.studentId ]
                                    ]
                                , div []
                                    [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Belt Level:" ]
                                    , p [ class "mt-1 text-sm text-gray-900" ] [ text submission.beltLevel ]
                                    ]
                                , div []
                                    [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Game Name:" ]
                                    , p [ class "mt-1 text-sm text-gray-900" ] [ text submission.gameName ]
                                    ]
                                , div []
                                    [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Submission Date:" ]
                                    , p [ class "mt-1 text-sm text-gray-900" ] [ text submission.submissionDate ]
                                    ]
                                , div []
                                    [ label [ class "block text-sm font-medium text-gray-700" ] [ text "GitHub Repository:" ]
                                    , p [ class "mt-1 text-sm text-gray-900" ]
                                        [ a
                                            [ href submission.githubLink
                                            , target "_blank"
                                            , class "text-blue-600 hover:text-blue-800 hover:underline"
                                            ]
                                            [ text submission.githubLink ]
                                        ]
                                    ]
                                , div []
                                    [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Notes:" ]
                                    , p [ class "mt-1 text-sm text-gray-900 whitespace-pre-line" ] [ text submission.notes ]
                                    ]
                                ]
                            ]
                        , div []
                            [ h3 [ class "text-lg font-medium text-gray-900 mb-3" ] [ text "Current Grade" ]
                            , case submission.grade of
                                Just grade ->
                                    div [ class "bg-gray-50 rounded-lg p-4 space-y-3" ]
                                        [ div []
                                            [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Score:" ]
                                            , p [ class "mt-1 text-lg font-bold text-gray-900" ] [ text (String.fromInt grade.score ++ "/100") ]
                                            ]
                                        , div []
                                            [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Feedback:" ]
                                            , p [ class "mt-1 text-sm text-gray-900 whitespace-pre-line" ] [ text grade.feedback ]
                                            ]
                                        , div []
                                            [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Graded By:" ]
                                            , p [ class "mt-1 text-sm text-gray-900" ] [ text grade.gradedBy ]
                                            ]
                                        , div []
                                            [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Grading Date:" ]
                                            , p [ class "mt-1 text-sm text-gray-900" ] [ text grade.gradingDate ]
                                            ]
                                        ]

                                Nothing ->
                                    div [ class "bg-gray-50 rounded-lg p-4 flex justify-center" ]
                                        [ p [ class "text-gray-500 italic" ] [ text "This submission has not been graded yet." ] ]
                            ]
                        ]
                    , div [ class "space-y-6" ]
                        [ div []
                            [ h3 [ class "text-lg font-medium text-gray-900 mb-3" ]
                                [ text
                                    (if submission.grade == Nothing then
                                        "Add Grade"

                                     else
                                        "Update Grade"
                                    )
                                ]
                            , div [ class "bg-gray-50 rounded-lg p-4 space-y-4" ]
                                [ div []
                                    [ label [ for "scoreInput", class "block text-sm font-medium text-gray-700" ] [ text "Score (0-100):" ]
                                    , input
                                        [ type_ "number"
                                        , id "scoreInput"
                                        , Html.Attributes.min "0"
                                        , Html.Attributes.max "100"
                                        , value model.tempScore
                                        , onInput UpdateTempScore
                                        , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                        ]
                                        []
                                    ]
                                , div []
                                    [ label [ for "feedbackInput", class "block text-sm font-medium text-gray-700" ] [ text "Feedback:" ]
                                    , textarea
                                        [ id "feedbackInput"
                                        , value model.tempFeedback
                                        , onInput UpdateTempFeedback
                                        , rows 6
                                        , placeholder "Provide feedback on the game submission..."
                                        , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                        ]
                                        []
                                    ]
                                , button
                                    [ onClick SubmitGrade
                                    , class "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                                    ]
                                    [ text
                                        (if submission.grade == Nothing then
                                            "Submit Grade"

                                         else
                                            "Update Grade"
                                        )
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            , div [ class "px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end" ]
                [ button
                    [ onClick CloseSubmission
                    , class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    ]
                    [ text "Close" ]
                ]
            ]
        ]
