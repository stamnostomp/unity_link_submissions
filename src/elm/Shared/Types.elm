module Shared.Types exposing (..)

-- Shared types used across both Admin and Student modules


type alias Student =
    { id : String
    , name : String
    , created : String
    , lastActive : String
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
