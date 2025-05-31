module Admin.Pages.PointManagement exposing (update, view)

import Admin.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Shared.Ports as Ports
import Shared.Types exposing (..)
import Shared.Utils exposing (..)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateStudentPointsSearch searchText ->
            ( { model | studentPointsFilterText = searchText }, Cmd.none )

        ShowPointManagementPage ->
            -- Initialize points for existing students if no points data exists
            let
                initializedStudentPoints =
                    if List.isEmpty model.studentPoints then
                        initializeStudentPoints model.students

                    else
                        model.studentPoints
            in
            ( { model
                | page = PointManagementPage
                , loading = False -- Don't show loading since we're using local data
                , studentPoints = initializedStudentPoints
              }
            , Cmd.batch
                [ -- Still try to load from Firebase, but don't depend on it
                  Ports.requestStudentPoints ()
                , Ports.requestPointRedemptions ()
                , Ports.requestPointRewards ()
                ]
            )

        ReceiveStudentPoints result ->
            case result of
                Ok studentPoints ->
                    -- If we get data from Firebase, use it; otherwise keep initialized data
                    let
                        finalStudentPoints =
                            if List.isEmpty studentPoints then
                                initializeStudentPoints model.students

                            else
                                studentPoints
                    in
                    ( { model | studentPoints = finalStudentPoints, loading = False }, Cmd.none )

                Err error ->
                    -- If Firebase fails, use initialized data from existing students
                    let
                        initializedPoints =
                            initializeStudentPoints model.students
                    in
                    ( { model
                        | studentPoints = initializedPoints
                        , loading = False
                        , error = Nothing -- Don't show error, just use local data
                      }
                    , Cmd.none
                    )

        ReceivePointRedemptions result ->
            case result of
                Ok redemptions ->
                    ( { model | pointRedemptions = redemptions }, Cmd.none )

                Err error ->
                    ( { model | pointRedemptions = [] }, Cmd.none )

        -- Just use empty list
        ReceivePointRewards result ->
            case result of
                Ok rewards ->
                    ( { model | pointRewards = rewards }, Cmd.none )

                Err error ->
                    ( { model | pointRewards = [] }, Cmd.none )

        -- Just use empty list
        ShowAwardPointsModal studentId ->
            ( { model
                | showAwardPointsModal = True
                , awardPointsStudentId = studentId
                , awardPointsAmount = ""
                , awardPointsReason = ""
              }
            , Cmd.none
            )

        HideAwardPointsModal ->
            ( { model | showAwardPointsModal = False }, Cmd.none )

        UpdateAwardPointsAmount amount ->
            ( { model | awardPointsAmount = amount }, Cmd.none )

        UpdateAwardPointsReason reason ->
            ( { model | awardPointsReason = reason }, Cmd.none )

        SubmitAwardPoints ->
            case String.toInt model.awardPointsAmount of
                Just points ->
                    if points > 0 then
                        -- Update local student points immediately
                        let
                            updatedStudentPoints =
                                updateStudentPointsLocally
                                    model.awardPointsStudentId
                                    points
                                    model.studentPoints
                        in
                        ( { model
                            | studentPoints = updatedStudentPoints
                            , success = Just ("Awarded " ++ String.fromInt points ++ " points successfully!")
                            , showAwardPointsModal = False
                            , awardPointsAmount = ""
                            , awardPointsReason = ""
                          }
                        , -- Still try to save to Firebase
                          Ports.awardPoints
                            { studentId = model.awardPointsStudentId
                            , points = points
                            , reason = model.awardPointsReason
                            }
                        )

                    else
                        ( { model | error = Just "Points must be a positive number" }, Cmd.none )

                Nothing ->
                    ( { model | error = Just "Please enter a valid number of points" }, Cmd.none )

        PointsAwarded result ->
            case result of
                Ok awardResult ->
                    if awardResult.success then
                        ( { model | success = Just awardResult.message }
                        , Ports.requestStudentPoints ()
                        )

                    else
                        ( { model | error = Just awardResult.message }, Cmd.none )

                Err error ->
                    -- Even if Firebase fails, we already updated locally
                    ( model, Cmd.none )

        -- Manual Redemption Messages
        ShowRedeemPointsModal studentId ->
            ( { model
                | showRedeemPointsModal = True
                , redeemPointsStudentId = studentId
                , redeemPointsAmount = ""
                , redeemPointsReason = ""
                , error = Nothing
              }
            , Cmd.none
            )

        HideRedeemPointsModal ->
            ( { model | showRedeemPointsModal = False }, Cmd.none )

        UpdateRedeemPointsAmount amount ->
            ( { model | redeemPointsAmount = amount }, Cmd.none )

        UpdateRedeemPointsReason reason ->
            ( { model | redeemPointsReason = reason }, Cmd.none )

        SubmitRedeemPoints ->
            case String.toInt model.redeemPointsAmount of
                Just points ->
                    if points > 0 then
                        -- Check if student has enough points
                        let
                            studentPoints =
                                model.studentPoints
                                    |> List.filter (\sp -> sp.studentId == model.redeemPointsStudentId)
                                    |> List.head

                            hasEnoughPoints =
                                case studentPoints of
                                    Just sp ->
                                        sp.currentPoints >= points

                                    Nothing ->
                                        False
                        in
                        if hasEnoughPoints then
                            -- Update local student points immediately
                            let
                                updatedStudentPoints =
                                    redeemStudentPointsLocally
                                        model.redeemPointsStudentId
                                        points
                                        model.studentPoints
                            in
                            ( { model
                                | studentPoints = updatedStudentPoints
                                , success = Just ("Redeemed " ++ String.fromInt points ++ " points successfully!")
                                , showRedeemPointsModal = False
                                , redeemPointsAmount = ""
                                , redeemPointsReason = ""
                              }
                            , -- Try to save redemption to Firebase
                              Ports.redeemPoints
                                { studentId = model.redeemPointsStudentId
                                , points = points
                                , reason = model.redeemPointsReason
                                }
                            )

                        else
                            ( { model | error = Just "Student doesn't have enough points for this redemption" }, Cmd.none )

                    else
                        ( { model | error = Just "Points must be a positive number" }, Cmd.none )

                Nothing ->
                    ( { model | error = Just "Please enter a valid number of points" }, Cmd.none )

        PointsRedeemed result ->
            case result of
                Ok redeemResult ->
                    if redeemResult.success then
                        ( { model | success = Just redeemResult.message }
                        , Ports.requestStudentPoints ()
                        )

                    else
                        ( { model | error = Just redeemResult.message }, Cmd.none )

                Err error ->
                    -- Even if Firebase fails, we already updated locally
                    ( model, Cmd.none )

        ProcessRedemption redemption newStatus ->
            ( { model | loading = True }
            , Ports.processRedemption
                { redemptionId = redemption.id
                , status = redemptionStatusToString newStatus
                , processedBy = getUserEmail model
                }
            )

        RedemptionProcessed result ->
            case result of
                Ok processResult ->
                    if processResult.success then
                        ( { model
                            | loading = False
                            , success = Just processResult.message
                          }
                        , Cmd.batch
                            [ Ports.requestPointRedemptions ()
                            , Ports.requestStudentPoints ()
                            ]
                        )

                    else
                        ( { model | loading = False, error = Just processResult.message }, Cmd.none )

                Err error ->
                    ( { model | loading = False }, Cmd.none )

        -- Reward Management
        UpdateNewRewardName name ->
            ( { model | newRewardName = name }, Cmd.none )

        UpdateNewRewardDescription description ->
            ( { model | newRewardDescription = description }, Cmd.none )

        UpdateNewRewardCost cost ->
            ( { model | newRewardCost = cost }, Cmd.none )

        UpdateNewRewardCategory category ->
            ( { model | newRewardCategory = category }, Cmd.none )

        UpdateNewRewardStock stock ->
            ( { model | newRewardStock = stock }, Cmd.none )

        AddNewReward ->
            case String.toInt model.newRewardCost of
                Just cost ->
                    if String.trim model.newRewardName == "" then
                        ( { model | error = Just "Please enter a reward name" }, Cmd.none )

                    else
                        let
                            stockValue =
                                if String.trim model.newRewardStock == "" then
                                    Nothing

                                else
                                    String.toInt model.newRewardStock

                            newReward =
                                { id = "local-" ++ String.fromInt (List.length model.pointRewards + 1)
                                , name = model.newRewardName
                                , description = model.newRewardDescription
                                , pointCost = cost
                                , category =
                                    if String.trim model.newRewardCategory == "" then
                                        "General"

                                    else
                                        model.newRewardCategory
                                , isActive = True
                                , stock = stockValue
                                , order = List.length model.pointRewards + 1
                                }

                            updatedRewards =
                                newReward :: model.pointRewards
                        in
                        ( { model
                            | pointRewards = updatedRewards
                            , success = Just ("Reward '" ++ newReward.name ++ "' added successfully!")
                            , newRewardName = ""
                            , newRewardDescription = ""
                            , newRewardCost = ""
                            , newRewardCategory = ""
                            , newRewardStock = ""
                          }
                        , Ports.savePointReward (encodePointReward newReward)
                        )

                Nothing ->
                    ( { model | error = Just "Please enter a valid point cost" }, Cmd.none )

        RewardResult result ->
            if String.startsWith "Error:" result then
                ( { model | error = Just result }, Cmd.none )

            else
                ( { model | success = Just result }
                , Ports.requestPointRewards ()
                )

        _ ->
            ( model, Cmd.none )



