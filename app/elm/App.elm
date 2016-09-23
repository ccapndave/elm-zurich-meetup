module App exposing (init, update, view, subscriptions)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List.Extra exposing (zip)


type alias Colour = Int


type alias Code =
  (Colour, Colour, Colour, Colour)


type alias Model =
  { correctCode : Code
  , currentGuess : Code
  , guesses : List Code
  }


type Msg
  = Guess Code
  | ChangeColour Int Code


codeToList : Code -> List Colour
codeToList (a, b, c, d) =
  [ a, b, c, d ]


listToCode : List Colour -> Code
listToCode code =
  case code of
    [a, b, c, d] ->
      (a, b, c, d)

    otherwise ->
      Debug.crash "This can't happen!"


cycleColour : Colour -> Colour
cycleColour colour =
  (colour + 1) % 6


countOccurences : a -> List a -> Int
countOccurences x xs =
  xs
    |> List.filter (\x' -> x' == x)
    |> List.length


calculateMatches : Code -> Code -> (Int, Int)
calculateMatches correctCode code =
  let
    blackCount =
      zip (codeToList correctCode) (codeToList code)
        |> List.filterMap (\(a, b) -> if a == b then Just () else Nothing)
        |> List.length

    whiteCount =
      [0..5]
        |> List.map (\colour -> (countOccurences colour (codeToList correctCode), countOccurences colour (codeToList code)))
        |> List.map (\(a, b) -> Basics.min a b)
        |> List.sum
  in
  (blackCount, whiteCount - blackCount)


init : (Model, Cmd Msg)
init =
  { correctCode = (0, 0, 0, 0)
  , currentGuess = (0, 0, 0, 0)
  , guesses = []
  } ! []


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Guess code ->
      { model | guesses = model.guesses ++ [ code ] }
      ! []

    ChangeColour pos (a, b, c, d) ->
      let
        code =
          case pos of
            0 ->
              (cycleColour a, b, c, d)

            1 ->
              (a, cycleColour b, c, d)

            2 ->
              (a, b, cycleColour c, d)

            3 ->
              (a, b, c, cycleColour d)

            otherwise ->
              Debug.crash "Illegal position"
      in
      { model | currentGuess = code } ! []


view : Model -> Html Msg
view model =
  div
    []
    [ renderGuessList model.correctCode model.guesses
    , renderCurrentGuess model.currentGuess
    ]


renderGuessList : Code -> List Code -> Html Msg
renderGuessList correctCode codes =
  ul
    [ class "guess-list" ]
    (codes
      |> List.map (\code ->
        li
          [ class "guess"
          ]
          [ renderCode code
          , renderMatches (calculateMatches correctCode code)
          ]
      )
    )


renderCurrentGuess : Code -> Html Msg
renderCurrentGuess code =
  div
    [ class "current-guess" ]
    [ renderCode code
    , button
        [ onClick <| Guess code
        ]
        [ text "Guess!"
        ]
    ]


renderMatches : (Int, Int) -> Html Msg
renderMatches (blackMatches, whiteMatches) =
  ul
    []
    (
      ([0..(blackMatches - 1)] |> List.map (\_ -> li [ class "match black" ] [])) ++
      ([0..(whiteMatches - 1)] |> List.map (\_ -> li [ class "match white" ] []))
    )


renderCode : Code -> Html Msg
renderCode ((a, b, c, d) as code) =
  ul
    [ class "code"
    ]
    [ renderColour code a 0
    , renderColour code b 1
    , renderColour code c 2
    , renderColour code d 3
    ]


renderColour : Code -> Colour -> Int -> Html Msg
renderColour code colour pos =
  li
    [ class <| "colour colour-" ++ toString colour
    , onClick <| ChangeColour pos code
    ]
    [
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
