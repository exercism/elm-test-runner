module SingleDescribeSingleTest exposing (..)

import Expect exposing (Expectation)
import ExtractTestCode
import Json.Encode
import Test exposing (..)


tests : Test
tests =
    test "Can extract single test in describe wrapper" <|
        \_ ->
            """module AnnalynsInfiltrationTests exposing (tests)

import Test exposing (..)

tests : Test
tests =
    describe "AnnalynsInfiltration"
        [ test "Cannot execute fast attack if knight is awake" <|
            \\_ ->
                let
                    knightIsAwake =
                        True
                in
                canFastAttack knightIsAwake
                    |> Expect.equal False
        ]"""
                |> ExtractTestCode.extractTestCode
                |> Expect.equal
                    (Json.Encode.encode 2
                        (Json.Encode.list ExtractTestCode.encode
                            [ { name = "Cannot execute fast attack if knight is awake"
                              , testCode = """let
  
  
  knightIsAwake  =
      True
in
  canFastAttack knightIsAwake |> Expect.equal False"""
                              }
                            ]
                        )
                    )
