module Shared.Utils exposing (..)

import Admin.Types exposing (Msg(..), PointTransaction, TransactionType(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Shared.Types exposing (..)



-- VALIDATION


isValidNameFormat : String -> Bool
isValidNameFormat name =
    let
        parts =
            String.split "." name
    in
    List.length parts == 2 && List.all (\part -> String.length part > 0) parts



-- FORMATTING


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


formatDate : String -> String
formatDate dateString =
    if String.contains "T" dateString then
        let
            dateParts =
                dateString |> String.split "T" |> List.take 2

            date =
                Maybe.withDefault "" (List.head dateParts)

            time =
                case List.drop 1 dateParts |> List.head of
                    Just timeStr ->
                        String.split ":" timeStr |> List.take 2 |> String.join ":"

                    Nothing ->
                        ""
        in
        date ++ " " ++ time

    else
        dateString


pointTransactionDecoder : Decoder PointTransaction
pointTransactionDecoder =
    Decode.map8
        (\id studentId studentName transactionType points reason category adminEmail ->
            PointTransaction id studentId studentName transactionType points reason category adminEmail ""
        )
        (Decode.field "id" Decode.string)
        (Decode.field "studentId" Decode.string)
        (Decode.field "studentName" Decode.string)
        (Decode.field "TransactionType" transactionTypeDecoder)
        (Decode.field "points" Decode.int)
        (Decode.field "reason" Decode.string)
        (Decode.field "category" Decode.string)
        (Decode.field "adminEmail" Decode.string)
        |> Decode.andThen
            (\transaction ->
                Decode.field "date" Decode.string
                    |> Decode.map (\date -> { transaction | date = date })
            )


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

                    _ ->
                        Decode.fail ("Unkown transaction type: " ++ str)
            )


capitalizeWords : String -> String
capitalizeWords str =
    String.join " " (List.map capitalizeWord (String.split " " str))


capitalizeWord : String -> String
capitalizeWord word =
    case String.uncons word of
        Just ( firstChar, rest ) ->
            String.cons (Char.toUpper firstChar) rest

        Nothing ->
            ""



-- ENCODERS


encodeCredentials : String -> String -> Encode.Value
encodeCredentials email password =
    Encode.object
        [ ( "email", Encode.string email )
        , ( "password", Encode.string password )
        ]


encodeGrade : Grade -> Encode.Value
encodeGrade grade =
    Encode.object
        [ ( "score", Encode.int grade.score )
        , ( "feedback", Encode.string grade.feedback )
        , ( "gradedBy", Encode.string grade.gradedBy )
        , ( "gradingDate", Encode.string grade.gradingDate )
        ]


encodeNewStudent : String -> Encode.Value
encodeNewStudent name =
    Encode.object [ ( "name", Encode.string name ) ]


encodeBelt : Belt -> Encode.Value
encodeBelt belt =
    Encode.object
        [ ( "id", Encode.string belt.id )
        , ( "name", Encode.string belt.name )
        , ( "color", Encode.string belt.color )
        , ( "order", Encode.int belt.order )
        , ( "gameOptions", Encode.list Encode.string belt.gameOptions )
        ]


encodeStudentUpdate : Student -> Encode.Value
encodeStudentUpdate student =
    Encode.object
        [ ( "id", Encode.string student.id )
        , ( "name", Encode.string student.name )
        ]


encodeAdminUserUpdate : AdminUser -> Encode.Value
encodeAdminUserUpdate adminUser =
    Encode.object
        [ ( "uid", Encode.string adminUser.uid )
        , ( "email", Encode.string adminUser.email )
        , ( "displayName", Encode.string adminUser.displayName )
        , ( "role", Encode.string adminUser.role )
        ]



-- DECODERS


userDecoder : Decoder User
userDecoder =
    Decode.map4 User
        (Decode.field "uid" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.oneOf
            [ Decode.field "role" Decode.string
            , Decode.succeed "admin"
            ]
        )


studentDecoder : Decoder Student
studentDecoder =
    Decode.map5 Student
        -- Changed from map4 to map5
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "created" Decode.string)
        (Decode.field "lastActive" Decode.string)
        (Decode.maybe (Decode.field "points" studentPointsDecoder))



-- Added this line


gradeDecoder : Decoder Grade
gradeDecoder =
    Decode.map4 Grade
        (Decode.field "score" Decode.int)
        (Decode.field "feedback" Decode.string)
        (Decode.field "gradedBy" Decode.string)
        (Decode.field "gradingDate" Decode.string)


submissionDecoder : Decoder Submission
submissionDecoder =
    Decode.map6
        (\id gameBelt gameName githubLink notes submissionDate ->
            { id = id
            , studentId = ""
            , studentName = "Unknown"
            , beltLevel = gameBelt
            , gameName = gameName
            , githubLink = githubLink
            , notes = notes
            , submissionDate = submissionDate
            , grade = Nothing
            }
        )
        (Decode.field "id" Decode.string)
        (Decode.field "beltLevel" Decode.string)
        (Decode.field "gameName" Decode.string)
        (Decode.field "githubLink" Decode.string)
        (Decode.field "notes" Decode.string)
        (Decode.field "submissionDate" Decode.string)
        |> Decode.andThen
            (\submission ->
                Decode.maybe (Decode.field "studentId" Decode.string)
                    |> Decode.map
                        (\maybeStudentId ->
                            case maybeStudentId of
                                Just studentId ->
                                    { submission | studentId = studentId }

                                Nothing ->
                                    { submission | studentId = submission.id }
                        )
            )
        |> Decode.andThen
            (\submission ->
                Decode.maybe (Decode.field "studentName" Decode.string)
                    |> Decode.map
                        (\maybeStudentName ->
                            case maybeStudentName of
                                Just studentName ->
                                    { submission | studentName = studentName }

                                Nothing ->
                                    { submission | studentName = capitalizeWords (String.replace "-" " " submission.studentId) }
                        )
            )
        |> Decode.andThen
            (\submission ->
                Decode.maybe (Decode.field "grade" gradeDecoder)
                    |> Decode.map (\grade -> { submission | grade = grade })
            )


