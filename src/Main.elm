module Main exposing (..)

import Browser
import Html exposing (Html, div, input, button, text, form, label, textarea)
import Html.Attributes exposing (placeholder, type_, value, class)
import Html.Events exposing (onClick, onInput)
import Time exposing (Posix, posixToMillis)
import Task

-- MODEL

type alias Model =
    { name : String
    , link : String
    , notes : String
    , date : String
    , showAdminPage : Bool
    , password : String
    , submissions : List Submission
    }

type alias Submission =
    { name : String
    , link : String
    , notes : String
    , date : String
    , grade : String
    }

init : () -> ( Model, Cmd Msg )
init _ =
    ( { name = ""
      , link = ""
      , notes = ""
      , date = ""
      , showAdminPage = False
      , password = ""
      , submissions = []
      }
    , Cmd.none
    )

-- UPDATE

type Msg
    = UpdateName String
    | UpdateLink String
    | UpdateNotes String
    | Submit
    | ReceiveTime String
    | ToggleAdminPage
    | UpdatePassword String
    | CheckPassword
    | UpdateGrade String String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateName newName ->
            ( { model | name = newName }, Cmd.none )

        UpdateLink newLink ->
            ( { model | link = newLink }, Cmd.none )

        UpdateNotes newNotes ->
            ( { model | notes = newNotes }, Cmd.none )

        Submit ->
            let
                newSubmission =
                    { name = model.name, link = model.link, notes = model.notes, date = model.date, grade = "" }
            in
            ( { model | submissions = newSubmission :: model.submissions }, fetchTime )

        ReceiveTime timeString ->
            ( { model | date = timeString }, Cmd.none )

        ToggleAdminPage ->
            ( { model | showAdminPage = not model.showAdminPage }, Cmd.none )

        UpdatePassword newPassword ->
            ( { model | password = newPassword }, Cmd.none )

        CheckPassword ->
            -- Directly comparing the password in plaintext
            if model.password == "admin123" then
                ( { model | showAdminPage = True }, Cmd.none )
            else
                ( model, Cmd.none )

        UpdateGrade name grade ->
            let
                updatedSubmissions =
                    List.map
                        (\sub -> if sub.name == name then { sub | grade = grade } else sub)
                        model.submissions
            in
            ( { model | submissions = updatedSubmissions }, Cmd.none )

-- FETCH TIME

fetchTime : Cmd Msg
fetchTime =
    Task.perform (posixToMillis >> String.fromInt >> ReceiveTime) Time.now

-- VIEW

view : Model -> Html Msg
view model =
    if model.showAdminPage then
        adminView model
    else
        userView model

userView : Model -> Html Msg
userView model =
    div [ class "flex flex-col items-center justify-center min-h-screen bg-gray-100 p-4" ]
        [ form [ class "bg-white p-6 rounded-lg shadow-md" ]
            [ label [ class "block text-gray-700 text-sm font-bold mb-2" ] [ text "Enter your name:" ]
            , input [ class "border rounded w-full py-2 px-3 text-gray-700", type_ "text", placeholder "Your name", onInput UpdateName, value model.name ] []
            , label [ class "block text-gray-700 text-sm font-bold mb-2 mt-4" ] [ text "Enter a link:" ]
            , input [ class "border rounded w-full py-2 px-3 text-gray-700", type_ "url", placeholder "Enter a link", onInput UpdateLink, value model.link ] []
            , label [ class "block text-gray-700 text-sm font-bold mb-2 mt-4" ] [ text "Notes:" ]
            , textarea [ class "border rounded w-full py-2 px-3 text-gray-700", placeholder "Add notes here...", onInput UpdateNotes, value model.notes ] []
            , button [ class "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mt-4", onClick Submit ] [ text "Submit" ]
            ]
        , button [ class "fixed bottom-4 right-4 bg-gray-800 text-white px-4 py-2 rounded", onClick ToggleAdminPage ] [ text "Admin" ]
        ]

adminView : Model -> Html Msg
adminView model =
    div [ class "flex flex-col items-center justify-center min-h-screen bg-gray-100 p-4" ]
        [ label [ class "block text-gray-700 text-sm font-bold mb-2" ] [ text "Enter Password:" ]
        , input [ class "border rounded w-full py-2 px-3 text-gray-700", type_ "password", placeholder "Password", onInput UpdatePassword, value model.password ] []
        , button [ class "bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded mt-4", onClick CheckPassword ] [ text "Submit" ]
        , if model.showAdminPage then
            div [ class "mt-4 p-4 bg-white rounded-lg shadow-md" ]
                (text "All Submissions Page"
                :: List.map
                    (\sub ->
                        div []
                            [ text ("Name: " ++ sub.name ++ " | Link: " ++ sub.link ++ " | Notes: " ++ sub.notes ++ " | Date: " ++ sub.date ++ " | Grade: " ++ sub.grade)
                            , input [ type_ "text", placeholder "Enter grade", onInput (UpdateGrade sub.name) ] []
                            ]
                    )
                    model.submissions
                )
          else
            text ""
        ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

-- MAIN

main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }
