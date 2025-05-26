module Admin.Pages.BeltManagement exposing (update, view)

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
        ReceiveBelts result ->
            case result of
                Ok belts ->
                    ( { model | belts = belts, loading = False }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error), loading = False }, Cmd.none )

        UpdateNewBeltName name ->
            ( { model | newBeltName = name }, Cmd.none )

        UpdateNewBeltColor color ->
            ( { model | newBeltColor = color }, Cmd.none )

        UpdateNewBeltOrder order ->
            ( { model | newBeltOrder = order }, Cmd.none )

        UpdateNewBeltGameOptions options ->
            ( { model | newBeltGameOptions = options }, Cmd.none )

        AddNewBelt ->
            if String.trim model.newBeltName == "" then
                ( { model | error = Just "Please enter a belt name" }, Cmd.none )

            else
                let
                    orderResult =
                        String.toInt model.newBeltOrder
                in
                case orderResult of
                    Just order ->
                        let
                            gameOptions =
                                model.newBeltGameOptions
                                    |> String.split ","
                                    |> List.map String.trim
                                    |> List.filter (not << String.isEmpty)

                            beltId =
                                model.newBeltName |> String.toLower |> String.replace " " "-"

                            newBelt =
                                { id = beltId
                                , name = model.newBeltName
                                , color = model.newBeltColor
                                , order = order
                                , gameOptions = gameOptions
                                }
                        in
                        ( { model | loading = True, error = Nothing }
                        , Ports.saveBelt (encodeBelt newBelt)
                        )

                    Nothing ->
                        ( { model | error = Just "Please enter a valid order number" }, Cmd.none )

        EditBelt belt ->
            ( { model
                | editingBelt = Just belt
                , newBeltName = belt.name
                , newBeltColor = belt.color
                , newBeltOrder = String.fromInt belt.order
                , newBeltGameOptions = String.join ", " belt.gameOptions
              }
            , Cmd.none
            )

        CancelEditBelt ->
            ( { model
                | editingBelt = Nothing
                , newBeltName = ""
                , newBeltColor = "#000000"
                , newBeltOrder = ""
                , newBeltGameOptions = ""
              }
            , Cmd.none
            )

        UpdateBelt ->
            case model.editingBelt of
                Just belt ->
                    if String.trim model.newBeltName == "" then
                        ( { model | error = Just "Please enter a belt name" }, Cmd.none )

                    else
                        let
                            orderResult =
                                String.toInt model.newBeltOrder
                        in
                        case orderResult of
                            Just order ->
                                let
                                    gameOptions =
                                        model.newBeltGameOptions
                                            |> String.split ","
                                            |> List.map String.trim
                                            |> List.filter (not << String.isEmpty)

                                    updatedBelt =
                                        { id = belt.id
                                        , name = model.newBeltName
                                        , color = model.newBeltColor
                                        , order = order
                                        , gameOptions = gameOptions
                                        }
                                in
                                ( { model | loading = True, error = Nothing }
                                , Ports.saveBelt (encodeBelt updatedBelt)
                                )

                            Nothing ->
                                ( { model | error = Just "Please enter a valid order number" }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        DeleteBelt beltId ->
            ( { model | loading = True }, Ports.deleteBelt beltId )

        BeltResult result ->
            if String.startsWith "Error:" result then
                ( { model | error = Just result, loading = False, success = Nothing }, Cmd.none )

            else
                ( { model
                    | success = Just result
                    , loading = False
                    , error = Nothing
                    , editingBelt = Nothing
                    , newBeltName = ""
                    , newBeltColor = "#000000"
                    , newBeltOrder = ""
                    , newBeltGameOptions = ""
                  }
                , Ports.requestBelts ()
                )

        RefreshBelts ->
            ( { model | loading = True }, Ports.requestBelts () )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "space-y-6" ]
        [ div [ class "bg-white shadow rounded-lg p-6" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-900" ] [ text "Belt Management" ]
                , button
                    [ onClick CloseCurrentPage
                    , class "text-gray-500 hover:text-gray-700 flex items-center"
                    ]
                    [ span [ class "mr-1" ] [ text "←" ]
                    , text "Back to Submissions"
                    ]
                ]
            , viewBeltForm model
            , viewBeltsList model
            ]
        ]