beltDecoder : Decoder Belt
beltDecoder =
    Decode.map5 Belt
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "color" Decode.string)
        (Decode.field "order" Decode.int)
        (Decode.field "gameOptions" (Decode.list Decode.string))


adminUserDecoder : Decoder AdminUser
adminUserDecoder =
    Decode.map6 AdminUser
        (Decode.field "uid" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.oneOf
            [ Decode.field "role" Decode.string
            , Decode.succeed "admin"
            ]
        )
        (Decode.maybe (Decode.field "createdBy" Decode.string))
        (Decode.maybe (Decode.field "createdAt" Decode.string))



-- POINT SYSTEM DECODERS


studentPointsDecoder : Decoder StudentPoints
studentPointsDecoder =
    Decode.map5 StudentPoints
        -- Changed from map6 to map5
        (Decode.field "studentId" Decode.string)
        (Decode.field "currentPoints" Decode.int)
        (Decode.field "totalEarned" Decode.int)
        (Decode.field "totalRedeemed" Decode.int)
        (Decode.field "lastUpdated" Decode.string)


redemptionStatusDecoder : Decoder RedemptionStatus
redemptionStatusDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "pending" ->
                        Decode.succeed Pending

                    "approved" ->
                        Decode.succeed Approved

                    "fulfilled" ->
                        Decode.succeed Fulfilled

                    "cancelled" ->
                        Decode.succeed Cancelled

                    _ ->
                        Decode.fail ("Unknown redemption status: " ++ str)
            )


pointRedemptionDecoder : Decoder PointRedemption
pointRedemptionDecoder =
    Decode.map8
        (\id studentId studentName pointsRedeemed rewardName rewardDescription redeemedBy redemptionDate ->
            { id = id
            , studentId = studentId
            , studentName = studentName
            , pointsRedeemed = pointsRedeemed
            , rewardName = rewardName
            , rewardDescription = rewardDescription
            , redeemedBy = redeemedBy
            , redemptionDate = redemptionDate
            , status = Pending -- Default status
            }
        )
        (Decode.field "id" Decode.string)
        (Decode.field "studentId" Decode.string)
        (Decode.field "studentName" Decode.string)
        (Decode.field "pointsRedeemed" Decode.int)
        (Decode.field "rewardName" Decode.string)
        (Decode.field "rewardDescription" Decode.string)
        (Decode.field "redeemedBy" Decode.string)
        (Decode.field "redemptionDate" Decode.string)
        |> Decode.andThen
            (\redemption ->
                Decode.field "status" redemptionStatusDecoder
                    |> Decode.map (\status -> { redemption | status = status })
            )


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



-- POINT SYSTEM ENCODERS


encodeStudentPoints : StudentPoints -> Encode.Value
encodeStudentPoints studentPoints =
    Encode.object
        [ ( "studentId", Encode.string studentPoints.studentId )
        , ( "currentPoints", Encode.int studentPoints.currentPoints )
        , ( "totalEarned", Encode.int studentPoints.totalEarned )
        , ( "totalRedeemed", Encode.int studentPoints.totalRedeemed )
        , ( "lastUpdated", Encode.string studentPoints.lastUpdated )
        ]


encodeRedemptionStatus : RedemptionStatus -> Encode.Value
encodeRedemptionStatus status =
    case status of
        Pending ->
            Encode.string "pending"

        Approved ->
            Encode.string "approved"

        Fulfilled ->
            Encode.string "fulfilled"

        Cancelled ->
            Encode.string "cancelled"


encodePointRedemption : PointRedemption -> Encode.Value
encodePointRedemption redemption =
    Encode.object
        [ ( "id", Encode.string redemption.id )
        , ( "studentId", Encode.string redemption.studentId )
        , ( "studentName", Encode.string redemption.studentName )
        , ( "pointsRedeemed", Encode.int redemption.pointsRedeemed )
        , ( "rewardName", Encode.string redemption.rewardName )
        , ( "rewardDescription", Encode.string redemption.rewardDescription )
        , ( "redeemedBy", Encode.string redemption.redeemedBy )
        , ( "redemptionDate", Encode.string redemption.redemptionDate )
        , ( "status", encodeRedemptionStatus redemption.status )
        ]


encodePointReward : PointReward -> Encode.Value
encodePointReward reward =
    Encode.object
        [ ( "id", Encode.string reward.id )
        , ( "name", Encode.string reward.name )
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


encodeAwardPoints : String -> Int -> String -> Encode.Value
encodeAwardPoints studentId points reason =
    Encode.object
        [ ( "studentId", Encode.string studentId )
        , ( "points", Encode.int points )
        , ( "reason", Encode.string reason )
        ]


encodeProcessRedemption : String -> String -> String -> Encode.Value
encodeProcessRedemption redemptionId status processedBy =
    Encode.object
        [ ( "redemptionId", Encode.string redemptionId )
        , ( "status", Encode.string status )
        , ( "processedBy", Encode.string processedBy )
        ]
