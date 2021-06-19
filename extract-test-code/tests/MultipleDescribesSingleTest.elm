module MultipleDescribesSingleTest exposing (..)

import Expect exposing (Expectation)
import ExtractTestCode
import Test exposing (..)


tests : Test
tests =
    test "Can extract tests in multiple describe wrappers" <|
        \_ ->
            """module AnnalynsInfiltrationTests exposing (tests)

import Test exposing (..)

tests : Test
tests =
    describe "AnnalynsInfiltration"
        [ describe "AnnalynsInfiltration task 1"
            [ test "Cannot execute fast attack if knight is awake" <|
            \\_ ->
                let
                    knightIsAwake =
                        True
                in
                canFastAttack knightIsAwake
                    |> Expect.equal False
            ]
        , describe "AnnalynsInfiltration task 2"
            [ test "Can execute fast attack if knight is sleeping" <|
                \\_ ->
                    let
                        knightIsAwake =
                            False
                    in
                    canFastAttack knightIsAwake
                        |> Expect.equal True
            ]
        ]
"""
                |> ExtractTestCode.extractTestCode
                |> Expect.equal """Cannot execute fast attack if knight is awake
let
  
  
  knightIsAwake  =
      True
in
  canFastAttack knightIsAwake |> Expect.equal False
Can execute fast attack if knight is sleeping
let
  
  
  knightIsAwake  =
      False
in
  canFastAttack knightIsAwake |> Expect.equal True"""
