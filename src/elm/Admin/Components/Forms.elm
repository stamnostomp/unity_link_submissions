module Admin.Components.Forms exposing (..)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Shared.Utils exposing (..)


viewCreateStudentForm : Model -> Html Msg
viewCreateStudentForm model =
    div [ class "space-y-2" ]
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
        , p [ class "text-sm text-gray-500 mt-1" ] [ text "Name must be in format: firstname.lastname" ]
        , div [ class "mt-6" ]
            [ button
                [ onClick CreateNewStudent
                , class "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Create Student Record" ]
            ]
        ]
