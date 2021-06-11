module NormalizeDeclaration exposing (..)

import Elm.Parser
import Elm.Processing exposing (init, process)
import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression exposing (..)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Writer exposing (writeExpression)
import Parser
import StructuredWriter as Writer exposing (..)


normalizeWithoutCheck : String -> String
normalizeWithoutCheck original =
    case Elm.Parser.parse original of
        Err error ->
            "Failed: " ++ Parser.deadEndsToString error

        Ok rawFile ->
            process init rawFile
                |> .declarations
                |> List.map Node.value
                |> List.concatMap normalizeDeclaration
                |> toString


toString : List ( String, Expression ) -> String
toString tests =
    List.map writeTest tests
        |> breaked
        |> write


writeTest : ( String, Expression ) -> Writer
writeTest ( name, code ) =
    [ string name, writeExpression (Node.Node emptyRange code) ]
        |> breaked


normalizeDeclaration : Declaration -> List ( String, Expression )
normalizeDeclaration declaration =
    case declaration of
        Declaration.FunctionDeclaration functionDeclaration ->
            let
                _ =
                    Debug.log "functiondeclaration" "functiondeclaration"
            in
            normalizeFunction functionDeclaration

        _ ->
            []


normalizeFunction : Function -> List ( String, Expression )
normalizeFunction functionDeclaration =
    let
        name =
            functionDeclaration.declaration |> Node.value |> .name |> Node.value

        expression =
            functionDeclaration.declaration |> Node.value |> .expression |> Node.value
    in
    -- This requires the top level function in a test module to be called "tests"
    -- We could instead require it to have a type annotation that specifies a
    -- function with no parameters that returns a Test
    if name == "tests" then
        let
            _ =
                Debug.log "tests function declaration" "tests function declaration"
        in
        normalizeExpression expression

    else
        []


normalizeExpression : Expression -> List ( String, Expression )
normalizeExpression expression =
    case expression of
        Application nodeExpressions ->
            let
                expressions =
                    List.map Node.value nodeExpressions
            in
            case expressions of
                (FunctionOrValue _ functionName) :: xs ->
                    if functionName == "describe" then
                        let
                            _ =
                                Debug.log "describe function application" "describe function application"
                        in
                        normalizeDescribe xs

                    else if functionName == "test" then
                        let
                            _ =
                                Debug.log "test function application" "test function application"
                        in
                        normalizeTest xs

                    else
                        []

                _ ->
                    []

        OperatorApplication operator direction left right ->
            case Node.value left of
                Application nodeExpressions2 ->
                    normalizeExpression (Application (nodeExpressions2 ++ [ right ]))

                _ ->
                    []

        _ ->
            []


{-| describe function should have a string parameter and a
list (of tests or desribe functions, which return a Test)
parameter. We want to process this list
-}
normalizeDescribe : List Expression -> List ( String, Expression )
normalizeDescribe expressions =
    case expressions of
        _ :: (ListExpr testOrDescribes) :: [] ->
            let
                _ =
                    Debug.log "describe" "describe"
            in
            List.concatMap normalizeExpression (List.map Node.value testOrDescribes)

        _ ->
            []


{-| test function should have a string parameter to describe
the test, and then a function for the test. Only lambdas are
supported as the second parameter
-}
normalizeTest : List Expression -> List ( String, Expression )
normalizeTest expressions =
    case expressions of
        (Literal name) :: (LambdaExpression test) :: [] ->
            let
                _ =
                    Debug.log "test" "test"
            in
            [ ( name, Node.value test.expression ) ]

        _ ->
            []
