module TwoFer exposing (twoFer)


twoFer : Maybe String -> String
twoFer name =
    let
        _ =
            Debug.log "Log variable" name

        _ =
            Debug.log "Log constant" 42
    in
    "One for you, one for me."
