module Main exposing (..)

import Html.App
import App exposing (init, update, view, subscriptions)

main =
  Html.App.program
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }
