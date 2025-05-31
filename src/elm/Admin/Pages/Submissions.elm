module Admin.Pages.Submissions exposing (update, view)

import Admin.Components.Filters as Filters
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



-- UPDATE (extracted from main Admin.elm update function)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveSubmissions result ->
            case result of
                Ok submissions ->
                    ( { model | submissions = submissions, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        SelectSubmission submission ->
            let
                tempScore =
                    submission.grade
                        |> Maybe.map (\g -> String.fromInt g.score)
                        |> Maybe.withDefault ""

                tempFeedback =
                    submission.grade
                        |> Maybe.map .feedback
                        |> Maybe.withDefault ""
            in
            ( { model
                | currentSubmission = Just submission
                , tempScore = tempScore
                , tempFeedback = tempFeedback
              }
            , Cmd.none
            )

        CloseSubmission ->
            ( { model | currentSubmission = Nothing }, Cmd.none )

        UpdateFilterText text ->
            ( { model | filterText = text }, Cmd.none )

        UpdateFilterBelt belt ->
            let
                filterBelt =
                    if belt == "all" then
                        Nothing

                    else
                        Just belt
            in
            ( { model | filterBelt = filterBelt }, Cmd.none )

        UpdateFilterGraded status ->
            let
                filterGraded =
                    case status of
                        "all" ->
                            Nothing

                        "graded" ->
                            Just True

                        "ungraded" ->
                            Just False

                        _ ->
                            Nothing
            in
            ( { model | filterGraded = filterGraded }, Cmd.none )

        UpdateSortBy sortBy ->
            ( { model | sortBy = sortBy }, Cmd.none )

        ToggleSortDirection ->
            let
                newDirection =
                    case model.sortDirection of
                        Ascending ->
                            Descending

                        Descending ->
                            Ascending
            in
            ( { model | sortDirection = newDirection }, Cmd.none )

        UpdateTempScore score ->
            ( { model | tempScore = score }, Cmd.none )

        UpdateTempFeedback feedback ->
            ( { model | tempFeedback = feedback }, Cmd.none )

        SubmitGrade ->
            case model.currentSubmission of
                Just submission ->
                    let
                        scoreResult =
                            String.toInt model.tempScore
                    in
                    case scoreResult of
                        Just score ->
                            if score < 0 || score > 100 then
                                ( { model | error = Just "Score must be between 0 and 100" }, Cmd.none )

                            else
                                let
                                    grade =
                                        { score = score
                                        , feedback = model.tempFeedback
                                        , gradedBy = getUserEmail model
                                        , gradingDate = "2025-03-03"
                                        }

                                    gradeData =
                                        Encode.object
                                            [ ( "submissionId", Encode.string submission.id )
                                            , ( "grade", encodeGrade grade )
                                            ]
                                in
                                ( { model | loading = True, error = Nothing, success = Nothing }
                                , Ports.saveGrade gradeData
                                )

                        Nothing ->
                            ( { model | error = Just "Please enter a valid score (0-100)" }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        GradeResult result ->
            if String.startsWith "Error:" result then
                ( { model | error = Just result, loading = False, success = Nothing }, Cmd.none )

            else
                ( { model | success = Just "Grade saved successfully", loading = False, error = Nothing }
                , Ports.requestSubmissions ()
                )

        RefreshSubmissions ->
            ( { model | loading = True }, Ports.requestSubmissions () )

        DeleteSubmission submission ->
            ( { model | confirmDeleteSubmission = Just submission }, Cmd.none )

        ConfirmDeleteSubmission submission ->
            ( { model | loading = True, confirmDeleteSubmission = Nothing }
            , Ports.deleteSubmission submission.id
            )

        CancelDeleteSubmission ->
            ( { model | confirmDeleteSubmission = Nothing }, Cmd.none )

        SubmissionDeleted result ->
            case result of
                Ok submissionId ->
                    let
                        updatedSubmissions =
                            List.filter (\s -> s.id /= submissionId) model.submissions
                    in
                    ( { model
                        | loading = False
                        , success = Just "Submission deleted successfully"
                        , submissions = updatedSubmissions
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | loading = False
                        , error = Just ("Error deleting submission: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        -- Don't handle other messages
        _ ->
            ( model, Cmd.none )



-- VIEW (extracted from main Admin.elm view functions)


view : Model -> Html Msg
view model =
    div []
        [ viewFilters model
        , viewSubmissionList model
        , viewSubmissionModal model
        , viewConfirmDeleteSubmissionModal model
        ]


viewFilters : Model -> Html Msg
viewFilters model =
    div [ class "bg-white shadow rounded-lg mb-6 p-4" ]
        [ div [ class "flex items-center justify-between mb-4" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Game Submissions" ]

            -- Remove the management buttons from here since they're now in tabs
            ]
        , Filters.viewSubmissionFilters model
        , Filters.viewSubmissionSort model
        ]


viewSubmissionList : Model -> Html Msg
viewSubmissionList model =
    let
        filteredSubmissions =
            applyFilters model
    in
    if List.isEmpty filteredSubmissions then
        div [ class "text-center py-12 bg-white rounded-lg shadow" ]
            [ p [ class "text-gray-500" ] [ text "No submissions found matching your filters." ] ]

    else
        Tables.viewSubmissionsTable filteredSubmissions


viewSubmissionModal : Model -> Html Msg
viewSubmissionModal model =
    case model.currentSubmission of
        Just submission ->
            Modals.viewSubmissionGradingModal model submission

        Nothing ->
            text ""


viewConfirmDeleteSubmissionModal : Model -> Html Msg
viewConfirmDeleteSubmissionModal model =
    case model.confirmDeleteSubmission of
        Just submission ->
            Modals.viewConfirmDeleteSubmissionModal submission

        Nothing ->
            text ""



-- HELPER FUNCTIONS (extracted from main Admin.elm)


applyFilters : Model -> List Submission
applyFilters model =
    model.submissions
        |> List.filter (filterByText model.filterText)
        |> List.filter (filterByBelt model.filterBelt)
        |> List.filter (filterByGraded model.filterGraded)
        |> sortSubmissions model.sortBy model.sortDirection


filterByText : String -> Submission -> Bool
filterByText filterText submission =
    if String.isEmpty filterText then
        True

    else
        let
            lowercaseFilter =
                String.toLower filterText

            containsFilter text =
                String.contains lowercaseFilter (String.toLower text)
        in
        containsFilter submission.studentName
            || containsFilter submission.gameName
            || containsFilter submission.beltLevel


filterByBelt : Maybe String -> Submission -> Bool
filterByBelt maybeBelt submission =
    case maybeBelt of
        Just belt ->
            submission.beltLevel == belt

        Nothing ->
            True


filterByGraded : Maybe Bool -> Submission -> Bool
filterByGraded maybeGraded submission =
    case maybeGraded of
        Just isGraded ->
            case submission.grade of
                Just _ ->
                    isGraded

                Nothing ->
                    not isGraded

        Nothing ->
            True


sortSubmissions : SortBy -> SortDirection -> List Submission -> List Submission
sortSubmissions sortBy direction submissions =
    let
        sortFunction =
            case sortBy of
                ByName ->
                    \a b -> compare a.studentName b.studentName

                ByDate ->
                    \a b -> compare a.submissionDate b.submissionDate

                ByBelt ->
                    \a b -> compare a.beltLevel b.beltLevel

                ByGradeStatus ->
                    \a b ->
                        case ( a.grade, b.grade ) of
                            ( Just _, Nothing ) ->
                                LT

                            ( Nothing, Just _ ) ->
                                GT

                            _ ->
                                compare a.submissionDate b.submissionDate

        sortedList =
            List.sortWith sortFunction submissions
    in
    case direction of
        Ascending ->
            sortedList

        Descending ->
            List.reverse sortedList


getUserEmail : Model -> String
getUserEmail model =
    case model.appState of
        Authenticated user ->
            user.email

        _ ->
            "unknown@example.com"
