module SingleDescribeMultipleTests exposing (..)

import Expect
import ExtractTestCode
import Json.Encode
import Test exposing (..)


tests : Test
tests =
    test "Can extract multiple tests in describe wrapper" <|
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
        , test "Can execute fast attack if knight is sleeping" <|
            \\_ ->
                let
                    knightIsAwake =
                        False
                in
                canFastAttack knightIsAwake
                    |> Expect.equal True
        ]
"""
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
                            , { name = "Can execute fast attack if knight is sleeping"
                              , testCode =
                                    """let
  
  
  knightIsAwake  =
      False
in
  canFastAttack knightIsAwake |> Expect.equal True"""
                              }
                            ]
                        )
                    )