-- HELPER FUNCTIONS
-- Initialize student points from existing student records


initializeStudentPoints : List Student -> List StudentPoints
initializeStudentPoints students =
    List.map studentToStudentPoints students


studentToStudentPoints : Student -> StudentPoints
studentToStudentPoints student =
    { studentId = student.id
    , currentPoints = 0
    , totalEarned = 0
    , totalRedeemed = 0
    , lastUpdated = "2025-05-30"
    }



-- Update student points locally


updateStudentPointsLocally : String -> Int -> List StudentPoints -> List StudentPoints
updateStudentPointsLocally studentId pointsToAdd studentPointsList =
    List.map
        (\sp ->
            if sp.studentId == studentId then
                { sp
                    | currentPoints = sp.currentPoints + pointsToAdd
                    , totalEarned = sp.totalEarned + pointsToAdd
                    , lastUpdated = "2025-05-30"
                }

            else
                sp
        )
        studentPointsList



-- Redeem student points locally


redeemStudentPointsLocally : String -> Int -> List StudentPoints -> List StudentPoints
redeemStudentPointsLocally studentId pointsToRedeem studentPointsList =
    List.map
        (\sp ->
            if sp.studentId == studentId then
                { sp
                    | currentPoints = Basics.max 0 (sp.currentPoints - pointsToRedeem)
                    , totalRedeemed = sp.totalRedeemed + pointsToRedeem
                    , lastUpdated = "2025-05-30"
                }

            else
                sp
        )
        studentPointsList



