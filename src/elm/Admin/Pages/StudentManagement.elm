module Admin.Pages.StudentManagement exposing (update, view)

import Admin.Components.Forms as Forms
import Admin.Components.Modals as Modals
import Admin.Components.Tables as Tables
import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Shared.Ports as Ports
import Shared.Types exposing (..)
import Shared.Utils exposing (..)



-- UPDATE (extracted from lines ~400-600 in original Admin.elm)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Note: ViewStudentRecord is now handled in Admin.Main.elm
        -- Note: ReceivedStudentRecord is now handled in Admin.Main.elm
        -- Note: CloseStudentRecord is now handled in Admin.Main.elm
        UpdateNewStudentName name ->
            ( { model | newStudentName = name }, Cmd.none )

        CreateNewStudent ->
            let
                trimmedName =
                    String.trim model.newStudentName
            in
            if String.isEmpty trimmedName then
                ( { model | error = Just "Please enter a student name" }, Cmd.none )

            else if not (isValidNameFormat trimmedName) then
                ( { model | error = Just "Please enter the name in the format firstname.lastname (e.g., tyler.smith)" }, Cmd.none )

            else
                ( { model | loading = True, error = Nothing }
                , Ports.createStudent (encodeNewStudent trimmedName)
                )

        StudentCreated result ->
            case result of
                Ok student ->
                    ( { model
                        | page = StudentRecordPage student []
                        , loading = False
                        , success = Just ("Student record for " ++ student.name ++ " created successfully")
                        , currentStudent = Just student
                        , studentSubmissions = []
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error creating student: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        RequestAllStudents ->
            ( { model | loading = True }, Ports.requestAllStudents () )

        ReceiveAllStudents result ->
            case result of
                Ok students ->
                    ( { model | students = students, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        UpdateStudentFilterText text ->
            ( { model | studentFilterText = text }, Cmd.none )

        UpdateStudentSortBy sortBy ->
            ( { model | studentSortBy = sortBy }, Cmd.none )

        ToggleStudentSortDirection ->
            let
                newDirection =
                    case model.studentSortDirection of
                        Ascending ->
                            Descending

                        Descending ->
                            Ascending
            in
            ( { model | studentSortDirection = newDirection }, Cmd.none )

        EditStudent student ->
            ( { model | editingStudent = Just student }, Cmd.none )

        UpdateEditingStudentName name ->
            case model.editingStudent of
                Just student ->
                    let
                        updatedStudent =
                            { student | name = name }
                    in
                    ( { model | editingStudent = Just updatedStudent }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveStudentEdit ->
            case model.editingStudent of
                Just student ->
                    if String.trim student.name == "" then
                        ( { model | error = Just "Please enter a student name" }, Cmd.none )

                    else if not (isValidNameFormat student.name) then
                        ( { model | error = Just "Please enter the name in the format firstname.lastname" }, Cmd.none )

                    else
                        ( { model | loading = True, error = Nothing, editingStudent = Nothing }
                        , Ports.updateStudent (encodeStudentUpdate student)
                        )

                Nothing ->
                    ( model, Cmd.none )

        CancelStudentEdit ->
            ( { model | editingStudent = Nothing, error = Nothing }, Cmd.none )

        DeleteStudent student ->
            ( { model | confirmDeleteStudent = Just student }, Cmd.none )

        ConfirmDeleteStudent student ->
            ( { model | loading = True, confirmDeleteStudent = Nothing }
            , Ports.deleteStudent student.id
            )

        CancelDeleteStudent ->
            ( { model | confirmDeleteStudent = Nothing }, Cmd.none )

        StudentUpdated result ->
            case result of
                Ok student ->
                    let
                        updatedStudents =
                            List.map
                                (\s ->
                                    if s.id == student.id then
                                        student

                                    else
                                        s
                                )
                                model.students
                    in
                    ( { model
                        | loading = False
                        , success = Just ("Student " ++ student.name ++ " updated successfully")
                        , students = updatedStudents
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error updating student: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        StudentDeleted result ->
            case result of
                Ok studentId ->
                    let
                        updatedStudents =
                            List.filter (\s -> s.id /= studentId) model.students
                    in
                    ( { model
                        | loading = False
                        , success = Just "Student deleted successfully"
                        , students = updatedStudents
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error deleting student: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        -- Don't handle other messages
        _ ->
            ( model, Cmd.none )



-- VIEW (extracted from lines ~800-1200 in original Admin.elm)


view : Model -> Html Msg
view model =
    case model.page of
        StudentManagementPage ->
            viewStudentManagementPage model

        StudentRecordPage student submissions ->
            viewStudentRecordPage model student submissions

        _ ->
            text ""


viewStudentManagementPage : Model -> Html Msg
viewStudentManagementPage model =
    div [ class "space-y-6" ]
        [ div [ class "bg-white shadow rounded-lg p-6" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-900" ]
                    [ text "Student Management" ]

                -- Remove the "Back to Submissions" button since we now have tabs
                ]
            , div [ class "mt-6 space-y-6" ]
                [ Forms.viewCreateStudentForm model
                ]
            ]
        , Tables.viewStudentDirectoryTable model
        , Modals.viewEditStudentModal model
        , Modals.viewConfirmDeleteStudentModal model
        ]


viewStudentRecordPage : Model -> Student -> List Submission -> Html Msg
viewStudentRecordPage model student submissions =
    div [ class "space-y-6" ]
        [ div [ class "bg-white shadow rounded-lg p-6" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-900" ]
                    [ text ("Student Record: " ++ formatDisplayName student.name) ]
                , button
                    [ onClick CloseStudentRecord
                    , class "text-gray-500 hover:text-gray-700 flex items-center"
                    ]
                    [ span [ class "mr-1" ] [ text "←" ]
                    , text "Back to Student Management"
                    ]
                ]
            , div [ class "mt-4 grid grid-cols-1 md:grid-cols-3 gap-4" ]
                [ div [ class "bg-gray-50 p-4 rounded-md" ]
                    [ h3 [ class "text-sm font-medium text-gray-700" ] [ text "Student ID" ]
                    , p [ class "mt-1 text-lg" ] [ text student.id ]
                    ]
                , div [ class "bg-gray-50 p-4 rounded-md" ]
                    [ h3 [ class "text-sm font-medium text-gray-700" ] [ text "Joined" ]
                    , p [ class "mt-1 text-lg" ] [ text student.created ]
                    ]
                , div [ class "bg-gray-50 p-4 rounded-md" ]
                    [ h3 [ class "text-sm font-medium text-gray-700" ] [ text "Last Active" ]
                    , p [ class "mt-1 text-lg" ] [ text student.lastActive ]
                    ]
                ]
            ]
        , Tables.viewStudentSubmissionsTable submissions
        ]



-- HELPER FUNCTIONS (extracted from original Admin.elm)


applyStudentFilters : Model -> List Student
applyStudentFilters model =
    model.students
        |> List.filter (filterStudentByText model.studentFilterText)
        |> sortStudents model.studentSortBy model.studentSortDirection


filterStudentByText : String -> Student -> Bool
filterStudentByText filterText student =
    if String.isEmpty filterText then
        True

    else
        let
            lowercaseFilter =
                String.toLower filterText

            containsFilter text =
                String.contains lowercaseFilter (String.toLower text)
        in
        containsFilter student.name || containsFilter student.id


sortStudents : StudentSortBy -> SortDirection -> List Student -> List Student
sortStudents sortBy direction students =
    let
        sortFunction =
            case sortBy of
                ByStudentName ->
                    \a b -> compare a.name b.name

                ByStudentCreated ->
                    \a b -> compare a.created b.created

                ByStudentLastActive ->
                    \a b -> compare a.lastActive b.lastActive

        sortedList =
            List.sortWith sortFunction students
    in
    case direction of
        Ascending ->
            sortedList

        Descending ->
            List.reverse sortedList


getStudentSortButtonClass : Model -> StudentSortBy -> String
getStudentSortButtonClass model sortType =
    let
        baseClass =
            "px-3 py-1 rounded text-sm"
    in
    if model.studentSortBy == sortType then
        baseClass ++ " bg-blue-100 text-blue-800 font-medium"

    else
        baseClass ++ " text-gray-600 hover:bg-gray-100"



-- ENCODERS (extracted from original Admin.elm)


encodeNewStudent : String -> Encode.Value
encodeNewStudent name =
    Encode.object
        [ ( "name", Encode.string name ) ]


encodeStudentUpdate : Student -> Encode.Value
encodeStudentUpdate student =
    Encode.object
        [ ( "id", Encode.string student.id )
        , ( "name", Encode.string student.name )
        ]
