module Admin.Components.Modals exposing (..)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Shared.Types exposing (..)
import Shared.Utils exposing (..)


viewSubmissionGradingModal : Model -> Submission -> Html Msg
viewSubmissionGradingModal model submission =
    div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
        [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-4xl w-full m-4 max-h-[90vh] flex flex-col" ]
            [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200 flex justify-between items-center" ]
                [ h2 [ class "text-lg font-medium text-gray-900" ] [ text (submission.studentName ++ "'s Submission") ]
                , button [ onClick CloseSubmission, class "text-gray-400 hover:text-gray-500" ] [ text "×" ]
                ]
            , div [ class "px-6 py-2 bg-blue-50 border-b border-gray-200" ]
                [ button [ onClick (ViewStudentRecord submission.studentId), class "text-sm text-blue-600 hover:text-blue-800" ]
                    [ text ("View all submissions for " ++ submission.studentName) ]
                ]
            , div [ class "p-6 overflow-y-auto flex-grow" ]
                [ div [ class "grid grid-cols-1 md:grid-cols-2 gap-6" ]
                    [ viewSubmissionDetails submission
                    , viewCurrentGrade submission
                    , viewGradingForm model submission
                    ]
                ]
            , div [ class "px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end" ]
                [ button [ onClick CloseSubmission, class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500" ] [ text "Close" ] ]
            ]
        ]


viewSubmissionDetails : Submission -> Html Msg
viewSubmissionDetails submission =
    div [ class "space-y-6" ]
        [ div []
            [ h3 [ class "text-lg font-medium text-gray-900 mb-3" ] [ text "Submission Details" ]
            , div [ class "bg-gray-50 rounded-lg p-4 space-y-3" ]
                [ div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Student Name:" ], p [ class "mt-1 text-sm text-gray-900" ] [ text submission.studentName ] ]
                , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Student ID:" ], p [ class "mt-1 text-sm text-gray-900" ] [ text submission.studentId ] ]
                , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Belt Level:" ], p [ class "mt-1 text-sm text-gray-900" ] [ text submission.beltLevel ] ]
                , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Game Name:" ], p [ class "mt-1 text-sm text-gray-900" ] [ text submission.gameName ] ]
                , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Submission Date:" ], p [ class "mt-1 text-sm text-gray-900" ] [ text submission.submissionDate ] ]
                , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "GitHub Repository:" ], p [ class "mt-1 text-sm text-gray-900" ] [ a [ href submission.githubLink, target "_blank", class "text-blue-600 hover:text-blue-800 hover:underline" ] [ text submission.githubLink ] ] ]
                , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Notes:" ], p [ class "mt-1 text-sm text-gray-900 whitespace-pre-line" ] [ text submission.notes ] ]
                ]
            ]
        ]


viewCurrentGrade : Submission -> Html Msg
viewCurrentGrade submission =
    div []
        [ h3 [ class "text-lg font-medium text-gray-900 mb-3" ] [ text "Current Grade" ]
        , case submission.grade of
            Just grade ->
                div [ class "bg-gray-50 rounded-lg p-4 space-y-3" ]
                    [ div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Score:" ], p [ class "mt-1 text-lg font-bold text-gray-900" ] [ text (String.fromInt grade.score ++ "/100") ] ]
                    , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Feedback:" ], p [ class "mt-1 text-sm text-gray-900 whitespace-pre-line" ] [ text grade.feedback ] ]
                    , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Graded By:" ], p [ class "mt-1 text-sm text-gray-900" ] [ text grade.gradedBy ] ]
                    , div [] [ label [ class "block text-sm font-medium text-gray-700" ] [ text "Grading Date:" ], p [ class "mt-1 text-sm text-gray-900" ] [ text grade.gradingDate ] ]
                    ]

            Nothing ->
                div [ class "bg-gray-50 rounded-lg p-4 flex justify-center" ] [ p [ class "text-gray-500 italic" ] [ text "This submission has not been graded yet." ] ]
        ]


