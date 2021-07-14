let
    knightIsAwake =
        True
in
canFastAttack knightIsAwake
    |> Expect.equal False
