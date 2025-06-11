port module Student exposing (..)

-- Complete Student application with all ports properly defined

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Svg exposing (path, svg)
import Svg.Attributes exposing (fill, viewBox)
import Task
import Time



-- PORTS


port findStudent : String -> Cmd msg


port studentFound : (Decode.Value -> msg) -> Sub msg


port saveSubmission : Encode.Value -> Cmd msg


port submissionResult : (String -> msg) -> Sub msg


port requestBelts : () -> Cmd msg


port receiveBelts : (Decode.Value -> msg) -> Sub msg



-- Point System Ports


port requestStudentPoints : String -> Cmd msg


port receiveStudentPoints : (Decode.Value -> msg) -> Sub msg


port requestPointRewards : () -> Cmd msg


port receivePointRewards : (Decode.Value -> msg) -> Sub msg


port redeemPointReward : Encode.Value -> Cmd msg


port pointRedemptionResult : (String -> msg) -> Sub msg


port requestPointTransactions : String -> Cmd msg


port receivePointTransactions : (Decode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Student =
    { id : String
    , name : String
    , created : String
    , lastActive : String
    , submissions : List Submission
    }


type alias Submission =
    { id : String
    , studentId : String
    , beltLevel : String
    , gameName : String
    , githubLink : String
    , notes : String
    , submissionDate : String
    , grade : Maybe Grade
    }


type alias Grade =
    { score : Int
    , feedback : String
    , gradedBy : String
    , gradingDate : String
    }


type alias Belt =
    { id : String
    , name : String
    , color : String
    , order : Int
    , gameOptions : List String
    }


type alias StudentPoints =
    { studentId : String
    , currentPoints : Int
    , totalEarned : Int
    , totalRedeemed : Int
    , lastUpdated : String
    }


type alias PointReward =
    { id : String
    , name : String
    , description : String
    , pointCost : Int
    , category : String
    , isActive : Bool
    , stock : Maybe Int
    , order : Int
    }


type alias PointTransaction =
    { id : String
    , studentId : String
    , studentName : String
    , transactionType : TransactionType
    , points : Int
    , reason : String
    , category : String
    , adminEmail : String
    , date : String
    }


type TransactionType
    = Award
    | Redemption


type alias PointRedemption =
    { id : String
    , studentId : String
    , studentName : String
    , pointsRedeemed : Int
    , rewardName : String
    , rewardDescription : String
    , redeemedBy : String
    , redemptionDate : String
    , status : RedemptionStatus
    }


type RedemptionStatus
    = Pending
    | Approved
    | Fulfilled
    | Cancelled


type Page
    = NamePage
    | StudentProfilePage Student
    | SubmissionFormPage Student
    | SubmissionCompletePage Student Submission
    | PointsPage Student
    | RedemptionHistoryPage Student
    | LoadingPage String


type alias Model =
    { page : Page
    , searchName : String
    , beltLevel : String
    , gameName : String
    , githubLink : String
    , notes : String
    , errorMessage : Maybe String
    , successMessage : Maybe String
    , belts : List Belt

    -- Points System Data
    , studentPoints : Maybe StudentPoints
    , pointRewards : List PointReward
    , pointTransactions : List PointTransaction
    , selectedReward : Maybe PointReward
    , showRedemptionConfirm : Bool
    , loading : Bool
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { page = NamePage
      , searchName = ""
      , beltLevel = ""
      , gameName = ""
      , githubLink = ""
      , notes = ""
      , errorMessage = Nothing
      , successMessage = Nothing
      , belts = []
      , studentPoints = Nothing
      , pointRewards = []
      , pointTransactions = []
      , selectedReward = Nothing
      , showRedemptionConfirm = False
      , loading = False
      }
    , requestBelts ()
    )



-- MESSAGES


type Msg
    = UpdateSearchName String
    | SearchStudent
    | StudentFoundResult (Result Decode.Error (Maybe Student))
    | StartNewSubmission Student
    | UpdateBeltLevel String
    | UpdateGameName String
    | UpdateGithubLink String
    | UpdateNotes String
    | SubmitForm Student
    | SubmissionSaved String
    | BackToProfile
    | BackToSearch
    | Reset
    | BeltsReceived (Result Decode.Error (List Belt))
      -- Points System Messages
    | ShowPointsPage Student
    | ShowRedemptionHistory Student
    | StudentPointsReceived (Result Decode.Error StudentPoints)
    | PointRewardsReceived (Result Decode.Error (List PointReward))
    | PointTransactionsReceived (Result Decode.Error (List PointTransaction))
    | SelectReward PointReward
    | CancelRedemption
    | ConfirmRedemption
    | RedemptionResult String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateSearchName name ->
            ( { model | searchName = name }, Cmd.none )

        SearchStudent ->
            let
                trimmedName =
                    String.trim model.searchName
            in
            if String.isEmpty trimmedName then
                ( { model | errorMessage = Just "Please enter your name to continue" }, Cmd.none )

            else if not (isValidNameFormat trimmedName) then
                ( { model | errorMessage = Just "Please enter your name in the format firstname.lastname (e.g., tyler.smith)" }, Cmd.none )

            else
                ( { model | page = LoadingPage "Searching for your record...", errorMessage = Nothing }
                , findStudent trimmedName
                )

        StudentFoundResult result ->
            case result of
                Ok maybeStudent ->
                    case maybeStudent of
                        Just student ->
                            ( { model | page = StudentProfilePage student, errorMessage = Nothing }, Cmd.none )

                        Nothing ->
                            ( { model
                                | page = NamePage
                                , errorMessage = Just "No record found. Please check your name or ask your teacher to create a record for you."
                              }
                            , Cmd.none
                            )

                Err error ->
                    ( { model
                        | page = NamePage
                        , errorMessage = Just ("Error loading record: " ++ Decode.errorToString error)
                      }
                    , Cmd.none
                    )

        StartNewSubmission student ->
            ( { model
                | page = SubmissionFormPage student
                , beltLevel = ""
                , gameName = ""
                , githubLink = ""
                , notes = ""
                , errorMessage = Nothing
              }
            , Cmd.none
            )

        UpdateBeltLevel beltId ->
            let
                gameOptions =
                    getGameOptions beltId model.belts

                defaultGame =
                    List.head gameOptions |> Maybe.withDefault ""
            in
            ( { model | beltLevel = beltId, gameName = defaultGame }, Cmd.none )

        UpdateGameName game ->
            ( { model | gameName = game }, Cmd.none )

        UpdateGithubLink link ->
            ( { model | githubLink = link }, Cmd.none )

        UpdateNotes notes ->
            ( { model | notes = notes }, Cmd.none )

        SubmitForm student ->
            if String.trim model.beltLevel == "" || String.trim model.gameName == "" || String.trim model.githubLink == "" then
                ( { model | errorMessage = Just "Please fill in all required fields" }, Cmd.none )

            else
                let
                    currentDate =
                        "2025-06-04"

                    newSubmission =
                        { id = student.id ++ "-" ++ model.beltLevel ++ "-" ++ String.fromInt (List.length student.submissions + 1)
                        , studentId = student.id
                        , beltLevel = model.beltLevel
                        , gameName = model.gameName
                        , githubLink = model.githubLink
                        , notes = model.notes
                        , submissionDate = currentDate
                        , grade = Nothing
                        }
                in
                ( { model | page = LoadingPage "Saving your submission...", errorMessage = Nothing }
                , saveSubmission (encodeSubmission newSubmission)
                )

        SubmissionSaved result ->
            case model.page of
                LoadingPage _ ->
                    if String.startsWith "Error:" result then
                        ( { model | errorMessage = Just result, page = NamePage }, Cmd.none )

                    else
                        ( model, findStudent model.searchName )

                _ ->
                    ( model, Cmd.none )

        BackToProfile ->
            case model.page of
                SubmissionFormPage student ->
                    ( { model | page = StudentProfilePage student }, Cmd.none )

                PointsPage student ->
                    ( { model | page = StudentProfilePage student }, Cmd.none )

                RedemptionHistoryPage student ->
                    ( { model | page = StudentProfilePage student }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        BackToSearch ->
            ( { model | page = NamePage }, Cmd.none )

        Reset ->
            init ()

        BeltsReceived result ->
            case result of
                Ok belts ->
                    let
                        sortedBelts =
                            List.sortBy .order belts
                    in
                    ( { model | belts = sortedBelts }, Cmd.none )

                Err error ->
                    ( { model | errorMessage = Just ("Error loading belts: " ++ Decode.errorToString error) }, Cmd.none )

        -- Points System Messages
        ShowPointsPage student ->
            ( { model | page = LoadingPage "Loading your points...", loading = True }
            , Cmd.batch
                [ requestStudentPoints student.id
                , requestPointRewards ()
                ]
            )

        ShowRedemptionHistory student ->
            ( { model | page = LoadingPage "Loading your redemption history...", loading = True }
            , requestPointTransactions student.id
            )

        StudentPointsReceived result ->
            case result of
                Ok studentPoints ->
                    case model.page of
                        LoadingPage _ ->
                            case getStudentFromModel model of
                                Just student ->
                                    ( { model
                                        | studentPoints = Just studentPoints
                                        , page = PointsPage student
                                        , loading = False
                                      }
                                    , Cmd.none
                                    )

                                Nothing ->
                                    ( { model | errorMessage = Just "Error loading student data", page = NamePage }, Cmd.none )

                        _ ->
                            ( { model | studentPoints = Just studentPoints, loading = False }, Cmd.none )

                Err error ->
                    ( { model | errorMessage = Just ("Error loading points: " ++ Decode.errorToString error), page = NamePage }, Cmd.none )

        PointRewardsReceived result ->
            case result of
                Ok rewards ->
                    let
                        activeRewards =
                            List.filter .isActive rewards
                                |> List.sortBy .order
                    in
                    ( { model | pointRewards = activeRewards, loading = False }, Cmd.none )

                Err error ->
                    ( { model | errorMessage = Just ("Error loading rewards: " ++ Decode.errorToString error) }, Cmd.none )

        PointTransactionsReceived result ->
            case result of
                Ok transactions ->
                    case getStudentFromModel model of
                        Just student ->
                            let
                                sortedTransactions =
                                    List.sortBy .date transactions |> List.reverse
                            in
                            ( { model
                                | pointTransactions = sortedTransactions
                                , page = RedemptionHistoryPage student
                                , loading = False
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( { model | errorMessage = Just "Error loading student data", page = NamePage }, Cmd.none )

                Err error ->
                    ( { model | errorMessage = Just ("Error loading transaction history: " ++ Decode.errorToString error), page = NamePage }, Cmd.none )

        SelectReward reward ->
            case model.studentPoints of
                Just points ->
                    if points.currentPoints >= reward.pointCost then
                        ( { model | selectedReward = Just reward, showRedemptionConfirm = True }, Cmd.none )

                    else
                        ( { model | errorMessage = Just ("You need " ++ String.fromInt reward.pointCost ++ " points to redeem this reward. You currently have " ++ String.fromInt points.currentPoints ++ " points.") }, Cmd.none )

                Nothing ->
                    ( { model | errorMessage = Just "Error loading your points balance" }, Cmd.none )

        CancelRedemption ->
            ( { model | selectedReward = Nothing, showRedemptionConfirm = False }, Cmd.none )

        ConfirmRedemption ->
            case ( model.selectedReward, model.studentPoints, getStudentFromModel model ) of
                ( Just reward, Just points, Just student ) ->
                    let
                        redemptionData =
                            { rewardId = reward.id
                            , rewardName = reward.name
                            , rewardDescription = reward.description
                            , pointCost = reward.pointCost
                            , studentId = student.id
                            , studentName = student.name
                            }
                    in
                    ( { model
                        | loading = True
                        , selectedReward = Nothing
                        , showRedemptionConfirm = False
                      }
                    , redeemPointReward (encodeRedemption redemptionData)
                    )

                _ ->
                    ( { model | errorMessage = Just "Error processing redemption" }, Cmd.none )

        RedemptionResult result ->
            if String.startsWith "Error:" result then
                ( { model | errorMessage = Just result, loading = False }, Cmd.none )

            else
                case getStudentFromModel model of
                    Just student ->
                        ( { model
                            | successMessage = Just result
                            , loading = False
                          }
                        , requestStudentPoints student.id
                        )

                    Nothing ->
                        ( { model | errorMessage = Just "Error refreshing data", loading = False }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ studentFound (decodeStudentResponse >> StudentFoundResult)
        , submissionResult SubmissionSaved
        , receiveBelts (decodeBeltsResponse >> BeltsReceived)
        , receiveStudentPoints (decodeStudentPointsResponse >> StudentPointsReceived)
        , receivePointRewards (decodePointRewardsResponse >> PointRewardsReceived)
        , receivePointTransactions (decodePointTransactionsResponse >> PointTransactionsReceived)
        , pointRedemptionResult RedemptionResult
        ]



-- HELPER FUNCTIONS


isValidNameFormat : String -> Bool
isValidNameFormat name =
    let
        parts =
            String.split "." name
    in
    List.length parts == 2 && List.all (\part -> String.length part > 0) parts


getGameOptions : String -> List Belt -> List String
getGameOptions beltId belts =
    case List.filter (\b -> b.id == beltId) belts of
        [] ->
            []

        belt :: _ ->
            belt.gameOptions


formatDisplayName : String -> String
formatDisplayName name =
    let
        parts =
            String.split "." name

        firstName =
            List.head parts |> Maybe.withDefault ""

        lastName =
            List.drop 1 parts |> List.head |> Maybe.withDefault ""

        capitalizedFirst =
            String.toUpper (String.left 1 firstName) ++ String.dropLeft 1 firstName

        capitalizedLast =
            String.toUpper (String.left 1 lastName) ++ String.dropLeft 1 lastName
    in
    capitalizedFirst ++ " " ++ capitalizedLast


transactionTypeToString : TransactionType -> String
transactionTypeToString transactionType =
    case transactionType of
        Award ->
            "Points Earned"

        Redemption ->
            "Points Redeemed"


redemptionStatusToString : RedemptionStatus -> String
redemptionStatusToString status =
    case status of
        Pending ->
            "Pending"

        Approved ->
            "Approved"

        Fulfilled ->
            "Fulfilled"

        Cancelled ->
            "Cancelled"


getStudentFromModel : Model -> Maybe Student
getStudentFromModel model =
    case model.page of
        StudentProfilePage student ->
            Just student

        SubmissionFormPage student ->
            Just student

        PointsPage student ->
            Just student

        RedemptionHistoryPage student ->
            Just student

        SubmissionCompletePage student _ ->
            Just student

        _ ->
            Nothing



-- BELT COLOR INDICATOR


viewBeltColorIndicator : String -> List Belt -> Html Msg
viewBeltColorIndicator selectedBeltId belts =
    let
        selectedBelt =
            belts
                |> List.filter (\b -> b.id == selectedBeltId)
                |> List.head
    in
    case selectedBelt of
        Just belt ->
            div
                [ class "absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none" ]
                [ div
                    [ class "w-4 h-4 rounded-full"
                    , style "background-color" belt.color
                    , style "border" "1px solid #ddd"
                    ]
                    []
                ]

        Nothing ->
            text ""



-- JSON ENCODERS & DECODERS


encodeSubmission : Submission -> Encode.Value
encodeSubmission submission =
    Encode.object
        [ ( "id", Encode.string submission.id )
        , ( "studentId", Encode.string submission.studentId )
        , ( "beltLevel", Encode.string submission.beltLevel )
        , ( "gameName", Encode.string submission.gameName )
        , ( "githubLink", Encode.string submission.githubLink )
        , ( "notes", Encode.string submission.notes )
        , ( "submissionDate", Encode.string submission.submissionDate )
        ]


encodeRedemption : { rewardId : String, rewardName : String, rewardDescription : String, pointCost : Int, studentId : String, studentName : String } -> Encode.Value
encodeRedemption redemption =
    Encode.object
        [ ( "rewardId", Encode.string redemption.rewardId )
        , ( "rewardName", Encode.string redemption.rewardName )
        , ( "rewardDescription", Encode.string redemption.rewardDescription )
        , ( "pointCost", Encode.int redemption.pointCost )
        , ( "studentId", Encode.string redemption.studentId )
        , ( "studentName", Encode.string redemption.studentName )
        ]


decodeStudentResponse : Decode.Value -> Result Decode.Error (Maybe Student)
decodeStudentResponse value =
    Decode.decodeValue (Decode.nullable studentDecoder) value


studentDecoder : Decoder Student
studentDecoder =
    Decode.map5 Student
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "created" Decode.string)
        (Decode.field "lastActive" Decode.string)
        (Decode.field "submissions" (Decode.list submissionDecoder))


submissionDecoder : Decoder Submission
submissionDecoder =
    Decode.map8 Submission
        (Decode.field "id" Decode.string)
        (Decode.field "studentId" Decode.string)
        (Decode.field "beltLevel" Decode.string)
        (Decode.field "gameName" Decode.string)
        (Decode.field "githubLink" Decode.string)
        (Decode.field "notes" Decode.string)
        (Decode.field "submissionDate" Decode.string)
        (Decode.maybe (Decode.field "grade" gradeDecoder))


gradeDecoder : Decoder Grade
gradeDecoder =
    Decode.map4 Grade
        (Decode.field "score" Decode.int)
        (Decode.field "feedback" Decode.string)
        (Decode.field "gradedBy" Decode.string)
        (Decode.field "gradingDate" Decode.string)


beltDecoder : Decoder Belt
beltDecoder =
    Decode.map5 Belt
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "color" Decode.string)
        (Decode.field "order" Decode.int)
        (Decode.field "gameOptions" (Decode.list Decode.string))


decodeBeltsResponse : Decode.Value -> Result Decode.Error (List Belt)
decodeBeltsResponse value =
    Decode.decodeValue (Decode.list beltDecoder) value



-- Points System Decoders


studentPointsDecoder : Decoder StudentPoints
studentPointsDecoder =
    Decode.map5 StudentPoints
        (Decode.field "studentId" Decode.string)
        (Decode.field "currentPoints" Decode.int)
        (Decode.field "totalEarned" Decode.int)
        (Decode.field "totalRedeemed" Decode.int)
        (Decode.field "lastUpdated" Decode.string)


decodeStudentPointsResponse : Decode.Value -> Result Decode.Error StudentPoints
decodeStudentPointsResponse value =
    Decode.decodeValue studentPointsDecoder value


pointRewardDecoder : Decoder PointReward
pointRewardDecoder =
    Decode.map8 PointReward
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "pointCost" Decode.int)
        (Decode.field "category" Decode.string)
        (Decode.field "isActive" Decode.bool)
        (Decode.maybe (Decode.field "stock" Decode.int))
        (Decode.field "order" Decode.int)


decodePointRewardsResponse : Decode.Value -> Result Decode.Error (List PointReward)
decodePointRewardsResponse value =
    Decode.decodeValue (Decode.list pointRewardDecoder) value


transactionTypeDecoder : Decoder TransactionType
transactionTypeDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "Award" ->
                        Decode.succeed Award

                    "award" ->
                        Decode.succeed Award

                    "Redemption" ->
                        Decode.succeed Redemption

                    "redemption" ->
                        Decode.succeed Redemption

                    _ ->
                        Decode.fail ("Unknown transaction type: " ++ str)
            )


