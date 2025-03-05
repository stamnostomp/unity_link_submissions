port module Student exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time
import Task


-- PORTS

port findStudent : String -> Cmd msg
port studentFound : (Decode.Value -> msg) -> Sub msg
port saveSubmission : Encode.Value -> Cmd msg
port submissionResult : (String -> msg) -> Sub msg


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
    , submissions : List Submission
    }

type alias Submission =
    { id : String
    , studentId : String
    , gameLevel : String
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

type Page
    = NamePage
    | StudentProfilePage Student
    | SubmissionFormPage Student
    | SubmissionCompletePage Student Submission
    | LoadingPage String

type alias Model =
    { page : Page
    , searchName : String
    , gameLevel : String
    , gameName : String
    , githubLink : String
    , notes : String
    , errorMessage : Maybe String
    , successMessage : Maybe String
    }

init : () -> ( Model, Cmd Msg )
init _ =
    ( { page = NamePage
      , searchName = ""
      , gameLevel = ""
      , gameName = ""
      , githubLink = ""
      , notes = ""
      , errorMessage = Nothing
      , successMessage = Nothing
      }
    , Cmd.none
    )


-- GAME OPTIONS BY LEVEL

gameOptionsByLevel : List String -> List String
gameOptionsByLevel levels =
    let
        beginner = [ "Game 1", "Game 2", "Game 3" ]
        intermediate = [ "Game A", "Game B", "Game C" ]
        advanced = [ "Game 4", "Game 5", "Game 6" ]
    in
    List.concat
        [ if List.member "Beginner" levels then beginner else []
        , if List.member "Intermediate" levels then intermediate else []
        , if List.member "Advanced" levels then advanced else []
        ]

getGameOptions : String -> List String
getGameOptions level =
    case level of
        "Beginner" -> [ "Game 1", "Game 2", "Game 3" ]
        "Intermediate" -> [ "Game A", "Game B", "Game C" ]
        "Advanced" -> [ "Game 4", "Game 5", "Game 6" ]
        _ -> []


-- UPDATE

type Msg
    = UpdateSearchName String
    | SearchStudent
    | StudentFoundResult (Result Decode.Error (Maybe Student))
    | StartNewSubmission Student
    | UpdateGameLevel String
    | UpdateGameName String
    | UpdateGithubLink String
    | UpdateNotes String
    | SubmitForm Student
    | SubmissionSaved String
    | BackToProfile
    | BackToSearch
    | Reset

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateSearchName name ->
            ( { model | searchName = name }, Cmd.none )

        SearchStudent ->
            if String.trim model.searchName == "" then
                ( { model | errorMessage = Just "Please enter your name to continue" }, Cmd.none )
            else
                ( { model | page = LoadingPage "Searching for your record...", errorMessage = Nothing }
                , findStudent model.searchName
                )

        StudentFoundResult result ->
            case result of
                Ok maybeStudent ->
                    case maybeStudent of
                        Just student ->
                            ( { model | page = StudentProfilePage student, errorMessage = Nothing }, Cmd.none )

                        Nothing ->
                            ( { model
                              | page = NamePage
                              , errorMessage = Just "No record found. Please check your name or ask your teacher to create a record for you."
                              }, Cmd.none )

                Err error ->
                    ( { model
                      | page = NamePage
                      , errorMessage = Just ("Error loading record: " ++ Decode.errorToString error)
                      }, Cmd.none )

        StartNewSubmission student ->
            ( { model
              | page = SubmissionFormPage student
              , gameLevel = ""
              , gameName = ""
              , githubLink = ""
              , notes = ""
              , errorMessage = Nothing
              }, Cmd.none )

        UpdateGameLevel level ->
            let
                -- Reset game name when level changes
                gameOptions = getGameOptions level
                defaultGame = List.head gameOptions |> Maybe.withDefault ""
            in
            ( { model | gameLevel = level, gameName = defaultGame }, Cmd.none )

        UpdateGameName game ->
            ( { model | gameName = game }, Cmd.none )

        UpdateGithubLink link ->
            ( { model | githubLink = link }, Cmd.none )

        UpdateNotes notes ->
            ( { model | notes = notes }, Cmd.none )

        SubmitForm student ->
            if String.trim model.gameLevel == "" || String.trim model.gameName == "" || String.trim model.githubLink == "" then
                ( { model | errorMessage = Just "Please fill in all required fields" }, Cmd.none )
            else
                let
                    -- For a real app, you'd want to generate a better ID and use actual date
                    currentDate = "2025-03-04"
                    newSubmission =
                        { id = student.id ++ "-" ++ model.gameLevel ++ "-" ++ String.fromInt (List.length student.submissions + 1)
                        , studentId = student.id
                        , gameLevel = model.gameLevel
                        , gameName = model.gameName
                        , githubLink = model.githubLink
                        , notes = model.notes
                        , submissionDate = currentDate
                        , grade = Nothing
                        }
                in
                ( { model | page = LoadingPage "Saving your submission...", errorMessage = Nothing }
                , saveSubmission (encodeSubmission newSubmission)
                )

        SubmissionSaved result ->
            case model.page of
                LoadingPage _ ->
                    if String.startsWith "Error:" result then
                        ( { model | errorMessage = Just result, page = NamePage }, Cmd.none )
                    else
                        -- Re-search student to get updated record
                        ( model, findStudent model.searchName )

                _ ->
                    ( model, Cmd.none )

        BackToProfile ->
            case model.page of
                SubmissionFormPage student ->
                    ( { model | page = StudentProfilePage student }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        BackToSearch ->
            ( { model | page = NamePage }, Cmd.none )

        Reset ->
            init ()

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ studentFound (decodeStudentResponse >> StudentFoundResult)
        , submissionResult SubmissionSaved
        ]


-- JSON ENCODERS & DECODERS

encodeStudent : Student -> Encode.Value
encodeStudent student =
    Encode.object
        [ ( "id", Encode.string student.id )
        , ( "name", Encode.string student.name )
        , ( "created", Encode.string student.created )
        , ( "lastActive", Encode.string student.lastActive )
        ]

encodeSubmission : Submission -> Encode.Value
encodeSubmission submission =
    Encode.object
        [ ( "id", Encode.string submission.id )
        , ( "studentId", Encode.string submission.studentId )
        , ( "gameLevel", Encode.string submission.gameLevel )
        , ( "gameName", Encode.string submission.gameName )
        , ( "githubLink", Encode.string submission.githubLink )
        , ( "notes", Encode.string submission.notes )
        , ( "submissionDate", Encode.string submission.submissionDate )
        ]

decodeStudentResponse : Decode.Value -> Result Decode.Error (Maybe Student)
decodeStudentResponse value =
    Decode.decodeValue (Decode.nullable studentDecoder) value

studentDecoder : Decoder Student
studentDecoder =
    Decode.map5 Student
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "created" Decode.string)
        (Decode.field "lastActive" Decode.string)
        (Decode.field "submissions" (Decode.list submissionDecoder))

