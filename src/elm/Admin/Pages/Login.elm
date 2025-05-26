module Admin.Pages.Login exposing (update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode

import Shared.Ports as Ports
import Shared.Utils exposing (encodeCredentials)
import Admin.Types exposing (..)

-- UPDATE
-- MOVE THESE UPDATE CASES FROM YOUR Admin.elm update function:
-- - UpdateLoginEmail
-- - UpdateLoginPassword
-- - SubmitLogin
-- - ShowPasswordReset
-- - HidePasswordReset
-- - UpdatePasswordResetEmail
-- - SubmitPasswordReset
-- - PasswordResetResult

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
                , Ports.signIn (encodeCredentials model.loginEmail model.loginPassword)
                )

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
                ( { model | passwordResetMessage = Nothing, loading = True }
                , Ports.requestPasswordReset model.passwordResetEmail
                )

        PasswordResetResult result ->
            case result of
                Ok resetResult ->
                    ( { model
                      | passwordResetMessage = Just resetResult.message
                      , loading = False
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                      | passwordResetMessage = Just ("Error: " ++ Decode.errorToString error)
                      , loading = False
                      }
                    , Cmd.none
                    )

        _ ->
            ( model, Cmd.none )

-- VIEW
-- MOVE viewLoginForm function from your Admin.elm here
-- (Around lines 800-900)

view : Model -> Html Msg
view model =
    -- COPY YOUR viewLoginForm CONTENT HERE
    div [ class "bg-white shadow rounded-lg max-w-md mx-auto p-6" ]
        [ h2 [ class "text-xl font-medium text-gray-900 mb-6 text-center" ] [ text "Sign in to Admin Panel" ]
        -- ... rest of login form ...
        , viewPasswordResetModal model
        ]

viewPasswordResetModal : Model -> Html Msg
viewPasswordResetModal model =
    -- COPY YOUR PASSWORD RESET MODAL CODE HERE
    text "Password reset modal"
