module Admin.Components.Navigation exposing (view)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Shared.Types exposing (User)


view : Model -> User -> Html Msg
view model user =
    div [ class "bg-white shadow-sm border-b border-gray-200 mb-6" ]
        [ -- Top header with user info and sign out
          div [ class "max-w-8xl mx-auto px-4 sm:px-6 lg:px-8" ]
            [ div [ class "flex justify-between items-center py-4" ]
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

            -- Tab navigation
            , div [ class "border-t border-gray-200" ]
                [ nav [ class "max-w-8xl mx-auto px-4 sm:px-6 lg:px-8" ]
                    [ div [ class "-mb-px flex space-x-8" ]
                        [ viewTab "Game Submissions" SubmissionsPage model.page
                        , viewTab "Student Management" StudentManagementPage model.page
                        , viewTab "Belt Management" BeltManagementPage model.page
                        , viewTab "Point System" PointManagementPage model.page
                        , if isSuperUser model then
                            viewTab "Admin Users" AdminUsersPage model.page

                          else
                            text ""
                        ]
                    ]
                ]
            ]
        ]


viewTab : String -> Page -> Page -> Html Msg
viewTab label targetPage currentPage =
    let
        isActive =
            case ( targetPage, currentPage ) of
                ( SubmissionsPage, SubmissionsPage ) ->
                    True

                ( StudentManagementPage, StudentManagementPage ) ->
                    True

                ( StudentManagementPage, StudentRecordPage _ _ ) ->
                    True

                -- Student record is part of student management
                ( BeltManagementPage, BeltManagementPage ) ->
                    True

                ( PointManagementPage, PointManagementPage ) ->
                    True

                ( AdminUsersPage, AdminUsersPage ) ->
                    True

                _ ->
                    False

        baseClass =
            "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm cursor-pointer transition-colors"

        activeClass =
            baseClass ++ " border-blue-500 text-blue-600"

        inactiveClass =
            baseClass ++ " border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"

        clickMsg =
            case targetPage of
                SubmissionsPage ->
                    ShowSubmissionsPage

                StudentManagementPage ->
                    ShowStudentManagementPage

                BeltManagementPage ->
                    ShowBeltManagementPage

                PointManagementPage ->
                    ShowPointManagementPage

                AdminUsersPage ->
                    ShowAdminUsersPage

                _ ->
                    ShowSubmissionsPage

        -- Default fallback
    in
    button
        [ onClick clickMsg
        , class
            (if isActive then
                activeClass

             else
                inactiveClass
            )
        ]
        [ text label ]


isSuperUser : Model -> Bool
isSuperUser model =
    case model.appState of
        Authenticated user ->
            user.role == "superuser"

        _ ->
            False