-- Get student name from the students list


getStudentNameFromList : String -> List Student -> String
getStudentNameFromList studentId students =
    students
        |> List.filter (\s -> s.id == studentId)
        |> List.head
        |> Maybe.map .name
        |> Maybe.withDefault studentId



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "space-y-6" ]
        [ viewHeader
        , viewPointsOverview model
        , viewActiveRedemptions model
        , viewRewardManagement model
        , viewStudentPointsTable model
        , viewAwardPointsModal model
        , viewRedeemPointsModal model
        ]


viewHeader : Html Msg
viewHeader =
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ div [ class "flex justify-between items-center" ]
            [ h2 [ class "text-xl font-medium text-gray-900" ] [ text "Point Management System" ]
            , button
                [ onClick CloseCurrentPage
                , class "text-gray-500 hover:text-gray-700 flex items-center"
                ]
                [ span [ class "mr-1" ] [ text "←" ]
                , text "Back to Submissions"
                ]
            ]
        ]


viewPointsOverview : Model -> Html Msg
viewPointsOverview model =
    let
        totalPointsEarned =
            List.sum (List.map .totalEarned model.studentPoints)

        totalPointsRedeemed =
            List.sum (List.map .totalRedeemed model.studentPoints)

        currentPointsInSystem =
            List.sum (List.map .currentPoints model.studentPoints)

        pendingRedemptions =
            List.length (List.filter (\r -> r.status == Pending) model.pointRedemptions)
    in
    div [ class "grid grid-cols-1 md:grid-cols-4 gap-6" ]
        [ viewStatCard "Total Points Earned" (String.fromInt totalPointsEarned) "🎯"
        , viewStatCard "Points Redeemed" (String.fromInt totalPointsRedeemed) "🎁"
        , viewStatCard "Current Points" (String.fromInt currentPointsInSystem) "💎"
        , viewStatCard "Pending Redemptions" (String.fromInt pendingRedemptions) "⏳"
        ]


