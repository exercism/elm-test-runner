module Tests exposing (tests)

import Expect
import String
import Test exposing (..)
import TwoFer exposing (twoFer)


tests : Test
tests =
    describe "Two-fer"
        [ test "No log since test will pass" <|
            \() ->
                Expect.equal "One for you, one for me." (twoFer Nothing)
        , skip <|
            test "Will be logged" <|
                \() ->
                    Expect.equal "One for Alice, one for me." (twoFer (Just "Alice"))
        , skip <|
            test "Will be logged too" <|
                \() ->
                    Expect.equal "One for Bob, one for me." (twoFer (Just "Bob"))
        ]
