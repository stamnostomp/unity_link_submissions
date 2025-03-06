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

-- Belt management ports
port requestBelts : () -> Cmd msg
port receiveBelts : (Decode.Value -> msg) -> Sub msg
port saveBelt : Encode.Value -> Cmd msg
port deleteBelt : String -> Cmd msg
port beltResult : (String -> msg) -> Sub msg


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
    }

type alias Belt =
    { id : String
    , name : String
    , color : String
    , order : Int
    , gameOptions : List String
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

type SortBy
    = ByName
    | ByDate
    | ByBelt
    | ByGradeStatus

type SortDirection
    = Ascending
    | Descending

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

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
                          }, Cmd.none )

                Err error ->
                    ( { model
                      | appState = NotAuthenticated
                      , authError = Just (Decode.errorToString error)
                      , loading = False
                      }, Cmd.none )

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
                        "all" -> Nothing
                        "graded" -> Just True
                        "ungraded" -> Just False
                        _ -> Nothing
            in
            ( { model | filterGraded = filterGraded }, Cmd.none )

        UpdateSortBy sortBy ->
            ( { model | sortBy = sortBy }, Cmd.none )

        ToggleSortDirection ->
            let
                newDirection =
                    case model.sortDirection of
                        Ascending -> Descending
                        Descending -> Ascending
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

        ShowCreateStudentForm ->
            ( { model | page = CreateStudentPage, newStudentName = "" }, Cmd.none )

        CloseCreateStudentForm ->
            ( { model | page = SubmissionsPage }, Cmd.none )

        UpdateNewStudentName name ->
            ( { model | newStudentName = name }, Cmd.none )



        CreateNewStudent ->
            let
                trimmedName = String.trim model.newStudentName
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
                      }, Cmd.none )

                Err error ->
                    ( { model
                      | loading = False
                      , error = Just ("Error creating student: " ++ Decode.errorToString error)
                      }, Cmd.none )

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
                    orderResult = String.toInt model.newBeltOrder
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
                            orderResult = String.toInt model.newBeltOrder
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
        , gradeResult GradeResult
        , beltResult BeltResult
        ]


-- JSON DECODERS & ENCODERS

decodeSubmissionsResponse : Decode.Value -> Result Decode.Error (List Submission)
decodeSubmissionsResponse value =
    Decode.decodeValue (Decode.list submissionDecoder) value

