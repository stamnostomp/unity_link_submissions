module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode


-- MAIN

main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


-- MODEL

type Page
    = NamePage
    | SubmissionPage
    | ConfirmationPage

type alias Model =
    { page : Page
    , studentName : String
    , gameLevel : String
    , gameName : String
    , githubLink : String
    , notes : String
    , errorMessage : Maybe String
    , jsonOutput : String
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
      }
    , Cmd.none
    )


-- UPDATE

type Msg
    = UpdateName String
    | UpdateGameLevel String
    | UpdateGameName String
    | UpdateGithubLink String
    | UpdateNotes String
    | SubmitName
    | SubmitForm
    | BackToName
    | Reset

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateName name ->
            ( { model | studentName = name }, Cmd.none )

        UpdateGameLevel level ->
            ( { model | gameLevel = level }, Cmd.none )

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
                ( { model | page = ConfirmationPage, jsonOutput = jsonOutput, errorMessage = Nothing }, Cmd.none )

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
            , input
                [ type_ "text"
                , id "gameName"
                , value model.gameName
                , onInput UpdateGameName
                , placeholder "Enter your game's name"
                , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                ]
                []
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

viewConfirmationPage : Model -> Html Msg
viewConfirmationPage model =
    div [ class "space-y-6" ]
        [ div [ class "text-center" ]
            [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Submission Successful!" ]
            , p [ class "text-gray-600 mt-2" ] [ text ("Thank you, " ++ model.studentName ++ "! Your Unity game project has been submitted.") ]
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
                [ text "Note: In a production environment, this data would be saved to a server or file." ]
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