viewBeltForm : Model -> Html Msg
viewBeltForm model =
    div [ class "mt-6" ]
        [ div [ class "bg-white overflow-hidden shadow-sm rounded-lg border border-gray-200" ]
            [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
                [ h3 [ class "text-lg font-medium text-gray-900" ]
                    [ text
                        (case model.editingBelt of
                            Just belt ->
                                "Edit Belt: " ++ belt.name

                            Nothing ->
                                "Add New Belt"
                        )
                    ]
                ]
            , div [ class "p-6" ]
                [ div [ class "grid grid-cols-1 md:grid-cols-2 gap-4" ]
                    [ div [ class "space-y-2" ]
                        [ label [ for "beltName", class "block text-sm font-medium text-gray-700" ] [ text "Belt Name:" ]
                        , input
                            [ type_ "text"
                            , id "beltName"
                            , value model.newBeltName
                            , onInput UpdateNewBeltName
                            , placeholder "e.g. White Belt, Yellow Belt"
                            , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                            ]
                            []
                        ]
                    , div [ class "space-y-2" ]
                        [ label [ for "beltColor", class "block text-sm font-medium text-gray-700" ] [ text "Belt Color:" ]
                        , div [ class "flex items-center space-x-2" ]
                            [ input [ type_ "color", id "beltColor", value model.newBeltColor, onInput UpdateNewBeltColor, class "h-8 w-8 border border-gray-300 rounded" ] []
                            , input [ type_ "text", value model.newBeltColor, onInput UpdateNewBeltColor, placeholder "#000000", class "flex-1 mt-1 border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                            ]
                        ]
                    , div [ class "space-y-2" ]
                        [ label [ for "beltOrder", class "block text-sm font-medium text-gray-700" ] [ text "Display Order:" ]
                        , input [ type_ "number", id "beltOrder", value model.newBeltOrder, onInput UpdateNewBeltOrder, placeholder "1, 2, 3, etc.", class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                        ]
                    , div [ class "space-y-2" ]
                        [ label [ for "gameOptions", class "block text-sm font-medium text-gray-700" ] [ text "Game Options (comma separated):" ]
                        , textarea [ id "gameOptions", value model.newBeltGameOptions, onInput UpdateNewBeltGameOptions, placeholder "Game 1, Game 2, Game 3", rows 3, class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm" ] []
                        ]
                    ]
                , div [ class "mt-6 flex space-x-3" ]
                    [ case model.editingBelt of
                        Just belt ->
                            div [ class "flex space-x-3 w-full" ]
                                [ button [ onClick UpdateBelt, class "flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500" ] [ text "Update Belt" ]
                                , button [ onClick CancelEditBelt, class "py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500" ] [ text "Cancel" ]
                                ]

                        Nothing ->
                            button [ onClick AddNewBelt, class "w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500" ] [ text "Add Belt" ]
                    ]
                ]
            ]
        ]


viewBeltsList : Model -> Html Msg
viewBeltsList model =
    div [ class "mt-8" ]
        [ div [ class "flex justify-between items-center mb-4" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Current Belts" ]
            , button [ onClick RefreshBelts, class "py-1 px-3 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none" ] [ text "Refresh" ]
            ]
        , if List.isEmpty model.belts then
            div [ class "text-center py-12 bg-gray-50 rounded-lg border border-gray-200" ]
                [ p [ class "text-gray-500" ] [ text "No belts configured yet. Add your first belt above." ] ]

          else
            div [ class "bg-white shadow overflow-hidden sm:rounded-lg border border-gray-200" ]
                [ ul [ class "divide-y divide-gray-200" ] (List.map viewBeltRow (List.sortBy .order model.belts)) ]
        ]


viewBeltRow : Belt -> Html Msg
viewBeltRow belt =
    li [ class "py-4 px-6 flex items-center justify-between hover:bg-gray-50" ]
        [ div [ class "flex items-center space-x-4" ]
            [ div [ class "w-8 h-8 rounded-full border border-gray-300 flex-shrink-0", style "background-color" belt.color ] []
            , div [ class "flex-1 min-w-0" ]
                [ div [ class "flex items-center" ]
                    [ p [ class "text-sm font-medium text-gray-900 truncate" ] [ text belt.name ]
                    , span [ class "ml-2 text-xs text-gray-500" ] [ text ("Order: " ++ String.fromInt belt.order) ]
                    ]
                , p [ class "text-xs text-gray-500 truncate" ] [ text ("Games: " ++ truncateGamesList belt.gameOptions) ]
                ]
            ]
        , div [ class "flex space-x-2 ml-2 flex-shrink-0" ]
            [ button [ onClick (EditBelt belt), class "px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition" ] [ text "Edit" ]
            , button [ onClick (DeleteBelt belt.id), class "px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition" ] [ text "Delete" ]
            ]
        ]


truncateGamesList : List String -> String
truncateGamesList games =
    let
        maxGamesToShow =
            3

        totalGames =
            List.length games

        displayGames =
            if totalGames <= maxGamesToShow then
                games

            else
                List.take maxGamesToShow games ++ [ "..." ++ String.fromInt (totalGames - maxGamesToShow) ++ " more" ]
    in
    String.join ", " displayGames