submissionDecoder : Decoder Submission
submissionDecoder =
    Decode.map6
        (\id gameBelt gameName githubLink notes submissionDate ->
            { id = id
            , studentId = ""  -- Temporary value, will be filled in later
            , studentName = "Unknown"  -- Default value, will be overridden if available
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
    Decode.map3 User
        (Decode.field "uid" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "displayName" Decode.string)

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


-- HELPERS

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
        parts = String.split "." name
    in
    List.length parts == 2 &&
    List.all (\part -> String.length part > 0) parts

--helper to format the display name properly
formatDisplayName : String -> String
formatDisplayName name =
    let
        parts = String.split "." name
        firstName = List.head parts |> Maybe.withDefault ""
        lastName = List.drop 1 parts |> List.head |> Maybe.withDefault ""
        capitalizedFirst = String.toUpper (String.left 1 firstName) ++ String.dropLeft 1 firstName
        capitalizedLast = String.toUpper (String.left 1 lastName) ++ String.dropLeft 1 lastName
    in
    capitalizedFirst ++ " " ++ capitalizedLast

-- Helper function to capitalize words in a string
capitalizeWords : String -> String
capitalizeWords str =
    String.join " " (List.map capitalizeWord (String.split " " str))

capitalizeWord : String -> String
capitalizeWord word =
    case String.uncons word of
        Just (firstChar, rest) ->
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
                        case (a.grade, b.grade) of
                            (Just _, Nothing) -> LT
                            (Nothing, Just _) -> GT
                            _ -> compare a.submissionDate b.submissionDate

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
    div [ class "min-h-screen bg-gray-100 py-6 flex flex-col" ]
        [ div [ class "max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 w-full" ]
            [ h1 [ class "text-3xl font-bold text-gray-900 mb-8 text-center" ] [ text "Game Submission Admin" ]
            , viewContent model
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
                         [ button
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
            ]
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
                    [onClick ShowBeltManagement
                    , class "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    ]
                    [ text "Manage Belts"]
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
                        ([ option [ value "all" ] [ text "All Belts" ] ] ++
                            List.map (\belt -> option [ value belt.name ] [ text belt.name ]) model.belts)
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
                    [ text (if model.sortDirection == Ascending then "↑" else "↓") ]
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
        baseClass = "px-3 py-1 rounded text-sm"
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
            ]        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-900" ] [ text submission.gameName ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-900" ] [ text submission.beltLevel ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div [ class "text-sm text-gray-500" ] [ text submission.submissionDate ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ viewGradeBadge submission.grade ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-3" ]
            [ button
                [ onClick (SelectSubmission submission)
                , class "text-blue-600 hover:text-blue-900"
                ]
                [ text (if submission.grade == Nothing then "Grade" else "View/Edit") ]
            , button
                [ onClick (ViewStudentRecord submission.studentId)
                , class "text-green-600 hover:text-green-900"
                ]
                [ text "Student Record" ]
            ]
        ]

viewGradeBadge : Maybe Grade -> Html Msg
viewGradeBadge maybeGrade =
    case maybeGrade of
        Just grade ->
            let
                (bgColor, textColor) =
                    if grade.score >= 90 then
                        ("bg-green-100", "text-green-800")
                    else if grade.score >= 70 then
                        ("bg-blue-100", "text-blue-800")
                    else if grade.score >= 60 then
                        ("bg-yellow-100", "text-yellow-800")
                    else
                        ("bg-red-100", "text-red-800")
            in
            span [ class ("inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium " ++ bgColor ++ " " ++ textColor) ]
                [ text (String.fromInt grade.score ++ "/100") ]

        Nothing ->
            span [ class "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800" ]
                [ text "Ungraded" ]

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
        , td [ class "px-6 py-4 whitespace-nowrap text-right text-sm font-medium" ]
            [ button
                [ onClick (SelectSubmission submission)
                , class "text-blue-600 hover:text-blue-900"
                ]
                [ text (if submission.grade == Nothing then "Grade" else "View/Edit") ]
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

        -- This section would be expanded in the future to list existing students
        , div [ class "bg-white shadow rounded-lg p-6 mt-6" ]
            [ h3 [ class "text-lg font-medium text-gray-900 mb-4" ] [ text "Existing Students" ]
            , p [ class "text-gray-500 italic" ]
                [ text "Student listing functionality will be added here in a future update." ]
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
                            [ text (case model.editingBelt of
                                      Just belt -> "Edit Belt: " ++ belt.name
                                      Nothing -> "Add New Belt"
                            ) ]
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
                ] []
            , div [ class "flex-1 min-w-0" ]
                [ div [ class "flex items-center" ]
                    [ p [ class "text-sm font-medium text-gray-900 truncate" ]
                        [ text belt.name ]
                    , span [ class "ml-2 text-xs text-gray-500" ]
                        [ text ("Order: " ++ String.fromInt belt.order) ]
                    ]
                , p [ class "text-xs text-gray-500 truncate" ]
                    [ text ("Games: " ++ String.join ", " belt.gameOptions) ]
                ]
            ]
        , div [ class "flex space-x-2" ]
            [ button
                [ onClick (EditBelt belt)
                , class "text-indigo-600 hover:text-indigo-900 text-sm font-medium"
                ]
                [ text "Edit" ]
            , button
                [ onClick (DeleteBelt belt.id)
                , class "text-red-600 hover:text-red-900 text-sm font-medium"
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
                            [ h3 [ class "text-lg font-medium text-gray-900 mb-3" ] [ text (if submission.grade == Nothing then "Add Grade" else "Update Grade") ]
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
                                    [ text (if submission.grade == Nothing then "Submit Grade" else "Update Grade") ]
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