viewStatCard : String -> String -> String -> Html Msg
viewStatCard title value icon =
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ div [ class "flex items-center" ]
            [ div [ class "flex-shrink-0" ]
                [ span [ class "text-2xl" ] [ text icon ]
                ]
            , div [ class "ml-4" ]
                [ p [ class "text-sm font-medium text-gray-500" ] [ text title ]
                , p [ class "text-2xl font-semibold text-gray-900" ] [ text value ]
                ]
            ]
        ]


viewActiveRedemptions : Model -> Html Msg
viewActiveRedemptions model =
    let
        activeRedemptions =
            List.filter (\r -> r.status == Pending) model.pointRedemptions
    in
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ h3 [ class "text-lg font-medium text-gray-900 mb-4" ]
            [ text ("Pending Redemptions (" ++ String.fromInt (List.length activeRedemptions) ++ ")") ]
        , if List.isEmpty activeRedemptions then
            div [ class "text-center py-8 text-gray-500" ]
                [ text "No pending redemptions" ]

          else
            div [ class "overflow-x-auto" ]
                [ table [ class "min-w-full divide-y divide-gray-200" ]
                    [ thead [ class "bg-gray-50" ]
                        [ tr []
                            [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Student" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Reward" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Points" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Date" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Actions" ]
                            ]
                        ]
                    , tbody [ class "bg-white divide-y divide-gray-200" ]
                        (List.map viewRedemptionRow activeRedemptions)
                    ]
                ]
        ]


viewRedemptionRow : PointRedemption -> Html Msg
viewRedemptionRow redemption =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ]
            [ text (formatDisplayName redemption.studentName) ]
        , td [ class "px-6 py-4" ]
            [ div []
                [ p [ class "text-sm font-medium text-gray-900" ] [ text redemption.rewardName ]
                , p [ class "text-xs text-gray-500" ] [ text redemption.rewardDescription ]
                ]
            ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ span [ class "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800" ]
                [ text (String.fromInt redemption.pointsRedeemed) ]
            ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm text-gray-500" ]
            [ text redemption.redemptionDate ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium" ]
            [ div [ class "flex space-x-2" ]
                [ button
                    [ onClick (ProcessRedemption redemption Approved)
                    , class "px-3 py-1 bg-green-100 text-green-700 rounded hover:bg-green-200"
                    ]
                    [ text "Approve" ]
                , button
                    [ onClick (ProcessRedemption redemption Fulfilled)
                    , class "px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200"
                    ]
                    [ text "Fulfill" ]
                , button
                    [ onClick (ProcessRedemption redemption Cancelled)
                    , class "px-3 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200"
                    ]
                    [ text "Cancel" ]
                ]
            ]
        ]


viewRewardManagement : Model -> Html Msg
viewRewardManagement model =
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ h3 [ class "text-lg font-medium text-gray-900 mb-4" ] [ text "Reward Management" ]
        , viewAddRewardForm model
        , viewRewardsList model
        ]


