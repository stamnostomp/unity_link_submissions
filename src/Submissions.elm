port module Submissions exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode
import Dict exposing (Dict)
import Task
import Process


-- PORTS for JavaScript interop

port saveToFirebase : Encode.Value -> Cmd msg
port firebaseSaveResult : (String -> msg) -> Sub msg


-- MAIN

main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    firebaseSaveResult FirebaseResult


-- MODEL

type Page
    = NamePage
    | SubmissionPage
    | ConfirmationPage
    | SavingPage

type alias Model =
    { page : Page
    , studentName : String
    , gameLevel : String
    , gameName : String
    , githubLink : String
    , notes : String
    , errorMessage : Maybe String
    , jsonOutput : String
    , saveStatus : Maybe String
    }

init : () -> ( Model, Cmd Msg )
init _ =
    ( { page = NamePage
      , studentName = ""
      , gameLevel = ""
      , gameName = ""
      , githubLink = ""
      , notes = ""
      , errorMessage = Nothing
      , jsonOutput = ""
      , saveStatus = Nothing
      }
    , Cmd.none
    )


-- GAME OPTIONS BY LEVEL

gameOptionsByLevel : Dict String (List String)
gameOptionsByLevel =
    Dict.fromList
        [ ( "Beginner", [ "Game 1", "Game 2", "Game 3" ] )
        , ( "Intermediate", [ "Game A", "Game B", "Game C" ] )
        , ( "Advanced", [ "Game 4", "Game 5", "Game 6" ] )
        ]

getGameOptions : String -> List String
getGameOptions level =
    Dict.get level gameOptionsByLevel
        |> Maybe.withDefault []


-- UPDATE

type Msg
    = UpdateName String
    | UpdateGameLevel String
    | UpdateGameName String
    | UpdateGithubLink String
    | UpdateNotes String
    | SubmitName
    | SubmitForm
    | SaveToFirebase
    | FirebaseResult String
    | BackToName
    | Reset

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateName name ->
            ( { model | studentName = name }, Cmd.none )

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

        SubmitName ->
            if String.trim model.studentName == "" then
                ( { model | errorMessage = Just "Please enter your name to continue" }, Cmd.none )
            else
                ( { model | page = SubmissionPage, errorMessage = Nothing }, Cmd.none )

        SubmitForm ->
            if String.trim model.gameLevel == "" || String.trim model.gameName == "" || String.trim model.githubLink == "" then
                ( { model | errorMessage = Just "Please fill in all required fields" }, Cmd.none )
            else
                let
                    jsonOutput =
                        encodeSubmission model |> Encode.encode 2
                in
                ( { model
                  | page = SavingPage
                  , jsonOutput = jsonOutput
                  , errorMessage = Nothing
                  , saveStatus = Just "Saving your submission..."
                  }
                , Process.sleep 500
                    |> Task.perform (\_ -> SaveToFirebase)
                )

        SaveToFirebase ->
            ( model
            , saveToFirebase (encodeSubmission model)
            )

        FirebaseResult result ->
            if String.startsWith "Error:" result then
                ( { model
                  | page = SubmissionPage
                  , errorMessage = Just result
                  , saveStatus = Just "Failed to save"
                  }
                , Cmd.none
                )
            else
                ( { model
                  | page = ConfirmationPage
                  , saveStatus = Just "Successfully saved to Firebase"
                  }
                , Cmd.none
                )

        BackToName ->
            ( { model | page = NamePage }, Cmd.none )

        Reset ->
            init ()


-- JSON ENCODING

encodeSubmission : Model -> Encode.Value
encodeSubmission model =
    Encode.object
        [ ( "studentName", Encode.string model.studentName )
        , ( "gameLevel", Encode.string model.gameLevel )
        , ( "gameName", Encode.string model.gameName )
        , ( "githubLink", Encode.string model.githubLink )
        , ( "notes", Encode.string model.notes )
        , ( "submissionDate", Encode.string "2025-03-03" )  -- Current date hardcoded for example
        , ( "submissionId", Encode.string (model.studentName ++ "-" ++ String.fromInt (String.length model.studentName + String.length model.gameName)) )
        ]


-- VIEW

view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-gray-100 py-6 flex flex-col justify-center sm:py-12" ]
        [ div [ class "relative py-3 sm:max-w-xl sm:mx-auto" ]
            [ div [ class "absolute inset-0 bg-gradient-to-r from-blue-400 to-blue-600 shadow-lg transform -skew-y-6 sm:skew-y-0 sm:-rotate-6 sm:rounded-lg" ] []
            , div [ class "relative px-4 py-10 bg-white shadow-lg sm:rounded-lg sm:p-20" ]
                [ div [ class "max-w-md mx-auto" ]
                    [ h1 [ class "text-2xl font-semibold text-center text-gray-800 mb-6" ] [ text "Unity Game Submission" ]
                    , viewPage model
                    , viewError model.errorMessage
                    ]
                ]
            ]
        ]

