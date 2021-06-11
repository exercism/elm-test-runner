module AnnalynsInfiltrationTests exposing (tests)

import Test exposing (..)

tests : Test
tests =
    describe "AnnalynsInfiltration"
        [ test "Cannot execute fast attack if knight is awake" <|
            \_ ->
                let
                    knightIsAwake =
                        True
                in
                canFastAttack knightIsAwake
                    |> Expect.equal False
        ]
        
