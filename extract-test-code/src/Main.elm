port module Main exposing (main)

import ExtractTestCode


port stdin : (String -> msg) -> Sub msg


port stdout : String -> Cmd msg


main : Program () () String
main =
    Platform.worker
        { init = always ( (), Cmd.none )
        , subscriptions = \_ -> stdin identity
        , update = \input _ -> ( (), stdout (ExtractTestCode.extractTestCode input) )
        }
