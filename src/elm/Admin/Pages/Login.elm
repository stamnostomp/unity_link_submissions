module Admin.Pages.Login exposing (view)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


view : Model -> Html Msg
view model =
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
        , viewPasswordResetModal model
        ]


viewPasswordResetModal : Model -> Html Msg
viewPasswordResetModal model =
    if model.showPasswordReset then
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