submissionDecoder : Decoder Submission
submissionDecoder =
    Decode.map8 Submission
        (Decode.field "id" Decode.string)
        (Decode.field "studentId" Decode.string)
        (Decode.field "gameLevel" Decode.string)
        (Decode.field "gameName" Decode.string)
        (Decode.field "githubLink" Decode.string)
        (Decode.field "notes" Decode.string)
        (Decode.field "submissionDate" Decode.string)
        (Decode.maybe (Decode.field "grade" gradeDecoder))

gradeDecoder : Decoder Grade
gradeDecoder =
    Decode.map4 Grade
        (Decode.field "score" Decode.int)
        (Decode.field "feedback" Decode.string)
        (Decode.field "gradedBy" Decode.string)
        (Decode.field "gradingDate" Decode.string)


-- VIEW

view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-gray-100 py-6 flex flex-col justify-center sm:py-12" ]
        [ div [ class "relative py-3 sm:max-w-4xl sm:mx-auto" ]
            [ div [ class "absolute inset-0 bg-gradient-to-r from-blue-400 to-blue-600 shadow-lg transform -skew-y-6 sm:skew-y-0 sm:-rotate-6 sm:rounded-lg" ] []
            , div [ class "relative px-4 py-10 bg-white shadow-lg sm:rounded-lg sm:p-20" ]
                [ div [ class "max-w-4xl mx-auto" ]
                    [ h1 [ class "text-2xl font-semibold text-center text-gray-800 mb-6" ] [ text "Unity Game Submissions" ]
                    , viewPage model
                    , viewError model.errorMessage
                    , viewSuccess model.successMessage
                    ]
                ]
            ]
        ]

viewPage : Model -> Html Msg
viewPage model =
    case model.page of
        NamePage ->
            viewNamePage model

        StudentProfilePage student ->
            viewStudentProfilePage model student

        SubmissionFormPage student ->
            viewSubmissionFormPage model student

        SubmissionCompletePage student submission ->
            viewSubmissionCompletePage model student submission

        LoadingPage message ->
            viewLoading message

