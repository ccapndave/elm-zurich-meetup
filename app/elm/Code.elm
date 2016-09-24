module Code exposing
  ( Code
  , Matches
  , empty
  , codeGenerator
  , cycleColourAtPosition
  , colourAt
  , calculateMatches
  , isCorrect
  )

import Config exposing (Config)
import Random exposing (Generator)
import List.Extra exposing (updateAt, getAt, zip)


type alias Colour = Int


type Code =
  Code (List Colour)


type alias Matches =
  { blackCount : Int
  , whiteCount : Int
  }


empty : Config -> Code
empty { numPins } =
  mkCode (List.repeat numPins 0)


mkCode : List Int -> Code
mkCode colours =
  Code colours


codeGenerator : Config -> Generator Code
codeGenerator { numPins, numColours } =
  Random.list numPins (Random.int 0 (numColours - 1))
    |> Random.map mkCode


cycleColourAtPosition : Config -> Int -> Code -> Maybe Code
cycleColourAtPosition { numColours } pos code =
  case code of
    Code colours ->
      colours
        |> updateAt pos (\colour -> (colour + 1) % numColours)
        |> Maybe.map mkCode


colourAt : Int -> Code -> Maybe Colour
colourAt pos code =
  case code of
    Code colours ->
      colours
        |> getAt pos


countOccurences : a -> List a -> Int
countOccurences x xs =
  xs
    |> List.filter (\x' -> x' == x)
    |> List.length


calculateMatches : Code -> Code -> Matches
calculateMatches correctCode code =
  case (correctCode, code) of
    (Code correctColours, Code colours) ->
      let
        blackCount =
          zip correctColours colours
            |> List.filterMap (\(a, b) -> if a == b then Just () else Nothing)
            |> List.length

        whiteCount =
          [0..5]
            |> List.map (\colour -> (countOccurences colour correctColours, countOccurences colour colours))
            |> List.map (\(a, b) -> Basics.min a b)
            |> List.sum
      in
      { blackCount = blackCount
      , whiteCount = whiteCount - blackCount
      }


isCorrect : Config -> Code -> Code -> Bool
isCorrect { numPins } correctCode code =
  numPins == (calculateMatches correctCode code).blackCount