viewGradingForm : Model -> Submission -> Html Msg
viewGradingForm model submission =
    div [ class "space-y-6" ]
        [ div []
            [ h3 [ class "text-lg font-medium text-gray-900 mb-3" ]
                [ text
                    (if submission.grade == Nothing then
                        "Add Grade"

                     else
                        "Update Grade"
                    )
                ]
            , div [ class "bg-gray-50 rounded-lg p-4 space-y-4" ]
                [ div []
                    [ label [ for "scoreInput", class "block text-sm font-medium text-gray-700" ] [ text "Score (0-100):" ]
                    , input [ type_ "number", id "scoreInput", Html.Attributes.min "0", Html.Attributes.max "100", value model.tempScore, onInput UpdateTempScore, class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                    ]
                , div []
                    [ label [ for "feedbackInput", class "block text-sm font-medium text-gray-700" ] [ text "Feedback:" ]
                    , textarea [ id "feedbackInput", value model.tempFeedback, onInput UpdateTempFeedback, rows 6, placeholder "Provide feedback on the game submission...", class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                    ]
                , button [ onClick SubmitGrade, class "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500" ]
                    [ text
                        (if submission.grade == Nothing then
                            "Submit Grade"

                         else
                            "Update Grade"
                        )
                    ]
                ]
            ]
        ]


viewConfirmDeleteSubmissionModal : Submission -> Html Msg
viewConfirmDeleteSubmissionModal submission =
    div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
        [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
            [ div [ class "px-6 py-4 bg-red-50 border-b border-gray-200" ] [ h2 [ class "text-lg font-medium text-red-700" ] [ text "Confirm Delete" ] ]
            , div [ class "p-6" ]
                [ p [ class "mb-6 text-gray-700" ] [ text ("Are you sure you want to delete the submission for " ++ formatDisplayName submission.studentName ++ "'s " ++ submission.gameName ++ "? This action cannot be undone.") ]
                , div [ class "flex justify-end space-x-3" ]
                    [ button [ onClick CancelDeleteSubmission, class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Cancel" ]
                    , button [ onClick (ConfirmDeleteSubmission submission), class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none" ] [ text "Delete Submission" ]
                    ]
                ]
            ]
        ]


viewEditStudentModal : Model -> Html Msg
viewEditStudentModal model =
    case model.editingStudent of
        Just student ->
            div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
                [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                    [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ] [ h2 [ class "text-lg font-medium text-gray-900" ] [ text "Edit Student" ] ]
                    , div [ class "p-6" ]
                        [ div [ class "space-y-4" ]
                            [ div []
                                [ label [ for "editStudentName", class "block text-sm font-medium text-gray-700" ] [ text "Student Name:" ]
                                , input [ type_ "text", id "editStudentName", value student.name, onInput UpdateEditingStudentName, placeholder "firstname.lastname", class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                                , p [ class "text-sm text-gray-500 mt-1" ] [ text "Name must be in format: firstname.lastname" ]
                                ]
                            , div [ class "pt-2 flex justify-end space-x-3" ]
                                [ button [ onClick CancelStudentEdit, class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Cancel" ]
                                , button [ onClick SaveStudentEdit, class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none" ] [ text "Save Changes" ]
                                ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""


viewConfirmDeleteStudentModal : Model -> Html Msg
viewConfirmDeleteStudentModal model =
    case model.confirmDeleteStudent of
        Just student ->
            div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
                [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                    [ div [ class "px-6 py-4 bg-red-50 border-b border-gray-200" ] [ h2 [ class "text-lg font-medium text-red-700" ] [ text "Confirm Delete" ] ]
                    , div [ class "p-6" ]
                        [ p [ class "mb-4 text-gray-700" ] [ text ("Are you sure you want to delete the student record for " ++ formatDisplayName student.name ++ "?") ]
                        , p [ class "mb-6 text-red-600 font-medium" ] [ text "This will permanently delete the student AND all their game submissions. This action cannot be undone." ]
                        , div [ class "flex justify-end space-x-3" ]
                            [ button [ onClick CancelDeleteStudent, class "px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Cancel" ]
                            , button [ onClick (ConfirmDeleteStudent student), class "px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none" ] [ text "Delete Student & Submissions" ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""
