module Admin.Components.Tables exposing (..)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Shared.Types exposing (..)
import Shared.Utils exposing (..)


viewSubmissionsTable : List Submission -> Html Msg
viewSubmissionsTable submissions =
    div [ class "overflow-x-auto bg-white shadow rounded-lg" ]
        [ table [ class "min-w-full divide-y divide-gray-200" ]
            [ thead [ class "bg-gray-50" ]
                [ tr []
                    [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/5" ] [ text "Student" ] -- Added w-1/5 for 20% width
                    , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/6" ] [ text "Game" ] -- Added w-1/6 for ~16% width
                    , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-24" ] [ text "Belt" ] -- Fixed width for belt
                    , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-32" ] [ text "Submitted" ] -- Fixed width for date
                    , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-24" ] [ text "Grade" ] -- Fixed width for grade
                    , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-80" ] [ text "Actions" ] -- Wider for action buttons
                    ]
                ]
            , tbody [ class "bg-white divide-y divide-gray-200" ]
                (List.map viewSubmissionRow submissions)
            ]
        ]



-- Also update the action buttons in viewSubmissionRow to use better spacing:


viewSubmissionRow : Submission -> Html Msg
viewSubmissionRow submission =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap w-1/5" ]
            -- Match header width
            [ div [ class "text-sm font-medium text-gray-900" ] [ text (formatDisplayName submission.studentName) ]
            , div [ class "text-xs text-gray-500" ] [ text ("ID: " ++ submission.studentId) ]
            ]
        , td [ class "px-6 py-4 whitespace-nowrap w-1/6" ]
            -- Match header width
            [ div [ class "text-sm text-gray-900" ] [ text submission.gameName ] ]
        , td [ class "px-6 py-4 whitespace-nowrap w-24" ]
            -- Match header width
            [ div [ class "text-sm text-gray-900" ] [ text submission.beltLevel ] ]
        , td [ class "px-6 py-4 whitespace-nowrap w-32" ]
            -- Match header width
            [ div [ class "text-sm text-gray-500" ] [ text submission.submissionDate ] ]
        , td [ class "px-6 py-4 whitespace-nowrap w-24" ]
            -- Match header width
            [ viewGradeBadge submission.grade ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium w-80" ]
            -- Match header width
            [ div [ class "flex items-center space-x-2" ]
                -- Better flex layout
                [ button
                    [ onClick (SelectSubmission submission)
                    , class "flex-1 px-3 py-2 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center text-sm" -- Made buttons more flexible
                    ]
                    [ text
                        (if submission.grade == Nothing then
                            "Grade"

                         else
                            "View/Edit"
                        )
                    ]
                , button
                    [ onClick (ViewStudentRecord submission.studentId)
                    , class "flex-1 px-3 py-2 bg-green-100 text-green-700 rounded hover:bg-green-200 transition text-center text-sm"
                    ]
                    [ text "Student" ]
                , button
                    [ onClick (DeleteSubmission submission)
                    , class "flex-1 px-3 py-2 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center text-sm"
                    ]
                    [ text "Delete" ]
                ]
            ]
        ]


viewGradeBadge : Maybe Grade -> Html Msg
viewGradeBadge maybeGrade =
    case maybeGrade of
        Just grade ->
            let
                ( bgColor, textColor ) =
                    if grade.score >= 90 then
                        ( "bg-green-100", "text-green-800" )

                    else if grade.score >= 70 then
                        ( "bg-blue-100", "text-blue-800" )

                    else if grade.score >= 60 then
                        ( "bg-yellow-100", "text-yellow-800" )

                    else
                        ( "bg-red-100", "text-red-800" )
            in
            span [ class ("inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium " ++ bgColor ++ " " ++ textColor) ]
                [ text (String.fromInt grade.score ++ "/100") ]

        Nothing ->
            span [ class "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800" ]
                [ text "Ungraded" ]


