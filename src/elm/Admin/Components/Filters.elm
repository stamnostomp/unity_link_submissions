module Admin.Components.Filters exposing (..)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Shared.Types exposing (..)


viewSubmissionFilters : Model -> Html Msg
viewSubmissionFilters model =
    div [ class "flex flex-col md:flex-row md:items-center md:justify-between mb-4 gap-4" ]
        [ div [ class "flex-1" ]
            [ label [ for "filterText", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Search" ]
            , input
                [ type_ "text"
                , id "filterText"
                , placeholder "Search by name or game"
                , value model.filterText
                , onInput UpdateFilterText
                , class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                ]
                []
            ]
        , div [ class "w-full md:w-auto flex flex-col md:flex-row gap-4" ]
            [ div [ class "flex-1 md:w-40" ]
                [ label [ for "filterBelt", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Belt" ]
                , select [ id "filterBelt", onInput UpdateFilterBelt, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ]
                    ([ option [ value "all" ] [ text "All Belts" ] ] ++ List.map (\belt -> option [ value belt.name ] [ text belt.name ]) model.belts)
                ]
            , div [ class "flex-1 md:w-40" ]
                [ label [ for "filterGraded", class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Status" ]
                , select [ id "filterGraded", onInput UpdateFilterGraded, class "w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ]
                    [ option [ value "all" ] [ text "All Status" ]
                    , option [ value "graded" ] [ text "Graded" ]
                    , option [ value "ungraded" ] [ text "Ungraded" ]
                    ]
                ]
            ]
        ]


viewSubmissionSort : Model -> Html Msg
viewSubmissionSort model =
    div [ class "flex flex-col sm:flex-row justify-between items-center" ]
        [ div [ class "flex items-center gap-2 mb-2 sm:mb-0" ]
            [ span [ class "text-sm text-gray-500" ] [ text "Sort by:" ]
            , button [ onClick (UpdateSortBy ByName), class (getSortButtonClass model ByName) ] [ text "Name" ]
            , button [ onClick (UpdateSortBy ByDate), class (getSortButtonClass model ByDate) ] [ text "Date" ]
            , button [ onClick (UpdateSortBy ByBelt), class (getSortButtonClass model ByBelt) ] [ text "Belt" ]
            , button [ onClick (UpdateSortBy ByGradeStatus), class (getSortButtonClass model ByGradeStatus) ] [ text "Grade Status" ]
            , button [ onClick ToggleSortDirection, class "ml-2 px-2 py-1 rounded text-gray-600 hover:bg-gray-100" ]
                [ text
                    (if model.sortDirection == Ascending then
                        "↑"

                     else
                        "↓"
                    )
                ]
            ]
        , div [ class "flex items-center" ]
            [ button [ onClick RefreshSubmissions, class "flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Refresh" ]
            , span [ class "ml-4 text-sm text-gray-500" ] [ text ("Total: " ++ String.fromInt (List.length (applyFilters model)) ++ " submissions") ]
            ]
        ]


getSortButtonClass : Model -> SortBy -> String
getSortButtonClass model sortType =
    let
        baseClass =
            "px-3 py-1 rounded text-sm"
    in
    if model.sortBy == sortType then
        baseClass ++ " bg-blue-100 text-blue-800 font-medium"

    else
        baseClass ++ " text-gray-600 hover:bg-gray-100"



-- Helper functions needed by filters


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
        containsFilter submission.studentName || containsFilter submission.gameName || containsFilter submission.beltLevel


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