pointTransactionDecoder : Decoder PointTransaction
pointTransactionDecoder =
    Decode.map8
        (\id studentId studentName transactionType points reason category adminEmail ->
            PointTransaction id studentId studentName transactionType points reason category adminEmail ""
        )
        (Decode.field "id" Decode.string)
        (Decode.field "studentId" Decode.string)
        (Decode.field "studentName" Decode.string)
        (Decode.field "transactionType" transactionTypeDecoder)
        (Decode.field "points" Decode.int)
        (Decode.field "reason" Decode.string)
        (Decode.field "category" Decode.string)
        (Decode.field "adminEmail" Decode.string)
        |> Decode.andThen
            (\transaction ->
                Decode.field "date" Decode.string
                    |> Decode.map (\date -> { transaction | date = date })
            )


decodePointTransactionsResponse : Decode.Value -> Result Decode.Error (List PointTransaction)
decodePointTransactionsResponse value =
    Decode.decodeValue (Decode.list pointTransactionDecoder) value



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-gray-300 py-6 flex flex-col justify-center sm:py-12" ]
        [ div [ class "relative py-3 sm:max-w-4xl sm:mx-auto" ]
            [ div [ class "absolute inset-0 bg-gradient-to-r from-blue-400 to-blue-600 shadow-lg transform -skew-y-6 sm:skew-y-0 sm:-rotate-6 sm:rounded-lg" ] []
            , div [ class "relative px-4 py-10 bg-gray-100 shadow-lg sm:rounded-lg sm:p-20" ]
                [ div [ class "max-w-4xl mx-auto" ]
                    [ h1 [ class "text-2xl font-semibold text-center text-gray-800 mb-6" ] [ text "Unity Game Submissions" ]
                    , viewPage model
                    , viewError model.errorMessage
                    , viewSuccess model.successMessage
                    ]
                ]
            ]
        ]


