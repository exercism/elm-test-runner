module DndCharacter exposing (Character, ability, character, modifier)

import Random exposing (Generator)


type alias Character =
    { strength : Int
    , dexterity : Int
    , constitution : Int
    , intelligence : Int
    , wisdom : Int
    , charisma : Int
    , hitpoints : Int
    }


modifier : Int -> Int
modifier score =
    floor ((toFloat score - 10) / 2)


ability : Generator Int
ability =
    let
        sumOfMaxThree =
            List.sort >> List.reverse >> List.take 3 >> List.sum
    in
    Random.list 4 (Random.int 10 16)
        |> Random.map sumOfMaxThree


character : Generator Character
character =
    Random.constant (Character 1 1 1 1 1 1 1)
