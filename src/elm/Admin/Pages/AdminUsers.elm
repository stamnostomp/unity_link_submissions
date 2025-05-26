module Admin.Pages.AdminUsers exposing (update, view)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Shared.Ports as Ports
import Shared.Types exposing (..)
import Shared.Utils exposing (..)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Admin User Form
        ShowAdminUserForm ->
            ( { model | showAdminUserForm = True, adminUserForm = initAdminUserForm }, Cmd.none )

        HideAdminUserForm ->
            ( { model | showAdminUserForm = False }, Cmd.none )

        UpdateAdminUserEmail email ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | email = email }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        UpdateAdminUserPassword password ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | password = password }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        UpdateAdminUserConfirmPassword confirmPassword ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | confirmPassword = confirmPassword }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        UpdateAdminUserDisplayName displayName ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | displayName = displayName }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        UpdateAdminUserRole role ->
            let
                form =
                    model.adminUserForm

                updatedForm =
                    { form | role = role }
            in
            ( { model | adminUserForm = updatedForm }, Cmd.none )

        SubmitAdminUserForm ->
            let
                form =
                    model.adminUserForm

                validationError =
                    if String.isEmpty form.email then
                        Just "Email is required"

                    else if not (String.contains "@" form.email) then
                        Just "Please enter a valid email address"

                    else if String.isEmpty form.password then
                        Just "Password is required"

                    else if String.length form.password < 6 then
                        Just "Password must be at least 6 characters"

                    else if form.password /= form.confirmPassword then
                        Just "Passwords do not match"

                    else
                        Nothing

                updatedForm =
                    { form | formError = validationError }
            in
            case validationError of
                Just _ ->
                    ( { model | adminUserForm = updatedForm }, Cmd.none )

                Nothing ->
                    ( { model | adminUserForm = updatedForm, loading = True }
                    , Ports.createAdminUser { email = form.email, password = form.password, displayName = form.displayName, role = form.role }
                    )

        AdminUserCreated result ->
            case result of
                Ok adminResult ->
                    let
                        message =
                            if adminResult.success then
                                "Success: " ++ adminResult.message

                            else
                                "Error: " ++ adminResult.message
                    in
                    ( { model
                        | adminUserCreationResult = Just message
                        , showAdminUserForm =
                            if adminResult.success then
                                False

                            else
                                model.showAdminUserForm
                        , loading = False
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model | adminUserCreationResult = Just ("Error: " ++ Decode.errorToString error), loading = False }, Cmd.none )

        -- Admin User Management
        RequestAllAdmins ->
            ( { model | loading = True, adminUserDeletionResult = Nothing, adminUserUpdateResult = Nothing }, Ports.requestAllAdmins () )

        ReceiveAllAdmins result ->
            case result of
                Ok adminUsers ->
                    ( { model | adminUsers = adminUsers, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        EditAdminUser adminUser ->
            ( { model | editingAdminUser = Just adminUser }, Cmd.none )

        UpdateEditingAdminUserEmail email ->
            case model.editingAdminUser of
                Just adminUser ->
                    ( { model | editingAdminUser = Just { adminUser | email = email } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateEditingAdminUserDisplayName displayName ->
            case model.editingAdminUser of
                Just adminUser ->
                    ( { model | editingAdminUser = Just { adminUser | displayName = displayName } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateEditingAdminUserRole role ->
            case model.editingAdminUser of
                Just adminUser ->
                    ( { model | editingAdminUser = Just { adminUser | role = role } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveAdminUserEdit ->
            case model.editingAdminUser of
                Just adminUser ->
                    if String.trim adminUser.email == "" then
                        ( { model | error = Just "Email cannot be empty" }, Cmd.none )

                    else if not (String.contains "@" adminUser.email) then
                        ( { model | error = Just "Please enter a valid email address" }, Cmd.none )

                    else
                        ( { model | loading = True, editingAdminUser = Nothing, error = Nothing }, Ports.updateAdminUser (encodeAdminUserUpdate adminUser) )

                Nothing ->
                    ( model, Cmd.none )

        CancelAdminUserEdit ->
            ( { model | editingAdminUser = Nothing, error = Nothing }, Cmd.none )

        AdminUserUpdated result ->
            case result of
                Ok updateResult ->
                    ( { model | loading = False, adminUserUpdateResult = Just updateResult.message }
                    , if updateResult.success then
                        Ports.requestAllAdmins ()

                      else
                        Cmd.none
                    )

                Err error ->
                    ( { model | loading = False, error = Just ("Error updating admin user: " ++ Decode.errorToString error) }, Cmd.none )

        DeleteAdminUser adminUser ->
            ( { model | confirmDeleteAdmin = Just adminUser }, Cmd.none )

        ConfirmDeleteAdminUser adminUser ->
            ( { model | loading = True, confirmDeleteAdmin = Nothing }, Ports.deleteAdminUser adminUser.uid )

        CancelDeleteAdminUser ->
            ( { model | confirmDeleteAdmin = Nothing }, Cmd.none )

        AdminUserDeleted result ->
            case result of
                Ok deleteResult ->
                    ( { model | loading = False, adminUserDeletionResult = Just deleteResult.message }
                    , if deleteResult.success then
                        Ports.requestAllAdmins ()

                      else
                        Cmd.none
                    )

                Err error ->
                    ( { model | loading = False, error = Just ("Error deleting admin user: " ++ Decode.errorToString error) }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "space-y-6" ]
        [ viewHeader
        , viewCreationForm model
        , viewAdminUsersList model
        , viewEditModal model
        , viewConfirmDeleteModal model
        , viewSecurityInfo
        ]


viewHeader : Html Msg
viewHeader =
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ div [ class "flex justify-between items-center" ]
            [ h2 [ class "text-xl font-medium text-gray-900" ] [ text "Admin User Management" ]
            , button [ onClick CloseCurrentPage, class "text-gray-500 hover:text-gray-700 flex items-center" ]
                [ span [ class "mr-1" ] [ text "←" ], text "Back to Submissions" ]
            ]
        ]


viewCreationForm : Model -> Html Msg
viewCreationForm model =
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ viewAdminUserCreationResult model.adminUserCreationResult
        , viewAdminUserUpdateResult model.adminUserUpdateResult
        , viewAdminUserDeletionResult model.adminUserDeletionResult
        , if model.showAdminUserForm then
            viewAdminUserForm model.adminUserForm

          else
            div [ class "text-center py-8" ]
                [ p [ class "text-gray-500 mb-4" ] [ text "Create additional admin users who will have access to this admin dashboard." ]
                , button [ onClick ShowAdminUserForm, class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500" ] [ text "Create New Admin User" ]
                ]
        ]


viewAdminUserForm : AdminUserForm -> Html Msg
viewAdminUserForm form =
    div [ class "bg-white rounded-lg border border-gray-200 overflow-hidden" ]
        [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Create New Admin User" ] ]
        , div [ class "p-6" ]
            [ case form.formError of
                Just error ->
                    div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ] [ p [ class "text-sm text-red-700" ] [ text error ] ]

                Nothing ->
                    text ""
            , div [ class "space-y-4" ]
                [ div []
                    [ label [ for "adminEmail", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Email Address" ]
                    , input [ type_ "email", id "adminEmail", placeholder "admin@example.com", value form.email, onInput UpdateAdminUserEmail, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                    ]
                , div []
                    [ label [ for "adminDisplayName", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Display Name (optional)" ]
                    , input [ type_ "text", id "adminDisplayName", placeholder "Admin User", value form.displayName, onInput UpdateAdminUserDisplayName, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                    ]
                , div []
                    [ label [ for "adminPassword", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Password" ]
                    , input [ type_ "password", id "adminPassword", placeholder "••••••••", value form.password, onInput UpdateAdminUserPassword, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                    , p [ class "mt-1 text-xs text-gray-500" ] [ text "Password must be at least 6 characters" ]
                    ]
                , div []
                    [ label [ for "adminConfirmPassword", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Confirm Password" ]
                    , input [ type_ "password", id "adminConfirmPassword", placeholder "••••••••", value form.confirmPassword, onInput UpdateAdminUserConfirmPassword, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                    ]
                , div []
                    [ label [ for "adminRole", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Role:" ]
                    , select [ id "adminRole", value form.role, onInput UpdateAdminUserRole, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ]
                        [ option [ value "admin" ] [ text "Regular Admin" ]
                        , option [ value "superuser" ] [ text "Superuser" ]
                        ]
                    , p [ class "mt-1 text-xs text-gray-500" ] [ text "Superusers can manage other admin accounts." ]
                    ]
                ]
            , div [ class "mt-6 flex justify-end space-x-3" ]
                [ button [ onClick HideAdminUserForm, class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Cancel" ]
                , button [ onClick SubmitAdminUserForm, class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none" ] [ text "Create Admin User" ]
                ]
            ]
        ]


viewAdminUsersList : Model -> Html Msg
viewAdminUsersList model =
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ div [ class "flex justify-between items-center mb-4" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Current Admin Users" ]
            , button [ onClick RequestAllAdmins, class "px-3 py-1 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Refresh" ]
            ]
        , if model.loading then
            div [ class "flex justify-center my-6" ] [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" ] [] ]

          else if List.isEmpty model.adminUsers then
            div [ class "text-center py-12 bg-gray-50 rounded-lg" ] [ p [ class "text-gray-500" ] [ text "No admin users found. The first admin user may have been created through Firebase directly." ] ]

          else
            div [ class "overflow-x-auto bg-white" ]
                [ table [ class "min-w-full divide-y divide-gray-200" ]
                    [ thead [ class "bg-gray-50" ]
                        [ tr []
                            [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Email" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Display Name" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-20" ] [ text "Role" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Created By" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Created At" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-32" ] [ text "Actions" ]
                            ]
                        ]
                    , tbody [ class "bg-white divide-y divide-gray-200" ] (List.map viewAdminUserRow model.adminUsers)
                    ]
                ]
        ]


viewAdminUserRow : AdminUser -> Html Msg
viewAdminUserRow admin =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm font-medium text-gray-900 truncate max-w-xs" ] [ text admin.email ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm text-gray-500 truncate max-w-xs" ] [ text admin.displayName ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ viewRoleBadge admin.role ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm text-gray-500 truncate max-w-xs" ] [ text (Maybe.withDefault "Unknown" admin.createdBy) ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm text-gray-500" ] [ text (formatDate (Maybe.withDefault "Unknown" admin.createdAt)) ] ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium" ]
            [ div [ class "flex space-x-2" ]
                [ button [ onClick (EditAdminUser admin), class "flex-1 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center" ] [ text "Edit" ]
                , button [ onClick (DeleteAdminUser admin), class "flex-1 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center" ] [ text "Delete" ]
                ]
            ]
        ]


viewRoleBadge : String -> Html Msg
viewRoleBadge role =
    let
        ( bgColor, textColor ) =
            if role == "superuser" then
                ( "bg-purple-100", "text-purple-800" )

            else
                ( "bg-blue-100", "text-blue-800" )
    in
    span [ class ("inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium " ++ bgColor ++ " " ++ textColor) ] [ text role ]


viewEditModal : Model -> Html Msg
viewEditModal model =
    case model.editingAdminUser of
        Just adminUser ->
            div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
                [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                    [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
                        [ h2 [ class "text-lg font-medium text-gray-900" ] [ text ("Edit Admin User: " ++ adminUser.email) ] ]
                    , div [ class "p-6" ]
                        [ div [ class "space-y-4" ]
                            [ div []
                                [ label [ for "adminEmail", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Email Address" ]
                                , input [ type_ "email", id "adminEmail", placeholder "admin@example.com", value adminUser.email, onInput UpdateEditingAdminUserEmail, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                                ]
                            , div []
                                [ label [ for "adminDisplayName", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Display Name" ]
                                , input [ type_ "text", id "adminDisplayName", placeholder "Admin User", value adminUser.displayName, onInput UpdateEditingAdminUserDisplayName, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                                ]
                            , div []
                                [ label [ for "editAdminRole", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Role:" ]
                                , div [ class "mb-2 text-xs text-gray-500" ] [ text ("Current role: " ++ adminUser.role) ]
                                , select [ id "editAdminRole", value adminUser.role, onInput UpdateEditingAdminUserRole, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ]
                                    [ option [ value "admin" ] [ text "Regular Admin" ]
                                    , option [ value "superuser" ] [ text "Superuser" ]
                                    ]
                                , p [ class "mt-1 text-xs text-gray-500" ] [ text "Only superusers can manage other admin accounts" ]
                                ]
                            , div [ class "pt-2 flex justify-end space-x-3" ]
                                [ button [ onClick CancelAdminUserEdit, class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Cancel" ]
                                , button [ onClick SaveAdminUserEdit, class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none" ] [ text "Save Changes" ]
                                ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""


viewConfirmDeleteModal : Model -> Html Msg
viewConfirmDeleteModal model =
    case model.confirmDeleteAdmin of
        Just adminUser ->
            div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
                [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                    [ div [ class "px-6 py-4 bg-red-50 border-b border-gray-200" ]
                        [ h2 [ class "text-lg font-medium text-red-700" ] [ text "Confirm Delete" ] ]
                    , div [ class "p-6" ]
                        [ p [ class "mb-4 text-gray-700" ] [ text ("Are you sure you want to delete the admin user " ++ adminUser.email ++ "?") ]
                        , p [ class "mb-6 text-red-600 font-medium" ] [ text "This action cannot be undone and will revoke this user's access to the admin panel." ]
                        , div [ class "flex justify-end space-x-3" ]
                            [ button [ onClick CancelDeleteAdminUser, class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Cancel" ]
                            , button [ onClick (ConfirmDeleteAdminUser adminUser), class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none" ] [ text "Delete Admin User" ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""


viewSecurityInfo : Html Msg
viewSecurityInfo =
    div [ class "bg-yellow-50 shadow rounded-lg p-6 border-l-4 border-yellow-400" ]
        [ h3 [ class "text-lg font-medium text-yellow-800 mb-2" ] [ text "Security Information" ]
        , p [ class "text-yellow-700 mb-2" ] [ text "All admin users have full access to the system. Only create accounts for trusted instructors who need to manage student submissions and belt progression." ]
        , p [ class "text-yellow-700" ] [ text "Admin users will be able to:" ]
        , ul [ class "list-disc list-inside text-yellow-700 mt-2 ml-4 space-y-1" ]
            [ li [] [ text "Grade student submissions" ]
            , li [] [ text "Manage belt progression levels" ]
            , li [] [ text "Create and manage student accounts" ]
            , li [] [ text "Create other admin users" ]
            ]
        ]



-- Helper view functions


viewAdminUserCreationResult : Maybe String -> Html Msg
viewAdminUserCreationResult maybeResult =
    case maybeResult of
        Just result ->
            if String.startsWith "Success" result then
                div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ] [ p [ class "text-sm text-green-700" ] [ text result ] ]

            else
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ] [ p [ class "text-sm text-red-700" ] [ text result ] ]

        Nothing ->
            text ""


viewAdminUserUpdateResult : Maybe String -> Html Msg
viewAdminUserUpdateResult maybeResult =
    case maybeResult of
        Just result ->
            if String.startsWith "Success" result then
                div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ] [ p [ class "text-sm text-green-700" ] [ text result ] ]

            else
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ] [ p [ class "text-sm text-red-700" ] [ text result ] ]

        Nothing ->
            text ""


viewAdminUserDeletionResult : Maybe String -> Html Msg
viewAdminUserDeletionResult maybeResult =
    case maybeResult of
        Just result ->
            if String.startsWith "Success" result then
                div [ class "mb-4 bg-green-50 border-l-4 border-green-400 p-4" ] [ p [ class "text-sm text-green-700" ] [ text result ] ]

            else
                div [ class "mb-4 bg-red-50 border-l-4 border-red-400 p-4" ] [ p [ class "text-sm text-red-700" ] [ text result ] ]

        Nothing ->
            text ""
