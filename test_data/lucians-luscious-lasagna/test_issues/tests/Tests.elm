module Tests exposing (tests)

import Expect
import LuciansLusciousLasagna exposing (elapsedTimeInMinutes, expectedMinutesInOven, preparationTimeInMinutes)
import Test exposing (..)


tests : Test
tests =
    describe "LuciansLusciousLasagna"
        [ describe "1"
            [ test "all good" <|
                \_ ->
                    expectedMinutesInOven
                        |> Expect.equal 40
            ]
        , describe "2"
            [ skip <|
                test "unexpected skip in concept exercise, will be ran anyway" <|
                    \_ ->
                        preparationTimeInMinutes 2
                            |> Expect.equal 4
            ]
        , test "Missing task ID" <|
            \_ ->
                elapsedTimeInMinutes 3 10
                    |> Expect.equal 16
        , describe "#3"
            [ test "wrong task ID format" <|
                \_ ->
                    elapsedTimeInMinutes 6 30
                        |> Expect.equal 42
            ]
        ]