viewPage : Model -> Html Msg
viewPage model =
    case model.page of
        NamePage ->
            viewNamePage model

        StudentProfilePage student ->
            viewStudentProfilePage model student

        SubmissionFormPage student ->
            viewSubmissionFormPage model student

        SubmissionCompletePage student submission ->
            viewSubmissionCompletePage model student submission

        PointsPage student ->
            viewPointsPage model student

        RedemptionHistoryPage student ->
            viewRedemptionHistoryPage model student

        LoadingPage message ->
            viewLoading message


viewNamePage : Model -> Html Msg
viewNamePage model =
    div [ class "space-y-6" ]
        [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Student Record Lookup" ]
        , p [ class "text-gray-600" ] [ text "Please enter your name to find your record." ]
        , div [ class "space-y-2" ]
            [ label [ for "studentName", class "block text-sm font-medium text-gray-700" ] [ text "Full Name:" ]
            , input
                [ type_ "text"
                , id "studentName"
                , value model.searchName
                , onInput UpdateSearchName
                , placeholder "firstname.lastname (e.g., tyler.smith)"
                , autofocus True
                , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                ]
                []
            , p [ class "text-sm text-gray-500 mt-1" ]
                [ text "Name must be in format: firstname.lastname" ]
            ]
        , div [ class "mt-4" ]
            [ button
                [ onClick SearchStudent
                , class "w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Find My Record" ]
            ]
        , div [ class "mt-4 bg-amber-50 border border-amber-200 rounded-md p-4 text-center" ]
            [ p [ class "text-sm text-amber-800" ]
                [ text "If you can't find your record, please ask your teacher to create one for you." ]
            ]
        ]