viewNamePage : Model -> Html Msg
viewNamePage model =
    div [ class "space-y-6" ]
        [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Student Record Lookup" ]
        , p [ class "text-gray-600" ] [ text "Please enter your name to find your record." ]
        , div [ class "space-y-2" ]
            [ label [ for "studentName", class "block text-sm font-medium text-gray-700" ] [ text "Full Name:" ]
            , input
                [ type_ "text"
                , id "studentName"
                , value model.searchName
                , onInput UpdateSearchName
                , placeholder "Enter your full name"
                , autofocus True
                , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                ]
                []
            ]
        , div [ class "mt-4" ]
            [ button
                [ onClick SearchStudent
                , class "w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Find My Record" ]
            ]
        , div [ class "mt-4 bg-amber-50 border border-amber-200 rounded-md p-4 text-center" ]
            [ p [ class "text-sm text-amber-800" ]
                [ text "If you can't find your record, please ask your teacher to create one for you." ]
            ]
        ]

viewStudentProfilePage : Model -> Student -> Html Msg
viewStudentProfilePage model student =
    div [ class "space-y-6" ]
        [ div [ class "border-b border-gray-200 pb-5" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-700" ]
                    [ text ("Welcome, " ++ student.name) ]
                , button
                    [ onClick BackToSearch
                    , class "text-sm text-gray-600 hover:text-gray-900"
                    ]
                    [ text "Not you? Switch accounts" ]
                ]
            , div [ class "mt-1 flex flex-col sm:flex-row sm:flex-wrap sm:mt-0 sm:space-x-6" ]
                [ div [ class "mt-2 flex items-center text-sm text-gray-500" ]
                    [ text "Student ID: "
                    , span [ class "ml-1 font-medium" ] [ text student.id ]
                    ]
                , div [ class "mt-2 flex items-center text-sm text-gray-500" ]
                    [ text "Joined: "
                    , span [ class "ml-1" ] [ text student.created ]
                    ]
                ]
            ]

        , div [ class "space-y-4" ]
            [ div [ class "flex justify-between items-center" ]
                [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Your Game Submissions" ]
                , button
                    [ onClick (StartNewSubmission student)
                    , class "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    ]
                    [ text "Submit New Game" ]
                ]

            , if List.isEmpty student.submissions then
                div [ class "bg-gray-50 rounded-md p-4 text-center" ]
                    [ p [ class "text-gray-500" ] [ text "No submissions yet. Start by submitting your first game!" ] ]
            else
                div [ class "overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg" ]
                    [ table [ class "min-w-full divide-y divide-gray-300" ]
                        [ thead [ class "bg-gray-50" ]
                            [ tr []
                                [ th [ class "py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6" ] [ text "Game" ]
                                , th [ class "px-3 py-3.5 text-left text-sm font-semibold text-gray-900" ] [ text "Level" ]
                                , th [ class "px-3 py-3.5 text-left text-sm font-semibold text-gray-900" ] [ text "Submitted" ]
                                , th [ class "px-3 py-3.5 text-left text-sm font-semibold text-gray-900" ] [ text "Grade" ]
                                ]
                            ]
                        , tbody [ class "divide-y divide-gray-200 bg-white" ]
                            (List.map viewSubmissionRow student.submissions)
                        ]
                    ]
            ]
        ]

viewSubmissionRow : Submission -> Html Msg
viewSubmissionRow submission =
    tr []
        [ td [ class "whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6" ]
            [ text submission.gameName ]
        , td [ class "whitespace-nowrap px-3 py-4 text-sm text-gray-500" ]
            [ text submission.gameLevel ]
        , td [ class "whitespace-nowrap px-3 py-4 text-sm text-gray-500" ]
            [ text submission.submissionDate ]
        , td [ class "whitespace-nowrap px-3 py-4 text-sm text-gray-500" ]
            [ viewGradeStatus submission.grade ]
        ]

viewGradeStatus : Maybe Grade -> Html Msg
viewGradeStatus maybeGrade =
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
                [ text "Pending" ]