viewStudentDirectoryTable : Model -> Html Msg
viewStudentDirectoryTable model =
    div [ class "bg-white shadow rounded-lg p-6 mt-6" ]
        [ h3 [ class "text-lg font-medium text-gray-900 mb-4" ] [ text "Student Directory" ]
        , viewStudentFiltersAndSort model
        , if model.loading then
            div [ class "flex justify-center my-12" ]
                [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" ] [] ]

          else if List.isEmpty (applyStudentFilters model) then
            div [ class "text-center py-12 bg-gray-50 rounded-lg" ]
                [ p [ class "text-gray-500" ] [ text "No students found matching your filters." ] ]

          else
            div [ class "overflow-x-auto bg-white" ]
                [ table [ class "min-w-full divide-y divide-gray-200" ]
                    [ thead [ class "bg-gray-50" ]
                        [ tr []
                            [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Name" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Student ID" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Created" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Last Active" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Actions" ]
                            ]
                        ]
                    , tbody [ class "bg-white divide-y divide-gray-200" ]
                        (List.map viewStudentRow (applyStudentFilters model))
                    ]
                ]
        ]


viewStudentFiltersAndSort : Model -> Html Msg
viewStudentFiltersAndSort model =
    div [ class "mb-4" ]
        [ div [ class "flex items-center justify-between mb-4" ]
            [ div [ class "flex-1 max-w-md" ]
                [ label [ for "studentFilterText", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Search Students" ]
                , input
                    [ type_ "text"
                    , id "studentFilterText"
                    , placeholder "Search by name or ID"
                    , value model.studentFilterText
                    , onInput UpdateStudentFilterText
                    , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    []
                ]
            , div [ class "flex items-center ml-4 self-end" ]
                [ button [ onClick RequestAllStudents, class "flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Refresh" ] ]
            ]
        , div [ class "flex items-center mt-2" ]
            [ span [ class "text-sm text-gray-500 mr-2" ] [ text "Sort by:" ]
            , button [ onClick (UpdateStudentSortBy ByStudentName), class (getStudentSortButtonClass model ByStudentName) ] [ text "Name" ]
            , button [ onClick (UpdateStudentSortBy ByStudentCreated), class (getStudentSortButtonClass model ByStudentCreated) ] [ text "Created" ]
            , button [ onClick (UpdateStudentSortBy ByStudentLastActive), class (getStudentSortButtonClass model ByStudentLastActive) ] [ text "Last Active" ]
            , button [ onClick ToggleStudentSortDirection, class "ml-2 px-2 py-1 rounded text-gray-600 hover:bg-gray-100" ]
                [ text
                    (if model.studentSortDirection == Ascending then
                        "↑"

                     else
                        "↓"
                    )
                ]
            , span [ class "ml-4 text-sm text-gray-500" ] [ text ("Total: " ++ String.fromInt (List.length (applyStudentFilters model)) ++ " students") ]
            ]
        ]


viewStudentRow : Student -> Html Msg
viewStudentRow student =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm font-medium text-gray-900" ] [ text (formatDisplayName student.name) ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm text-gray-500" ] [ text student.id ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm text-gray-500" ] [ text student.created ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm text-gray-500" ] [ text student.lastActive ] ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-2" ]
            [ button [ onClick (ViewStudentRecord student.id), class "w-29 px-2 py-1 bg-green-100 text-green-700 rounded hover:bg-green-200 transition text-center" ] [ text "View Records" ]
            , button [ onClick (EditStudent student), class "w-24 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center" ] [ text "Edit" ]
            , button [ onClick (DeleteStudent student), class "w-24 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center" ] [ text "Delete" ]
            ]
        ]


viewStudentSubmissionsTable : List Submission -> Html Msg
viewStudentSubmissionsTable submissions =
    div [ class "bg-white shadow rounded-lg overflow-hidden" ]
        [ div [ class "px-6 py-4 border-b border-gray-200" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ]
                [ text ("All Submissions (" ++ String.fromInt (List.length submissions) ++ ")") ]
            ]
        , if List.isEmpty submissions then
            div [ class "p-6 text-center" ] [ p [ class "text-gray-500" ] [ text "No submissions found for this student." ] ]

          else
            div [ class "overflow-x-auto" ]
                [ table [ class "min-w-full divide-y divide-gray-200" ]
                    [ thead [ class "bg-gray-50" ]
                        [ tr []
                            [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Game" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Belt" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Submitted" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Grade" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Actions" ]
                            ]
                        ]
                    , tbody [ class "bg-white divide-y divide-gray-200" ] (List.map viewStudentSubmissionRow submissions)
                    ]
                ]
        ]


viewStudentSubmissionRow : Submission -> Html Msg
viewStudentSubmissionRow submission =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm font-medium text-gray-900" ] [ text submission.gameName ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm text-gray-900" ] [ text submission.beltLevel ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ div [ class "text-sm text-gray-500" ] [ text submission.submissionDate ] ]
        , td [ class "px-6 py-4 whitespace-nowrap" ] [ viewGradeBadge submission.grade ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-2" ]
            [ button [ onClick (SelectSubmission submission), class "w-24 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center" ]
                [ text
                    (if submission.grade == Nothing then
                        "Grade"

                     else
                        "View/Edit"
                    )
                ]
            , button [ onClick (DeleteSubmission submission), class "w-24 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center" ] [ text "Delete" ]
            ]
        ]



-- Helper functions


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
