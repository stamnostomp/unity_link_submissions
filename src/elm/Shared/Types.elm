module Shared.Types exposing (..)

-- Shared types used across both Admin and Student modules


type alias Student =
    { id : String
    , name : String
    , created : String
    , lastActive : String
    , points : Maybe StudentPoints -- Add this line
    }


type alias Submission =
    { id : String
    , studentId : String
    , studentName : String
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


type alias User =
    { uid : String
    , email : String
    , displayName : String
    , role : String
    }


type alias Belt =
    { id : String
    , name : String
    , color : String
    , order : Int
    , gameOptions : List String
    }


type alias AdminUser =
    { uid : String
    , email : String
    , displayName : String
    , role : String
    , createdBy : Maybe String
    , createdAt : Maybe String
    }


type alias StudentPoints =
    { studentId : String
    , currentPoints : Int
    , totalEarned : Int
    , totalRedeemed : Int
    , lastUpdated : String
    }


type alias PointRedemption =
    { id : String
    , studentId : String
    , studentName : String
    , pointsRedeemed : Int
    , rewardName : String
    , rewardDescription : String
    , redeemedBy : String -- Admin who processed the redemption OR student who redeemed
    , redemptionDate : String
    , status : RedemptionStatus
    }


type RedemptionStatus
    = Pending
    | Approved
    | Fulfilled
    | Cancelled


type alias PointReward =
    { id : String
    , name : String
    , description : String
    , pointCost : Int
    , category : String
    , isActive : Bool
    , stock : Maybe Int -- Nothing means unlimited
    , order : Int
    }



-- NEW: Transaction types for tracking all point movements


type alias PointTransaction =
    { id : String
    , studentId : String
    , studentName : String
    , transactionType : TransactionType
    , points : Int
    , reason : String
    , category : String -- "submission", "manual", "redemption", "refund", etc.
    , adminEmail : String -- Who performed the action (or "student-self-redemption")
    , date : String
    }


type TransactionType
    = Award
    | Redemption



-- NEW: Student redemption request type


type alias StudentRedemptionRequest =
    { rewardId : String
    , rewardName : String
    , rewardDescription : String
    , pointCost : Int
    , studentId : String
    , studentName : String
    }
