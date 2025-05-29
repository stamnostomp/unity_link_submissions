module Admin.Components.Navigation exposing (view)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Shared.Types exposing (User)


view : Model -> User -> Html Msg
view model user =
    div [ class "bg-white shadow rounded-lg mb-6 p-4 flex justify-between items-center" ]
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
            , button
                [ onClick ShowPointManagementPage
                , class "px-3 py-1 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none"
                ]
                [ text "Point System" ]
            , button
                [ onClick PerformSignOut
                , class "px-3 py-1 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                ]
                [ text "Sign Out" ]
            ]
        ]


isSuperUser : Model -> Bool
isSuperUser model =
    case model.appState of
        Authenticated user ->
            user.role == "superuser"

        _ ->
            False
