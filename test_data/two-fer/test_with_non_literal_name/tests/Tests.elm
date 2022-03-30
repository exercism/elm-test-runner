module Tests exposing (tests)

import Expect
import String
import Test exposing (..)
import TwoFer exposing (twoFer)


tests : Test
tests =
    describe "Two-fer"
        [ test "Normal test" <|
            \() ->
                Expect.equal "One for you, one for me." (twoFer Nothing)
        , skip <|
            let
                testName =
                    "Non literal test name, code will not get extracted"
            in
            test testName <|
                \() ->
                    Expect.equal "One for Alice, one for me." (twoFer (Just "Alice"))
        ]