viewPage : Model -> Html Msg
viewPage model =
    case model.page of
        NamePage ->
            viewNamePage model

        SubmissionPage ->
            viewSubmissionPage model

        SavingPage ->
            viewSavingPage model

        ConfirmationPage ->
            viewConfirmationPage model

viewNamePage : Model -> Html Msg
viewNamePage model =
    div [ class "space-y-6" ]
        [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Welcome!" ]
        , p [ class "text-gray-600" ] [ text "Please enter your name to begin the submission process." ]
        , div [ class "space-y-2" ]
            [ label [ for "studentName", class "block text-sm font-medium text-gray-700" ] [ text "Full Name:" ]
            , input
                [ type_ "text"
                , id "studentName"
                , value model.studentName
                , onInput UpdateName
                , placeholder "Enter your full name"
                , autofocus True
                , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                ]
                []
            ]
        , button
            [ onClick SubmitName
            , class "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            ]
            [ text "Continue" ]
        ]

viewSubmissionPage : Model -> Html Msg
viewSubmissionPage model =
    let
        gameOptions = getGameOptions model.gameLevel
    in
    div [ class "space-y-6" ]
        [ h2 [ class "text-xl font-medium text-gray-700" ] [ text ("Hello, " ++ model.studentName ++ "!") ]
        , p [ class "text-gray-600" ] [ text "Please provide details about your Unity game submission." ]

        , div [ class "space-y-2" ]
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

        , div [ class "flex space-x-4" ]
            [ button
                [ onClick BackToName
                , class "flex-1 py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Back" ]
            , button
                [ onClick SubmitForm
                , class "flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Submit" ]
            ]
        ]

viewSavingPage : Model -> Html Msg
viewSavingPage model =
    div [ class "space-y-6 text-center" ]
        [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Saving Your Submission" ]
        , div [ class "flex justify-center my-6" ]
            [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" ] [] ]
        , p [ class "text-gray-600" ]
            [ text (model.saveStatus |> Maybe.withDefault "Processing your submission...") ]
        ]

viewConfirmationPage : Model -> Html Msg
viewConfirmationPage model =
    div [ class "space-y-6" ]
        [ div [ class "text-center" ]
            [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Submission Successful!" ]
            , p [ class "text-gray-600 mt-2" ] [ text ("Thank you, " ++ model.studentName ++ "! Your Unity game project has been submitted.") ]
            , div [ class "mt-2 inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800" ]
                [ text "✓ Saved to Firebase" ]
            ]

        , div [ class "mt-6 border rounded-md p-4 bg-gray-50" ]
            [ h3 [ class "text-lg font-medium text-gray-700 mb-3" ] [ text "Submission Details:" ]
            , ul [ class "space-y-2" ]
                [ li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Name: " ]
                    , span [ class "text-gray-600" ] [ text model.studentName ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Game Level: " ]
                    , span [ class "text-gray-600" ] [ text model.gameLevel ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Game Name: " ]
                    , span [ class "text-gray-600" ] [ text model.gameName ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "GitHub Link: " ]
                    , a [ href model.githubLink, target "_blank", class "text-blue-600 hover:text-blue-800" ] [ text model.githubLink ]
                    ]
                , li [ class "pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Notes: " ]
                    , span [ class "text-gray-600" ] [ text model.notes ]
                    ]
                ]
            ]

        , div [ class "mt-6 border rounded-md overflow-hidden" ]
            [ div [ class "bg-gray-100 px-4 py-2 border-b" ]
                [ h3 [ class "text-lg font-medium text-gray-700" ] [ text "JSON Output:" ] ]
            , pre [ class "p-4 bg-gray-800 text-green-400 overflow-x-auto text-sm" ]
                [ text model.jsonOutput ]
            , p [ class "px-4 py-2 text-xs text-gray-500 bg-gray-100 border-t" ]
                [ text "This data has been saved to your Firebase database." ]
            ]

        , button
            [ onClick Reset
            , class "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            ]
            [ text "Submit Another Project" ]
        ]

viewError : Maybe String -> Html Msg
viewError maybeError =
    case maybeError of
        Just errorMsg ->
            div [ class "mt-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-shrink-0" ]
                        [ -- This would normally be an SVG icon, but we're using text for simplicity
                          span [ class "text-red-400" ] [ text "!" ]
                        ]
                    , div [ class "ml-3" ]
                        [ p [ class "text-sm text-red-700" ] [ text errorMsg ]
                        ]
                    ]
                ]

        Nothing ->
            text ""