viewAddRewardForm : Model -> Html Msg
viewAddRewardForm model =
    div [ class "bg-gray-50 p-4 rounded-lg mb-6" ]
        [ h4 [ class "text-md font-medium text-gray-900 mb-3" ] [ text "Add New Reward" ]
        , div [ class "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4" ]
            [ div []
                [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Reward Name" ]
                , input
                    [ type_ "text"
                    , value model.newRewardName
                    , onInput UpdateNewRewardName
                    , placeholder "e.g., Extra Credit, Homework Pass"
                    , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    ]
                    []
                ]
            , div []
                [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Point Cost" ]
                , input
                    [ type_ "number"
                    , value model.newRewardCost
                    , onInput UpdateNewRewardCost
                    , placeholder "50"
                    , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    ]
                    []
                ]
            , div []
                [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Category" ]
                , input
                    [ type_ "text"
                    , value model.newRewardCategory
                    , onInput UpdateNewRewardCategory
                    , placeholder "Academic, Fun, Privileges"
                    , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    ]
                    []
                ]
            , div [ class "md:col-span-2" ]
                [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Description" ]
                , input
                    [ type_ "text"
                    , value model.newRewardDescription
                    , onInput UpdateNewRewardDescription
                    , placeholder "Detailed description of the reward"
                    , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    ]
                    []
                ]
            , div []
                [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Stock (optional)" ]
                , input
                    [ type_ "number"
                    , value model.newRewardStock
                    , onInput UpdateNewRewardStock
                    , placeholder "Leave empty for unlimited"
                    , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    ]
                    []
                ]
            ]
        , div [ class "mt-4" ]
            [ button
                [ onClick AddNewReward
                , class "px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none"
                ]
                [ text "Add Reward" ]
            ]
        ]


viewRewardsList : Model -> Html Msg
viewRewardsList model =
    if List.isEmpty model.pointRewards then
        div [ class "text-center py-8 text-gray-500" ]
            [ text "No rewards configured yet. Add some rewards above!" ]

    else
        div [ class "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4" ]
            (List.map viewRewardCard model.pointRewards)


viewRewardCard : PointReward -> Html Msg
viewRewardCard reward =
    div [ class "border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow" ]
        [ div [ class "flex justify-between items-start mb-2" ]
            [ div []
                [ h5 [ class "font-medium text-gray-900" ] [ text reward.name ]
                , p [ class "text-xs text-gray-500" ] [ text reward.category ]
                ]
            , span [ class "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800" ]
                [ text (String.fromInt reward.pointCost ++ " pts") ]
            ]
        , p [ class "text-sm text-gray-600 mb-3" ] [ text reward.description ]
        , div [ class "flex justify-between items-center" ]
            [ div []
                [ case reward.stock of
                    Just stock ->
                        span [ class "text-xs text-gray-500" ] [ text ("Stock: " ++ String.fromInt stock) ]

                    Nothing ->
                        span [ class "text-xs text-gray-500" ] [ text "Unlimited" ]
                ]
            , div [ class "flex space-x-2" ]
                [ button
                    [ onClick (EditReward reward)
                    , class "text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200"
                    ]
                    [ text "Edit" ]
                , button
                    [ onClick (DeleteReward reward)
                    , class "text-xs px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200"
                    ]
                    [ text "Delete" ]
                ]
            ]
        ]


viewStudentPointsTable : Model -> Html Msg
viewStudentPointsTable model =
    let
        filteredStudentPoints =
            applyStudentPointsFilter model.studentPointsFilterText model
    in
    div [ class "bg-white shadow rounded-lg p-6" ]
        [ div [ class "flex justify-between items-center mb-4" ]
            [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Student Points" ]
            , div [ class "flex items-center space-x-3" ]
                [ div [ class "relative" ]
                    [ input
                        [ type_ "text"
                        , placeholder "Search students..."
                        , value model.studentPointsFilterText
                        , onInput UpdateStudentPointsSearch
                        , class "w-64 pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        ]
                        []
                    , div [ class "absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none" ]
                        [ span [ class "text-gray-400 text-sm" ] [ text "🔍" ]
                        ]
                    ]
                , span [ class "text-sm text-gray-500" ]
                    [ text ("Showing " ++ String.fromInt (List.length filteredStudentPoints) ++ " of " ++ String.fromInt (List.length model.studentPoints) ++ " students")
                    ]
                ]
            ]
        , if List.isEmpty model.studentPoints then
            div [ class "text-center py-8 text-gray-500" ]
                [ text "No students found. Go to Student Management to add students first." ]

          else if List.isEmpty filteredStudentPoints then
            div [ class "text-center py-8 text-gray-500" ]
                [ text "No students match your search. Try a different search term." ]

          else
            div [ class "overflow-x-auto" ]
                [ table [ class "min-w-full divide-y divide-gray-200" ]
                    [ thead [ class "bg-gray-50" ]
                        [ tr []
                            [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Student" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Current Points" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Total Earned" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Total Redeemed" ]
                            , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" ] [ text "Actions" ]
                            ]
                        ]
                    , tbody [ class "bg-white divide-y divide-gray-200" ]
                        (List.map (viewStudentPointsRow model) filteredStudentPoints)
                    ]
                ]
        ]