viewSubmissionFormPage : Model -> Student -> Html Msg
viewSubmissionFormPage model student =
    let
        gameOptions = getGameOptions model.gameLevel
    in
    div [ class "space-y-6" ]
        [ h2 [ class "text-xl font-medium text-gray-700" ] [ text ("New Submission for " ++ student.name) ]
        , p [ class "text-gray-600" ] [ text "Please provide details about your Unity game submission." ]

        , div [ class "space-y-4" ]
            [ div [ class "space-y-2" ]
                [ label [ for "gameLevel", class "block text-sm font-medium text-gray-700" ] [ text "Game Level:" ]
                , select
                    [ id "gameLevel"
                    , onInput UpdateGameLevel
                    , value model.gameLevel
                    , class "mt-1 block w-full bg-white border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    [ option [ value "" ] [ text "-- Select Level --" ]
                    , option [ value "Beginner" ] [ text "Beginner" ]
                    , option [ value "Intermediate" ] [ text "Intermediate" ]
                    , option [ value "Advanced" ] [ text "Advanced" ]
                    ]
                ]

            , div [ class "space-y-2" ]
                [ label [ for "gameName", class "block text-sm font-medium text-gray-700" ] [ text "Game Name:" ]
                , if model.gameLevel == "" then
                    div [ class "mt-1 p-2 bg-gray-100 border border-gray-300 rounded-md text-sm text-gray-500" ]
                        [ text "Please select a game level first" ]
                  else
                    select
                        [ id "gameName"
                        , onInput UpdateGameName
                        , value model.gameName
                        , class "mt-1 block w-full bg-white border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        ([ option [ value "" ] [ text "-- Select Game --" ] ] ++
                            List.map (\game -> option [ value game ] [ text game ]) gameOptions)
                ]

            , div [ class "space-y-2" ]
                [ label [ for "githubLink", class "block text-sm font-medium text-gray-700" ] [ text "GitHub Repository Link:" ]
                , input
                    [ type_ "url"
                    , id "githubLink"
                    , value model.githubLink
                    , onInput UpdateGithubLink
                    , placeholder "https://github.com/username/repository"
                    , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    []
                ]

            , div [ class "space-y-2" ]
                [ label [ for "notes", class "block text-sm font-medium text-gray-700" ] [ text "Additional Notes:" ]
                , textarea
                    [ id "notes"
                    , value model.notes
                    , onInput UpdateNotes
                    , placeholder "Provide any additional information about your game project"
                    , rows 5
                    , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    []
                ]
            ]

        , div [ class "flex space-x-4 mt-6" ]
            [ button
                [ onClick BackToProfile
                , class "flex-1 py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Back" ]
            , button
                [ onClick (SubmitForm student)
                , class "flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Submit Game" ]
            ]
        ]

viewSubmissionCompletePage : Model -> Student -> Submission -> Html Msg
viewSubmissionCompletePage model student submission =
    div [ class "space-y-6" ]
        [ div [ class "text-center" ]
            [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Submission Successful!" ]
            , p [ class "text-gray-600 mt-2" ] [ text ("Thank you, " ++ student.name ++ "! Your Unity game project has been submitted.") ]
            ]

        , div [ class "mt-6 border rounded-md p-4 bg-gray-50" ]
            [ h3 [ class "text-lg font-medium text-gray-700 mb-3" ] [ text "Submission Details:" ]
            , ul [ class "space-y-2" ]
                [ li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Name: " ]
                    , span [ class "text-gray-600" ] [ text student.name ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Game Level: " ]
                    , span [ class "text-gray-600" ] [ text submission.gameLevel ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Game Name: " ]
                    , span [ class "text-gray-600" ] [ text submission.gameName ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "GitHub Link: " ]
                    , a [ href submission.githubLink, target "_blank", class "text-blue-600 hover:text-blue-800" ] [ text submission.githubLink ]
                    ]
                , li [ class "pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Notes: " ]
                    , span [ class "text-gray-600" ] [ text submission.notes ]
                    ]
                ]
            ]

        , div [ class "flex space-x-4 mt-6" ]
            [ button
                [ onClick BackToProfile
                , class "flex-1 py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Back to Profile" ]
            , button
                [ onClick (StartNewSubmission student)
                , class "flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Submit Another Game" ]
            ]
        ]

viewLoading : String -> Html Msg
viewLoading message =
    div [ class "flex flex-col items-center justify-center py-12" ]
        [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500 mb-4" ] []
        , p [ class "text-gray-600" ] [ text message ]
        ]

viewError : Maybe String -> Html Msg
viewError maybeError =
    case maybeError of
        Just errorMsg ->
            div [ class "mt-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-shrink-0" ]
                        [ span [ class "text-red-400" ] [ text "!" ]
                        ]
                    , div [ class "ml-3" ]
                        [ p [ class "text-sm text-red-700" ] [ text errorMsg ]
                        ]
                    ]
                ]

        Nothing ->
            text ""

viewSuccess : Maybe String -> Html Msg
viewSuccess maybeSuccess =
    case maybeSuccess of
        Just successMsg ->
            div [ class "mt-4 bg-green-50 border-l-4 border-green-400 p-4" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-shrink-0" ]
                        [ span [ class "text-green-400" ] [ text "✓" ]
                        ]
                    , div [ class "ml-3" ]
                        [ p [ class "text-sm text-green-700" ] [ text successMsg ]
                        ]
                    ]
                ]

        Nothing ->
            text ""