viewStudentProfilePage : Model -> Student -> Html Msg
viewStudentProfilePage model student =
    div [ class "space-y-6" ]
        [ div [ class "border-b border-gray-400 pb-5" ]
            [ div [ class "flex justify-between items-center" ]
                [ h2 [ class "text-xl font-medium text-gray-700" ]
                    [ text ("Welcome, " ++ formatDisplayName student.name) ]
                , button
                    [ onClick BackToSearch
                    , class "text-sm text-gray-600 hover:text-gray-900"
                    ]
                    [ text "Not you? Switch accounts" ]
                ]
            ]

        -- Points Balance Display
        , case model.studentPoints of
            Just points ->
                div [ class "bg-gradient-to-r from-green-400 to-blue-500 rounded-lg p-6 text-white" ]
                    [ div [ class "flex items-center justify-between" ]
                        [ div []
                            [ h3 [ class "text-lg font-medium" ] [ text "Your Points Balance" ]
                            , p [ class "text-3xl font-bold" ] [ text (String.fromInt points.currentPoints) ]
                            , p [ class "text-sm opacity-90" ] [ text ("Total earned: " ++ String.fromInt points.totalEarned ++ " | Total redeemed: " ++ String.fromInt points.totalRedeemed) ]
                            ]
                        , div [ class "text-right" ]
                            [ button
                                [ onClick (ShowPointsPage student)
                                , class "bg-white bg-opacity-20 hover:bg-opacity-30 px-4 py-2 rounded-md text-white font-medium transition"
                                ]
                                [ text "Redeem Points" ]
                            , br [] []
                            , button
                                [ onClick (ShowRedemptionHistory student)
                                , class "mt-2 bg-white bg-opacity-20 hover:bg-opacity-30 px-4 py-2 rounded-md text-white font-medium transition"
                                ]
                                [ text "View History" ]
                            ]
                        ]
                    ]

            Nothing ->
                div [ class "bg-gray-100 rounded-lg p-6 text-center" ]
                    [ p [ class "text-gray-600 mb-4" ] [ text "Loading your points balance..." ]
                    , button
                        [ onClick (ShowPointsPage student)
                        , class "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
                        ]
                        [ text "View Points & Rewards" ]
                    ]

        -- Game Submissions Section
        , div [ class "space-y-4" ]
            [ div [ class "flex justify-between items-center" ]
                [ h3 [ class "text-lg font-medium text-gray-900" ] [ text "Your Game Submissions" ]
                , button
                    [ onClick (StartNewSubmission student)
                    , class "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    ]
                    [ text "Submit New Game" ]
                ]
            , if List.isEmpty student.submissions then
                div [ class "bg-gray-50 rounded-md p-4 text-center" ]
                    [ p [ class "text-gray-500" ] [ text "No submissions yet. Start by submitting your first game!" ] ]

              else
                div [ class "overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg" ]
                    [ table [ class "min-w-full divide-y divide-gray-300" ]
                        [ thead [ class "bg-gray-50" ]
                            [ tr []
                                [ th [ class "py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6" ] [ text "Game" ]
                                , th [ class "px-3 py-3.5 text-left text-sm font-semibold text-gray-900" ] [ text "Belt" ]
                                , th [ class "px-3 py-3.5 text-left text-sm font-semibold text-gray-900" ] [ text "Submitted" ]
                                , th [ class "px-3 py-3.5 text-left text-sm font-semibold text-gray-900" ] [ text "Grade" ]
                                ]
                            ]
                        , tbody [ class "divide-y divide-gray-400 divide-opacity-4 bg-white" ]
                            (List.map (viewSubmissionRow model) student.submissions)
                        ]
                    ]
            ]
        ]


viewSubmissionRow : Model -> Submission -> Html Msg
viewSubmissionRow model submission =
    let
        beltName =
            let
                matchingBelts =
                    List.filter (\b -> b.id == submission.beltLevel) model.belts
            in
            case matchingBelts of
                [] ->
                    submission.beltLevel

                belt :: _ ->
                    belt.name

        beltColor =
            let
                matchingBelts =
                    List.filter (\b -> b.id == submission.beltLevel) model.belts
            in
            case matchingBelts of
                [] ->
                    "#808080"

                -- Default gray if not found
                belt :: _ ->
                    belt.color
    in
    tr []
        [ td [ class "whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6" ]
            [ text submission.gameName ]
        , td [ class "whitespace-nowrap px-3 py-4 text-sm text-gray-500" ]
            [ div [ class "flex items-center" ]
                [ div [ class "w-3 h-3 mr-2 rounded-full", style "background-color" beltColor ] []
                , text beltName
                ]
            ]
        , td [ class "whitespace-nowrap px-3 py-4 text-sm text-gray-500" ]
            [ text submission.submissionDate ]
        , td [ class "whitespace-nowrap px-3 py-4 text-sm text-gray-500" ]
            [ viewGradeStatus submission.grade ]
        ]


viewGradeStatus : Maybe Grade -> Html Msg
viewGradeStatus maybeGrade =
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
                [ text "Pending" ]


viewSubmissionFormPage : Model -> Student -> Html Msg
viewSubmissionFormPage model student =
    let
        sortedBelts =
            List.sortBy .order model.belts

        gameOptions =
            getGameOptions model.beltLevel model.belts
    in
    div [ class "space-y-6" ]
        [ h2 [ class "text-xl font-medium text-gray-700" ] [ text ("New Submission for " ++ student.name) ]
        , p [ class "text-gray-600" ] [ text "Please provide details about your Unity game submission." ]
        , div [ class "space-y-4" ]
            [ div [ class "space-y-2" ]
                [ label [ for "beltLevel", class "block text-sm font-medium text-gray-700" ] [ text "Belt Level:" ]
                , div [ class "relative" ]
                    [ select
                        [ id "beltLevel"
                        , onInput UpdateBeltLevel
                        , value model.beltLevel
                        , class "mt-1 block w-full bg-white border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm pl-8"
                        ]
                        ([ option [ value "" ] [ text "-- Select Belt --" ] ]
                            ++ List.map
                                (\belt ->
                                    option
                                        [ value belt.id ]
                                        [ text belt.name ]
                                )
                                sortedBelts
                        )
                    , viewBeltColorIndicator model.beltLevel sortedBelts
                    ]
                ]
            , div [ class "space-y-2" ]
                [ label [ for "gameName", class "block text-sm font-medium text-gray-700" ] [ text "Game Name:" ]
                , if model.beltLevel == "" then
                    div [ class "mt-1 p-2 bg-gray-100 border border-gray-300 rounded-md text-sm text-gray-500" ]
                        [ text "Please select a belt level first" ]

                  else if List.isEmpty gameOptions then
                    div [ class "mt-1 p-2 bg-yellow-50 border border-yellow-300 rounded-md text-sm text-yellow-700" ]
                        [ text "No games available for this belt. Please contact your instructor." ]

                  else
                    select
                        [ id "gameName"
                        , onInput UpdateGameName
                        , value model.gameName
                        , class "mt-1 block w-full bg-white border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        ]
                        ([ option [ value "" ] [ text "-- Select Game --" ] ]
                            ++ List.map (\game -> option [ value game ] [ text game ]) gameOptions
                        )
                ]
            , div [ class "space-y-2" ]
                [ label [ for "githubLink", class "block text-sm font-medium text-gray-700" ] [ text "GitHub Repository Link:" ]
                , input
                    [ type_ "url"
                    , id "githubLink"
                    , value model.githubLink
                    , onInput UpdateGithubLink
                    , placeholder "https://github.com/username/repository"
                    , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    []
                ]
            , div [ class "space-y-2" ]
                [ label [ for "notes", class "block text-sm font-medium text-gray-700" ] [ text "Additional Notes:" ]
                , textarea
                    [ id "notes"
                    , value model.notes
                    , onInput UpdateNotes
                    , placeholder "Provide any additional information about your game project"
                    , rows 5
                    , class "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    ]
                    []
                ]
            ]
        , div [ class "flex space-x-4 mt-6" ]
            [ button
                [ onClick BackToProfile
                , class "flex-1 py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Back" ]
            , button
                [ onClick (SubmitForm student)
                , class "flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Submit Game" ]
            ]
        ]


viewSubmissionCompletePage : Model -> Student -> Submission -> Html Msg
viewSubmissionCompletePage model student submission =
    let
        beltName =
            let
                matchingBelts =
                    List.filter (\b -> b.id == submission.beltLevel) model.belts
            in
            case matchingBelts of
                [] ->
                    submission.beltLevel

                belt :: _ ->
                    belt.name
    in
    div [ class "space-y-6" ]
        [ div [ class "text-center" ]
            [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Submission Successful!" ]
            , p [ class "text-gray-600 mt-2" ] [ text ("Thank you, " ++ student.name ++ "! Your Unity game project has been submitted.") ]
            ]
        , div [ class "mt-6 border rounded-md p-4 bg-gray-50" ]
            [ h3 [ class "text-lg font-medium text-gray-700 mb-3" ] [ text "Submission Details:" ]
            , ul [ class "space-y-2" ]
                [ li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Name: " ]
                    , span [ class "text-gray-600" ] [ text student.name ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Belt Level: " ]
                    , span [ class "text-gray-600" ] [ text beltName ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Game Name: " ]
                    , span [ class "text-gray-600" ] [ text submission.gameName ]
                    ]
                , li [ class "border-b border-gray-200 pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "GitHub Link: " ]
                    , a [ href submission.githubLink, target "_blank", class "text-blue-600 hover:text-blue-800" ] [ text submission.githubLink ]
                    ]
                , li [ class "pb-2" ]
                    [ span [ class "font-medium text-gray-700" ] [ text "Notes: " ]
                    , span [ class "text-gray-600" ] [ text submission.notes ]
                    ]
                ]
            ]
        , div [ class "flex space-x-4 mt-6" ]
            [ button
                [ onClick BackToProfile
                , class "flex-1 py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Back to Profile" ]
            , button
                [ onClick (StartNewSubmission student)
                , class "flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                ]
                [ text "Submit Another Game" ]
            ]
        ]


viewPointsPage : Model -> Student -> Html Msg
viewPointsPage model student =
    div [ class "space-y-6" ]
        [ div [ class "flex justify-between items-center" ]
            [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Redeem Your Points" ]
            , button
                [ onClick BackToProfile
                , class "text-gray-500 hover:text-gray-700 flex items-center"
                ]
                [ span [ class "mr-1" ] [ text "←" ]
                , text "Back to Profile"
                ]
            ]

        -- Points Balance
        , case model.studentPoints of
            Just points ->
                div [ class "bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg p-6 text-white" ]
                    [ h3 [ class "text-lg font-medium mb-2" ] [ text "Available Points" ]
                    , p [ class "text-4xl font-bold" ] [ text (String.fromInt points.currentPoints) ]
                    ]

            Nothing ->
                div [ class "bg-gray-100 rounded-lg p-6 text-center" ]
                    [ p [ class "text-gray-600" ] [ text "Loading your points balance..." ] ]

        -- Available Rewards
        , div []
            [ h3 [ class "text-lg font-medium text-gray-900 mb-4" ] [ text "Available Rewards" ]
            , if List.isEmpty model.pointRewards then
                div [ class "bg-yellow-50 border border-yellow-200 rounded-lg p-6 text-center" ]
                    [ div [ class "text-yellow-600 mb-4" ]
                        [ svg [ class "w-12 h-12 mx-auto", fill "currentColor", viewBox "0 0 20 20" ]
                            [ path [ Html.Attributes.attribute "fill-rule" "evenodd", Html.Attributes.attribute "d" "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z", Html.Attributes.attribute "clip-rule" "evenodd" ] []
                            ]
                        ]
                    , h4 [ class "text-lg font-medium text-yellow-800 mb-2" ] [ text "No Rewards Available" ]
                    , p [ class "text-yellow-700" ] [ text "Your teacher hasn't set up any rewards yet. Check back later or ask your teacher about the points system!" ]
                    ]

              else
                div [ class "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ]
                    (List.map (viewRewardCard model) model.pointRewards)
            ]

        -- Redemption Confirmation Modal
        , viewRedemptionConfirmModal model
        ]


viewRewardCard : Model -> PointReward -> Html Msg
viewRewardCard model reward =
    let
        canAfford =
            case model.studentPoints of
                Just points ->
                    points.currentPoints >= reward.pointCost

                Nothing ->
                    False

        isOutOfStock =
            case reward.stock of
                Just stock ->
                    stock <= 0

                Nothing ->
                    False

        cardClass =
            if canAfford && not isOutOfStock then
                "bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transform hover:scale-105 transition-all duration-200 border-2 border-transparent hover:border-blue-500"

            else
                "bg-gray-100 rounded-lg shadow-md p-6 cursor-not-allowed opacity-60"
    in
    div
        [ class cardClass
        , if canAfford && not isOutOfStock then
            onClick (SelectReward reward)

          else
            class ""
        ]
        [ div [ class "flex justify-between items-start mb-4" ]
            [ div []
                [ h4 [ class "text-lg font-semibold text-gray-900" ] [ text reward.name ]
                , p [ class "text-sm text-gray-600" ] [ text reward.category ]
                ]
            , div [ class "text-right" ]
                [ span [ class "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800" ]
                    [ text (String.fromInt reward.pointCost ++ " pts") ]
                ]
            ]
        , p [ class "text-gray-700 mb-4" ] [ text reward.description ]
        , div [ class "flex justify-between items-center" ]
            [ case reward.stock of
                Just stock ->
                    if stock > 0 then
                        span [ class "text-sm text-green-600" ] [ text ("In stock: " ++ String.fromInt stock) ]

                    else
                        span [ class "text-sm text-red-600" ] [ text "Out of stock" ]

                Nothing ->
                    span [ class "text-sm text-green-600" ] [ text "Always available" ]
            , if not canAfford then
                span [ class "text-sm text-red-600" ] [ text "Not enough points" ]

              else if isOutOfStock then
                span [ class "text-sm text-red-600" ] [ text "Unavailable" ]

              else
                span [ class "text-sm text-green-600 font-medium" ] [ text "Click to redeem!" ]
            ]
        ]


viewRedemptionConfirmModal : Model -> Html Msg
viewRedemptionConfirmModal model =
    if model.showRedemptionConfirm then
        case ( model.selectedReward, model.studentPoints ) of
            ( Just reward, Just points ) ->
                div [ class "fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50" ]
                    [ div [ class "bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4" ]
                        [ div [ class "px-6 py-4 bg-blue-50 border-b border-gray-200" ]
                            [ h3 [ class "text-lg font-medium text-blue-800" ] [ text "Confirm Redemption" ]
                            ]
                        , div [ class "p-6" ]
                            [ div [ class "mb-4" ]
                                [ h4 [ class "font-medium text-gray-900 mb-2" ] [ text reward.name ]
                                , p [ class "text-gray-600 mb-4" ] [ text reward.description ]
                                , div [ class "bg-gray-50 p-4 rounded-md" ]
                                    [ div [ class "flex justify-between items-center mb-2" ]
                                        [ span [ class "text-gray-700" ] [ text "Cost:" ]
                                        , span [ class "font-medium text-red-600" ] [ text ("-" ++ String.fromInt reward.pointCost ++ " points") ]
                                        ]
                                    , div [ class "flex justify-between items-center mb-2" ]
                                        [ span [ class "text-gray-700" ] [ text "Current balance:" ]
                                        , span [ class "font-medium" ] [ text (String.fromInt points.currentPoints ++ " points") ]
                                        ]
                                    , div [ class "border-t pt-2 mt-2" ]
                                        [ div [ class "flex justify-between items-center" ]
                                            [ span [ class "font-medium text-gray-900" ] [ text "New balance:" ]
                                            , span [ class "font-bold text-green-600" ] [ text (String.fromInt (points.currentPoints - reward.pointCost) ++ " points") ]
                                            ]
                                        ]
                                    ]
                                ]
                            , div [ class "flex justify-end space-x-3" ]
                                [ button
                                    [ onClick CancelRedemption
                                    , class "px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                                    ]
                                    [ text "Cancel" ]
                                , button
                                    [ onClick ConfirmRedemption
                                    , class "px-4 py-2 border border-transparent rounded-md text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                                    ]
                                    [ text "Confirm Redemption" ]
                                ]
                            ]
                        ]
                    ]

            _ ->
                text ""

    else
        text ""


viewRedemptionHistoryPage : Model -> Student -> Html Msg
viewRedemptionHistoryPage model student =
    div [ class "space-y-6" ]
        [ div [ class "flex justify-between items-center" ]
            [ h2 [ class "text-xl font-medium text-gray-700" ] [ text "Points History" ]
            , button
                [ onClick BackToProfile
                , class "text-gray-500 hover:text-gray-700 flex items-center"
                ]
                [ span [ class "mr-1" ] [ text "←" ]
                , text "Back to Profile"
                ]
            ]

        -- Points Summary
        , case model.studentPoints of
            Just points ->
                div [ class "grid grid-cols-1 md:grid-cols-3 gap-6" ]
                    [ div [ class "bg-green-100 rounded-lg p-6 text-center" ]
                        [ p [ class "text-green-800 font-medium" ] [ text "Total Earned" ]
                        , p [ class "text-3xl font-bold text-green-600" ] [ text (String.fromInt points.totalEarned) ]
                        ]
                    , div [ class "bg-red-100 rounded-lg p-6 text-center" ]
                        [ p [ class "text-red-800 font-medium" ] [ text "Total Redeemed" ]
                        , p [ class "text-3xl font-bold text-red-600" ] [ text (String.fromInt points.totalRedeemed) ]
                        ]
                    , div [ class "bg-blue-100 rounded-lg p-6 text-center" ]
                        [ p [ class "text-blue-800 font-medium" ] [ text "Current Balance" ]
                        , p [ class "text-3xl font-bold text-blue-600" ] [ text (String.fromInt points.currentPoints) ]
                        ]
                    ]

            Nothing ->
                text ""

        -- Transaction History
        , div []
            [ h3 [ class "text-lg font-medium text-gray-900 mb-4" ] [ text "Transaction History" ]
            , if List.isEmpty model.pointTransactions then
                div [ class "bg-gray-50 rounded-lg p-8 text-center" ]
                    [ p [ class "text-gray-500" ] [ text "No point transactions yet. Complete assignments and submit games to earn points!" ]
                    ]

              else
                div [ class "bg-white shadow overflow-hidden sm:rounded-lg" ]
                    [ div [ class "overflow-x-auto" ]
                        [ table [ class "min-w-full divide-y divide-gray-200" ]
                            [ thead [ class "bg-gray-50" ]
                                [ tr []
                                    [ th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Date" ]
                                    , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Type" ]
                                    , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Points" ]
                                    , th [ class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ] [ text "Description" ]
                                    ]
                                ]
                            , tbody [ class "bg-white divide-y divide-gray-200" ]
                                (List.map viewTransactionRow model.pointTransactions)
                            ]
                        ]
                    ]
            ]
        ]


viewTransactionRow : PointTransaction -> Html Msg
viewTransactionRow transaction =
    tr [ class "hover:bg-gray-50" ]
        [ td [ class "px-6 py-4 whitespace-nowrap text-sm text-gray-500" ]
            [ text transaction.date ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ span
                [ class
                    (case transaction.transactionType of
                        Award ->
                            "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"

                        Redemption ->
                            "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"
                    )
                ]
                [ text (transactionTypeToString transaction.transactionType) ]
            ]
        , td [ class "px-6 py-4 whitespace-nowrap" ]
            [ span
                [ class
                    (case transaction.transactionType of
                        Award ->
                            "text-green-600 font-medium"

                        Redemption ->
                            "text-red-600 font-medium"
                    )
                ]
                [ text
                    (case transaction.transactionType of
                        Award ->
                            "+" ++ String.fromInt transaction.points

                        Redemption ->
                            "-" ++ String.fromInt transaction.points
                    )
                ]
            ]
        , td [ class "px-6 py-4 text-sm text-gray-900" ]
            [ text transaction.reason ]
        ]


viewLoading : String -> Html Msg
viewLoading message =
    div [ class "flex flex-col items-center justify-center py-12" ]
        [ div [ class "animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500 mb-4" ] []
        , p [ class "text-gray-600" ] [ text message ]
        ]


viewError : Maybe String -> Html Msg
viewError maybeError =
    case maybeError of
        Just errorMsg ->
            div [ class "mt-4 bg-red-50 border-l-4 border-red-400 p-4" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-shrink-0" ]
                        [ span [ class "text-red-400" ] [ text "!" ] ]
                    , div [ class "ml-3" ]
                        [ p [ class "text-sm text-red-700" ] [ text errorMsg ] ]
                    ]
                ]

        Nothing ->
            text ""


viewSuccess : Maybe String -> Html Msg
viewSuccess maybeSuccess =
    case maybeSuccess of
        Just successMsg ->
            div [ class "mt-4 bg-green-50 border-l-4 border-green-400 p-4" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-shrink-0" ]
                        [ span [ class "text-green-400" ] [ text "✓" ] ]
                    , div [ class "ml-3" ]
                        [ p [ class "text-sm text-green-700" ] [ text successMsg ] ]
                    ]
                ]

        Nothing ->
            text ""