viewStudentPointsRow : Model -> StudentPoints -> Html Msg
viewStudentPointsRow model studentPoints =
    let
        studentName =
            getStudentNameFromList studentPoints.studentId model.students
    in
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap" ]
            [ div []
                [ div [ class "text-sm font-medium text-gray-900" ]
                    [ text (formatDisplayName studentName) ]
                , div [ class "text-xs text-gray-500" ]
                    [ text ("ID: " ++ studentPoints.studentId) ]
                ]
            ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ span [ class "inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium bg-green-100 text-green-800" ]
                [ text (String.fromInt studentPoints.currentPoints) ]
            ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm text-gray-900" ]
            [ text (String.fromInt studentPoints.totalEarned) ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm text-gray-900" ]
            [ text (String.fromInt studentPoints.totalRedeemed) ]
        , td [ class "px-6 py-4 whitespace-nowrap text-sm font-medium" ]
            [ div [ class "flex space-x-2" ]
                [ button
                    [ onClick (ShowAwardPointsModal studentPoints.studentId)
                    , class "px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200"
                    ]
                    [ text "Award Points" ]
                , -- Add visual feedback to see if button is clickable
                  button
                    [ onClick (ShowRedeemPointsModal studentPoints.studentId)
                    , class
                        (if studentPoints.currentPoints <= 0 then
                            "px-3 py-1 bg-gray-100 text-gray-500 rounded cursor-not-allowed"

                         else
                            "px-3 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 active:bg-red-300 transition-colors"
                        )
                    , title ("Available: " ++ String.fromInt studentPoints.currentPoints ++ " points")
                    ]
                    [ text ("Redeem (" ++ String.fromInt studentPoints.currentPoints ++ ")") ]
                ]
            ]
        ]


viewAwardPointsModal : Model -> Html Msg
viewAwardPointsModal model =
    if model.showAwardPointsModal then
        let
            selectedStudent =
                model.students
                    |> List.filter (\s -> s.id == model.awardPointsStudentId)
                    |> List.head

            studentName =
                selectedStudent
                    |> Maybe.map .name
                    |> Maybe.withDefault model.awardPointsStudentId
        in
        div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
            [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                [ div [ class "px-6 py-4 bg-gray-50 border-b border-gray-200" ]
                    [ h3 [ class "text-lg font-medium text-gray-900" ]
                        [ text ("Award Points to " ++ formatDisplayName studentName) ]
                    ]
                , div [ class "p-6" ]
                    [ div [ class "space-y-4" ]
                        [ div []
                            [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Points to Award" ]
                            , input
                                [ type_ "number"
                                , value model.awardPointsAmount
                                , onInput UpdateAwardPointsAmount
                                , placeholder "10"
                                , Html.Attributes.min "1"
                                , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                                ]
                                []
                            , p [ class "text-xs text-gray-500 mt-1" ] [ text "Common values: 5 (small task), 10 (standard), 25 (exceptional)" ]
                            ]
                        , div []
                            [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Reason" ]
                            , textarea
                                [ value model.awardPointsReason
                                , onInput UpdateAwardPointsReason
                                , placeholder "Reason for awarding points..."
                                , rows 3
                                , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                                ]
                                []
                            ]
                        ]
                    , div [ class "mt-6 flex justify-end space-x-3" ]
                        [ button
                            [ onClick HideAwardPointsModal
                            , class "px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                            ]
                            [ text "Cancel" ]
                        , button
                            [ onClick SubmitAwardPoints
                            , class "px-4 py-2 border border-transparent rounded-md text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                            ]
                            [ text "Award Points" ]
                        ]
                    ]
                ]
            ]

    else
        text ""


viewRedeemPointsModal : Model -> Html Msg
viewRedeemPointsModal model =
    if model.showRedeemPointsModal then
        let
            selectedStudent =
                model.students
                    |> List.filter (\s -> s.id == model.redeemPointsStudentId)
                    |> List.head

            studentName =
                selectedStudent
                    |> Maybe.map .name
                    |> Maybe.withDefault model.redeemPointsStudentId

            currentPoints =
                model.studentPoints
                    |> List.filter (\sp -> sp.studentId == model.redeemPointsStudentId)
                    |> List.head
                    |> Maybe.map .currentPoints
                    |> Maybe.withDefault 0
        in
        div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
            [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                [ div [ class "px-6 py-4 bg-red-50 border-b border-gray-200" ]
                    [ h3 [ class "text-lg font-medium text-red-700" ]
                        [ text ("Redeem Points from " ++ formatDisplayName studentName) ]
                    ]
                , div [ class "p-6" ]
                    [ div [ class "mb-4 p-3 bg-blue-50 border border-blue-200 rounded-md" ]
                        [ p [ class "text-sm text-blue-800" ]
                            [ text ("Current available points: " ++ String.fromInt currentPoints) ]
                        ]
                    , div [ class "space-y-4" ]
                        [ div []
                            [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Points to Redeem" ]
                            , input
                                [ type_ "number"
                                , value model.redeemPointsAmount
                                , onInput UpdateRedeemPointsAmount
                                , placeholder "10"
                                , Html.Attributes.min "1"
                                , Html.Attributes.max (String.fromInt currentPoints)
                                , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-red-500 focus:border-red-500"
                                ]
                                []
                            , p [ class "text-xs text-gray-500 mt-1" ] [ text ("Maximum: " ++ String.fromInt currentPoints ++ " points") ]
                            ]
                        , div []
                            [ label [ class "block text-sm font-medium text-gray-700 mb-1" ] [ text "Reason for Redemption" ]
                            , textarea
                                [ value model.redeemPointsReason
                                , onInput UpdateRedeemPointsReason
                                , placeholder "Reason for redeeming points (e.g., 'Manual adjustment', 'Reward purchased')..."
                                , rows 3
                                , class "w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-red-500 focus:border-red-500"
                                ]
                                []
                            ]
                        ]
                    , div [ class "mt-6 flex justify-end space-x-3" ]
                        [ button
                            [ onClick HideRedeemPointsModal
                            , class "px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                            ]
                            [ text "Cancel" ]
                        , button
                            [ onClick SubmitRedeemPoints
                            , class "px-4 py-2 border border-transparent rounded-md text-sm font-medium text-white bg-red-600 hover:bg-red-700"
                            ]
                            [ text "Redeem Points" ]
                        ]
                    ]
                ]
            ]

    else
        text ""



-- Helper Functions


applyStudentPointsFilter : String -> Model -> List StudentPoints
applyStudentPointsFilter searchText model =
    if String.isEmpty (String.trim searchText) then
        model.studentPoints

    else
        let
            lowercaseSearch =
                String.toLower (String.trim searchText)

            matchesSearch studentPoints =
                let
                    studentName =
                        getStudentNameFromList studentPoints.studentId model.students

                    studentId =
                        studentPoints.studentId
                in
                String.contains lowercaseSearch (String.toLower studentName)
                    || String.contains lowercaseSearch (String.toLower studentId)
                    || String.contains lowercaseSearch (String.toLower (formatDisplayName studentName))
        in
        List.filter matchesSearch model.studentPoints


getUserEmail : Model -> String
getUserEmail model =
    case model.appState of
        Authenticated user ->
            user.email

        _ ->
            "unknown@example.com"


redemptionStatusToString : RedemptionStatus -> String
redemptionStatusToString status =
    case status of
        Pending ->
            "pending"

        Approved ->
            "approved"

        Fulfilled ->
            "fulfilled"

        Cancelled ->
            "cancelled"


encodePointReward : PointReward -> Encode.Value
encodePointReward reward =
    Encode.object
        [ ( "name", Encode.string reward.name )
        , ( "description", Encode.string reward.description )
        , ( "pointCost", Encode.int reward.pointCost )
        , ( "category", Encode.string reward.category )
        , ( "isActive", Encode.bool reward.isActive )
        , ( "stock"
          , case reward.stock of
                Just s ->
                    Encode.int s

                Nothing ->
                    Encode.null
          )
        , ( "order", Encode.int reward.order )
        ]
