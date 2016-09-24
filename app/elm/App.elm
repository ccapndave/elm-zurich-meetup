module App exposing (init, update, view, subscriptions)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Random
import Config exposing (Config)
import Code exposing (Code, Matches)


config : Config
config =
  { numColours = 6
  , numPins = 4
  }


type alias Model =
  { correctCode : Maybe Code
  , currentGuess : Code
  , guesses : List Code
  }


type Msg
  = SetCorrectCode Code
  | Guess Code
  | ChangeColour Int Code


isCorrect : Config -> Model -> Bool
isCorrect config model =
  Maybe.map2 (Code.isCorrect config) model.correctCode (model.guesses |> List.reverse >> List.head) == Just True


init : (Model, Cmd Msg)
init =
  { correctCode = Nothing
  , currentGuess = Code.empty config
  , guesses = []
  } !
  [ Random.generate SetCorrectCode (Code.codeGenerator config)
  ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SetCorrectCode code ->
      { model | correctCode = Just code } ! []

    Guess code ->
      { model | guesses = model.guesses ++ [ code ] } ! []

    ChangeColour pos code ->
      let
        currentGuess =
          case Code.cycleColourAtPosition config pos code of
            Just code ->
              code

            Nothing ->
              Debug.crash <| "Illegal colour position " ++ toString pos
      in
      { model | currentGuess = currentGuess } ! []


view : Model -> Html Msg
view model =
  if isCorrect config model then
    div
      []
      [ text "You got it!"
      ]
  else
    case model.correctCode of
      Just correctCode ->
        div
          []
          [ renderGuessList correctCode model.guesses
          , renderCurrentGuess model.currentGuess
          ]

      Nothing ->
        div [] []


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
          , renderMatches (Code.calculateMatches correctCode code)
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


renderMatches : Matches -> Html Msg
renderMatches { blackCount, whiteCount } =
  ul
    []
    (
      ([0..(blackCount - 1)] |> List.map (\_ -> li [ class "match black" ] [])) ++
      ([0..(whiteCount - 1)] |> List.map (\_ -> li [ class "match white" ] []))
    )


renderCode : Code -> Html Msg
renderCode code =
  ul
    [ class "code"
    ]
    ([0..3]
      |> List.map (renderColour code)
    )


renderColour : Code -> Int -> Html Msg
renderColour code pos =
  let
    colour =
      case Code.colourAt pos code of
        Just c ->
          c

        Nothing ->
          Debug.crash <| "Illegal colour position " ++ toString pos
  in
  li
    [ class <| "colour colour-" ++ toString colour
    , onClick <| ChangeColour pos code
    ]
    [
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
