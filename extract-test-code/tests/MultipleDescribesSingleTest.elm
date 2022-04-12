module MultipleDescribesSingleTest exposing (..)

import Expect
import ExtractTestCode
import Json.Encode
import Test exposing (..)


tests : Test
tests =
    describe "Can extract tests in multiple describe wrappers"
        [ test "Can extract tests with 2 describe layers" <|
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
                    |> Expect.equal
                        (Json.Encode.encode 2
                            (Json.Encode.list ExtractTestCode.encode
                                [ { name = "AnnalynsInfiltration task 1 > Cannot execute fast attack if knight is awake"
                                  , testCode =
                                        """let
  
  
  knightIsAwake  =
      True
in
  canFastAttack knightIsAwake |> Expect.equal False"""
                                  }
                                , { name = "AnnalynsInfiltration task 2 > Can execute fast attack if knight is sleeping"
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
        , test "Can extract tests with 4 describe layers" <|
            \_ ->
                """module AnnalynsInfiltrationTests exposing (tests)

import Test exposing (..)

tests : Test
tests =
    describe "AnnalynsInfiltration"
        [ describe "layer 2"
            [ describe "layer 3"
                [ describe "layer 4"
                    [ test "Cannot execute fast attack if knight is awake" <|
                        \\_ ->
                            let
                                knightIsAwake =
                                    True
                            in
                            canFastAttack knightIsAwake
                                |> Expect.equal False
                    ]
                ]
            ]
        ]
"""
                    |> ExtractTestCode.extractTestCode
                    |> Expect.equal
                        (Json.Encode.encode 2
                            (Json.Encode.list ExtractTestCode.encode
                                [ { name = "layer 2 > layer 3 > layer 4 > Cannot execute fast attack if knight is awake"
                                  , testCode =
                                        """let
  
  
  knightIsAwake  =
      True
in
  canFastAttack knightIsAwake |> Expect.equal False"""
                                  }
                                ]
                            )
                        )
        ]
