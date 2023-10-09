module FuzzTest exposing (..)

import Expect
import ExtractTestCode
import Json.Encode
import Test exposing (..)


tests : Test
tests =
    describe "Can extract tests written with the fuzz family"
        [ test "Can extract a test written with fuzz" <|
            \_ ->
                """module Tests exposing (tests)

import DndCharacter
import Expect
import Fuzz
import Test exposing (Test, describe, fuzzWith, skip, test)


tests : Test
tests =
    describe "DndCharacter"
        [ describe "modifier"
            [ fuzz Fuzz.int "modifier is always smaller than score" <|
                \\score -> Expect.atMost score (DndCharacter.modifier score)
            ]
        , describe "ability"
            [ fuzz (Fuzz.fromGenerator DndCharacter.ability)
                "generated ability should be at least 3"
              <|
                \\ability -> Expect.atLeast 3 ability
            ]
        ]
"""
                    |> ExtractTestCode.extractTestCode
                    |> Expect.equal
                        (Json.Encode.encode 2
                            (Json.Encode.list ExtractTestCode.encode
                                [ { name = "modifier > modifier is always smaller than score"
                                  , testCode =
                                        """fuzz Fuzz.int
 "modifier is always smaller than score"
 (\\score -> Expect.atMost score (DndCharacter.modifier score))"""
                                  }
                                , { name = "ability > generated ability should be at least 3"
                                  , testCode =
                                        """fuzz (Fuzz.fromGenerator DndCharacter.ability)
 "generated ability should be at least 3"
 (\\ability -> Expect.atLeast 3 ability)"""
                                  }
                                ]
                            )
                        )
        , test "Can extract a test written with fuzz2" <|
            \_ ->
                """module Tests exposing (tests)

import DndCharacter
import Expect
import Fuzz
import Test exposing (Test, describe, fuzzWith, skip, test)


tests : Test
tests =
    describe "DndCharacter"
        [ describe "modifier"
            [ fuzz2 Fuzz.int Fuzz.int "two scores can have the same modifier" <|
                \\a b -> (div a / 2 != div b / 2) || modifier a == modifier b
            ]
        , describe "ability"
            [ fuzz2 (Fuzz.fromGenerator DndCharacter.ability)
                (Fuzz.fromGenerator DndCharacter.ability)
                "abilities are never more than 15 apart"
              <|
                \\a b -> Expect.atMost 15 (abs (a - b))
            ]
        ]
"""
                    |> ExtractTestCode.extractTestCode
                    |> Expect.equal
                        (Json.Encode.encode 2
                            (Json.Encode.list ExtractTestCode.encode
                                [ { name = "modifier > two scores can have the same modifier"
                                  , testCode =
                                        """fuzz2 Fuzz.int
 Fuzz.int
 "two scores can have the same modifier"
 (\\a b -> (div a / 2 != div b / 2) || modifier a == modifier b)"""
                                  }
                                , { name = "ability > abilities are never more than 15 apart"
                                  , testCode =
                                        """fuzz2 (Fuzz.fromGenerator DndCharacter.ability)
 (Fuzz.fromGenerator DndCharacter.ability)
 "abilities are never more than 15 apart"
 (\\a b -> Expect.atMost 15 (abs (a - b)))"""
                                  }
                                ]
                            )
                        )
        , test "Can extract a test written with fuzz3" <|
            \_ ->
                """module Tests exposing (tests)

import DndCharacter
import Expect
import Fuzz
import Test exposing (Test, describe, fuzzWith, skip, test)


tests : Test
tests =
    describe "DndCharacter"
        [ describe "modifier"
            [ fuzz3 Fuzz.int Fuzz.int Fuzz.int "three scores can have the same modifier" <|
                \\a b c-> (div a / 2 != div b / 2) || modifier a == modifier b
            ]
        , describe "ability"
            [ fuzz3 (Fuzz.fromGenerator DndCharacter.ability)
                (Fuzz.fromGenerator DndCharacter.ability)
                (Fuzz.fromGenerator DndCharacter.ability)
                "abilities are never more than 15 apart"
              <|
                \\a b c -> Expect.atMost 15 (abs (a - c))
            ]
        ]
"""
                    |> ExtractTestCode.extractTestCode
                    |> Expect.equal
                        (Json.Encode.encode 2
                            (Json.Encode.list ExtractTestCode.encode
                                [ { name = "modifier > three scores can have the same modifier"
                                  , testCode =
                                        """fuzz3 Fuzz.int
 Fuzz.int
 Fuzz.int
 "three scores can have the same modifier"
 (\\a b c -> (div a / 2 != div b / 2) || modifier a == modifier b)"""
                                  }
                                , { name = "ability > abilities are never more than 15 apart"
                                  , testCode =
                                        """fuzz3 (Fuzz.fromGenerator DndCharacter.ability)
 (Fuzz.fromGenerator DndCharacter.ability)
 (Fuzz.fromGenerator DndCharacter.ability)
 "abilities are never more than 15 apart"
 (\\a b c -> Expect.atMost 15 (abs (a - c)))"""
                                  }
                                ]
                            )
                        )
        , test "Can extract a test written with fuzzWith" <|
            \_ ->
                """module Tests exposing (tests)

import DndCharacter
import Expect
import Fuzz
import Test exposing (Test, describe, fuzzWith, skip, test)


tests : Test
tests =
    describe "DndCharacter"
        [ describe "modifier"
            [ fuzzWith
                { runs = 10000, distribution = Test.NoDistribution }
                Fuzz.int "modifier is always smaller than score" <|
                \\score -> Expect.atMost score (DndCharacter.modifier score)
            ]
        , describe "ability"
            [ fuzzWith
                { runs = 10000
                , distribution =
                    Test.expectDistribution
                        [ ( Test.Distribution.atLeast 10, "is 13", (==) 13 )
                        , ( Test.Distribution.atLeast 85, "is not 13", (/=) 13 )
                        ]
                }
                (Fuzz.fromGenerator DndCharacter.ability)
                "13 has an approximate 13% chance of being picked"
            <|
                \\_ -> Expect.pass
            ]
        ]
"""
                    |> ExtractTestCode.extractTestCode
                    |> Expect.equal
                        (Json.Encode.encode 2
                            (Json.Encode.list ExtractTestCode.encode
                                [ { name = "modifier > modifier is always smaller than score"
                                  , testCode =
                                        """fuzzWith {runs = 10000, distribution = Test.NoDistribution}
 Fuzz.int
 "modifier is always smaller than score"
 (\\score -> Expect.atMost score (DndCharacter.modifier score))"""
                                  }
                                , { name = "ability > 13 has an approximate 13% chance of being picked"
                                  , testCode =
                                        """fuzzWith {runs = 10000
, distribution = Test.expectDistribution [(Test.Distribution.atLeast 10, "is 13", (==) 13)
, (Test.Distribution.atLeast 85, "is not 13", (/=) 13)]}
 (Fuzz.fromGenerator DndCharacter.ability)
 "13 has an approximate 13% chance of being picked"
 (\\_ -> Expect.pass)"""
                                  }
                                ]
                            )
                        )
        ]
