module Admin.Main exposing (main)

import Admin.Components.Navigation as Navigation
import Admin.Pages.AdminUsers as AdminUsers
import Admin.Pages.BeltManagement as BeltManagement
import Admin.Pages.Login as Login
import Admin.Pages.PointManagement as PointManagement
import Admin.Pages.StudentManagement as StudentManagement
import Admin.Pages.Submissions as Submissions
import Admin.Types exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Shared.Ports as Ports
import Shared.Types exposing (..)
import Shared.Utils exposing (..)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { -- App State
        appState = NotAuthenticated
      , page = SubmissionsPage
      , loading = False
      , error = Nothing
      , success = Nothing

      -- Authentication
      , loginEmail = ""
      , loginPassword = ""
      , authError = Nothing

      -- Data
      , submissions = []
      , students = []
      , belts = []
      , adminUsers = []

      -- Point Management Data
      , studentPoints = []
      , pointRedemptions = []
      , pointRewards = []
      , selectedPointRedemption = Nothing

      -- Current Selection/Editing
      , currentSubmission = Nothing
      , currentStudent = Nothing
      , studentSubmissions = []
      , editingStudent = Nothing
      , editingBelt = Nothing
      , editingAdminUser = Nothing
      , editingReward = Nothing

      -- Filtering and Sorting
      , filterText = ""
      , filterBelt = Nothing
      , filterGraded = Nothing
      , sortBy = ByDate
      , sortDirection = Descending
      , studentFilterText = ""
      , studentSortBy = ByStudentName
      , studentSortDirection = Ascending
      , studentPointsFilterText = ""

      -- Form States
      , tempScore = ""
      , tempFeedback = ""
      , newStudentName = ""
      , newBeltName = ""
      , newBeltColor = "#000000"
      , newBeltOrder = ""
      , newBeltGameOptions = ""
      , adminUserForm = initAdminUserForm
      , showAdminUserForm = False

      -- Point Management Form States
      , newRewardName = ""
      , newRewardDescription = ""
      , newRewardCost = ""
      , newRewardCategory = ""
      , newRewardStock = ""

      -- Point Management Modal States
      , showAwardPointsModal = False
      , awardPointsStudentId = ""
      , awardPointsAmount = ""
      , awardPointsReason = ""

      -- Auto-award settings
      , autoAwardPoints = True

      -- Confirmation States
      , confirmDeleteStudent = Nothing
      , confirmDeleteSubmission = Nothing
      , confirmDeleteAdmin = Nothing
      , confirmDeleteReward = Nothing

      -- Result Messages
      , adminUserCreationResult = Nothing
      , adminUserUpdateResult = Nothing
      , adminUserDeletionResult = Nothing

      -- Password Reset
      , showPasswordReset = False
      , passwordResetEmail = ""
      , passwordResetMessage = Nothing
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Authentication Messages
        UpdateLoginEmail email ->
            ( { model | loginEmail = email }, Cmd.none )

        UpdateLoginPassword password ->
            ( { model | loginPassword = password }, Cmd.none )

        SubmitLogin ->
            if String.isEmpty model.loginEmail || String.isEmpty model.loginPassword then
                ( { model | authError = Just "Please enter both email and password" }, Cmd.none )

            else
                ( { model | appState = AuthenticatingWith model.loginEmail model.loginPassword, authError = Nothing, loading = True }
                , Ports.signIn (encodeCredentials model.loginEmail model.loginPassword)
                )

        PerformSignOut ->
            ( { model | appState = NotAuthenticated, loading = True }, Ports.signOut () )

        ReceivedAuthState result ->
            case result of
                Ok authState ->
                    if authState.isSignedIn then
                        case authState.user of
                            Just user ->
                                ( { model | appState = Authenticated user, loading = True, authError = Nothing }
                                , Cmd.batch [ Ports.requestSubmissions (), Ports.requestBelts () ]
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
                        ( { model | appState = NotAuthenticated, authError = Just authResult.message, loading = False }, Cmd.none )

                Err error ->
                    ( { model | appState = NotAuthenticated, authError = Just (Decode.errorToString error), loading = False }, Cmd.none )

        -- Navigation Messages
        ShowSubmissionsPage ->
            ( { model | page = SubmissionsPage, error = Nothing, success = Nothing }, Cmd.none )

        ShowStudentManagementPage ->
            ( { model | page = StudentManagementPage, error = Nothing, success = Nothing }, Ports.requestAllStudents () )

        ShowBeltManagementPage ->
            ( { model | page = BeltManagementPage, newBeltName = "", newBeltColor = "#000000", newBeltOrder = "", newBeltGameOptions = "", editingBelt = Nothing, error = Nothing, success = Nothing }, Ports.requestBelts () )

        ShowAdminUsersPage ->
            if isSuperUser model then
                ( { model | page = AdminUsersPage, adminUserCreationResult = Nothing, adminUserUpdateResult = Nothing, adminUserDeletionResult = Nothing, loading = True }, Ports.requestAllAdmins () )

            else
                ( { model | error = Just "You don't have permission to access admin management." }, Cmd.none )

        ShowPointManagementPage ->
            ( { model | page = PointManagementPage, loading = True }
            , Cmd.batch
                [ -- CRITICAL: Load students first so Point Management can initialize properly
                  Ports.requestAllStudents ()
                , Ports.requestStudentPoints ()
                , Ports.requestPointRedemptions ()
                , Ports.requestPointRewards ()
                ]
            )

        CloseCurrentPage ->
            ( { model | page = SubmissionsPage, currentStudent = Nothing, studentSubmissions = [], editingStudent = Nothing, editingBelt = Nothing, editingAdminUser = Nothing, confirmDeleteStudent = Nothing, confirmDeleteSubmission = Nothing, confirmDeleteAdmin = Nothing, showAdminUserForm = False, error = Nothing, success = Nothing }, Cmd.none )

        -- Student Record Navigation (handle here so it works from any page)
        ViewStudentRecord studentId ->
            ( { model | loading = True, page = StudentManagementPage }
            , Ports.requestStudentRecord studentId
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
                | page = StudentManagementPage
                , currentStudent = Nothing
                , studentSubmissions = []
              }
            , Cmd.none
            )

        -- Password Reset Messages
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
                ( { model | passwordResetMessage = Nothing, loading = True }, Ports.requestPasswordReset model.passwordResetEmail )

        -- Handle student loading for any page that needs it
        ReceiveAllStudents result ->
            case result of
                Ok students ->
                    ( { model | students = students, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        PasswordResetResult result ->
            case result of
                Ok resetResult ->
                    ( { model | passwordResetMessage = Just resetResult.message, loading = False }, Cmd.none )

                Err error ->
                    ( { model | passwordResetMessage = Just ("Error: " ++ Decode.errorToString error), loading = False }, Cmd.none )

        -- Delegate to Page Modules
        _ ->
            case model.page of
                SubmissionsPage ->
                    Submissions.update msg model

                StudentManagementPage ->
                    StudentManagement.update msg model

                StudentRecordPage _ _ ->
                    StudentManagement.update msg model

                BeltManagementPage ->
                    BeltManagement.update msg model

                AdminUsersPage ->
                    AdminUsers.update msg model

                PointManagementPage ->
                    PointManagement.update msg model



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-gray-300 py-6 flex flex-col" ]
        [ div [ class "max-w-8xl mx-auto px-4 sm:px-6 lg:px-8 w-full" ]
            [ viewContent model ]
        ]


viewContent : Model -> Html Msg
viewContent model =
    case model.appState of
        NotAuthenticated ->
            Login.view model

        AuthenticatingWith _ _ ->
            viewLoadingAuthentication

        Authenticated user ->
            div []
                [ Navigation.view model user
                , if model.loading then
                    viewLoading "Loading..."

                  else
                    div [] [ viewMessages model, viewCurrentPage model ]
                ]


viewCurrentPage : Model -> Html Msg
viewCurrentPage model =
    case model.page of
        SubmissionsPage ->
            Submissions.view model

        StudentManagementPage ->
            StudentManagement.view model

        StudentRecordPage student submissions ->
            StudentManagement.view model

        BeltManagementPage ->
            BeltManagement.view model

        AdminUsersPage ->
            AdminUsers.view model

        PointManagementPage ->
            PointManagement.view model


viewMessages : Model -> Html Msg
viewMessages model =
    div []
        [ case model.error of
            Just errorMsg ->
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ] [ div [ class "flex" ] [ div [ class "flex-shrink-0" ] [ span [ class "text-red-400 text-lg" ] [ text "⚠" ] ], div [ class "ml-3" ] [ p [ class "text-sm text-red-700" ] [ text errorMsg ] ] ] ]

            Nothing ->
                text ""
        , case model.success of
            Just successMsg ->
                div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ] [ div [ class "flex" ] [ div [ class "flex-shrink-0" ] [ span [ class "text-green-400 text-lg" ] [ text "✓" ] ], div [ class "ml-3" ] [ p [ class "text-sm text-green-700" ] [ text successMsg ] ] ] ]

            Nothing ->
                text ""
        ]


viewLoading : String -> Html Msg
viewLoading message =
    div [ class "flex justify-center my-12" ]
        [ div [ class "flex flex-col items-center" ]
            [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500 mb-4" ] []
            , p [ class "text-gray-600" ] [ text message ]
            ]
        ]


viewLoadingAuthentication : Html Msg
viewLoadingAuthentication =
    div [ class "bg-white shadow rounded-lg max-w-md mx-auto p-6 text-center" ]
        [ div [ class "flex justify-center my-6" ] [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" ] [] ]
        , p [ class "text-gray-600" ] [ text "Signing you in..." ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.receiveAuthState (decodeAuthState >> ReceivedAuthState)
        , Ports.receiveAuthResult (decodeAuthResult >> ReceivedAuthResult)
        , Ports.passwordResetResult (decodePasswordResetResult >> PasswordResetResult)
        , Ports.receiveSubmissions (decodeSubmissionsResponse >> ReceiveSubmissions)
        , Ports.gradeResult GradeResult
        , Ports.submissionDeleted (decodeSubmissionDeletedResponse >> SubmissionDeleted)
        , Ports.receiveStudentRecord (decodeStudentRecordResponse >> ReceivedStudentRecord)
        , Ports.studentCreated (decodeStudentResponse >> StudentCreated)
        , Ports.receiveAllStudents (decodeStudentsResponse >> ReceiveAllStudents)
        , Ports.studentUpdated (decodeStudentResponse >> StudentUpdated)
        , Ports.studentDeleted (decodeStudentDeletedResponse >> StudentDeleted)
        , Ports.receiveBelts (decodeBeltsResponse >> ReceiveBelts)
        , Ports.beltResult BeltResult
        , Ports.adminUserCreated (decodeAdminCreationResult >> AdminUserCreated)
        , Ports.receiveAllAdmins (decodeAdminUsersResponse >> ReceiveAllAdmins)
        , Ports.adminUserDeleted (decodeAdminActionResult >> AdminUserDeleted)
        , Ports.adminUserUpdated (decodeAdminActionResult >> AdminUserUpdated)

        -- Point Management Subscriptions
        , Ports.receiveStudentPoints (decodeStudentPointsResponse >> ReceiveStudentPoints)
        , Ports.pointsAwarded (decodePointsAwardedResponse >> PointsAwarded)
        , Ports.receivePointRedemptions (decodePointRedemptionsResponse >> ReceivePointRedemptions)
        , Ports.redemptionProcessed (decodeRedemptionProcessedResponse >> RedemptionProcessed)
        , Ports.receivePointRewards (decodePointRewardsResponse >> ReceivePointRewards)
        , Ports.pointRewardResult RewardResult
        ]



-- HELPER FUNCTIONS


isSuperUser : Model -> Bool
isSuperUser model =
    case model.appState of
        Authenticated user ->
            user.role == "superuser"

        _ ->
            False



-- JSON DECODERS


decodeAuthState : Decode.Value -> Result Decode.Error { user : Maybe User, isSignedIn : Bool }
decodeAuthState value =
    let
        decoder =
            Decode.map2 (\user isSignedIn -> { user = user, isSignedIn = isSignedIn }) (Decode.field "user" (Decode.nullable userDecoder)) (Decode.field "isSignedIn" Decode.bool)
    in
    Decode.decodeValue decoder value


decodeAuthResult : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodeAuthResult value =
    let
        decoder =
            Decode.map2 (\success message -> { success = success, message = message }) (Decode.field "success" Decode.bool) (Decode.field "message" Decode.string)
    in
    Decode.decodeValue decoder value


decodeSubmissionsResponse : Decode.Value -> Result Decode.Error (List Submission)
decodeSubmissionsResponse value =
    Decode.decodeValue (Decode.list submissionDecoder) value


decodeStudentRecordResponse : Decode.Value -> Result Decode.Error { student : Student, submissions : List Submission }
decodeStudentRecordResponse value =
    let
        decoder =
            Decode.map2 (\student submissions -> { student = student, submissions = submissions }) (Decode.field "student" studentDecoder) (Decode.field "submissions" (Decode.list submissionDecoder))
    in
    Decode.decodeValue decoder value


decodeStudentResponse : Decode.Value -> Result Decode.Error Student
decodeStudentResponse value =
    Decode.decodeValue studentDecoder value


decodeBeltsResponse : Decode.Value -> Result Decode.Error (List Belt)
decodeBeltsResponse value =
    Decode.decodeValue (Decode.list beltDecoder) value


decodeStudentsResponse : Decode.Value -> Result Decode.Error (List Student)
decodeStudentsResponse value =
    Decode.decodeValue (Decode.list studentDecoder) value


decodeStudentDeletedResponse : Decode.Value -> Result Decode.Error String
decodeStudentDeletedResponse value =
    Decode.decodeValue Decode.string value


decodeSubmissionDeletedResponse : Decode.Value -> Result Decode.Error String
decodeSubmissionDeletedResponse value =
    Decode.decodeValue Decode.string value


decodeAdminCreationResult : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodeAdminCreationResult value =
    Decode.decodeValue (Decode.map2 (\success message -> { success = success, message = message }) (Decode.field "success" Decode.bool) (Decode.field "message" Decode.string)) value


decodeAdminUsersResponse : Decode.Value -> Result Decode.Error (List AdminUser)
decodeAdminUsersResponse value =
    Decode.decodeValue (Decode.list adminUserDecoder) value


decodeAdminActionResult : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodeAdminActionResult value =
    Decode.decodeValue (Decode.map2 (\success message -> { success = success, message = message }) (Decode.field "success" Decode.bool) (Decode.field "message" Decode.string)) value


decodePasswordResetResult : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodePasswordResetResult value =
    Decode.decodeValue (Decode.map2 (\success message -> { success = success, message = message }) (Decode.field "success" Decode.bool) (Decode.field "message" Decode.string)) value



-- Point Management Decoders


decodeStudentPointsResponse : Decode.Value -> Result Decode.Error (List StudentPoints)
decodeStudentPointsResponse value =
    Decode.decodeValue (Decode.list studentPointsDecoder) value


decodePointsAwardedResponse : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodePointsAwardedResponse value =
    Decode.decodeValue
        (Decode.map2 (\success message -> { success = success, message = message })
            (Decode.field "success" Decode.bool)
            (Decode.field "message" Decode.string)
        )
        value


decodePointRedemptionsResponse : Decode.Value -> Result Decode.Error (List PointRedemption)
decodePointRedemptionsResponse value =
    Decode.decodeValue (Decode.list pointRedemptionDecoder) value


decodeRedemptionProcessedResponse : Decode.Value -> Result Decode.Error { success : Bool, message : String }
decodeRedemptionProcessedResponse value =
    Decode.decodeValue
        (Decode.map2 (\success message -> { success = success, message = message })
            (Decode.field "success" Decode.bool)
            (Decode.field "message" Decode.string)
        )
        value


decodePointRewardsResponse : Decode.Value -> Result Decode.Error (List PointReward)
decodePointRewardsResponse value =
    Decode.decodeValue (Decode.list pointRewardDecoder) value
