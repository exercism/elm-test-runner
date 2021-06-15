module ExtractTestCode exposing (..)

import Elm.Parser
import Elm.Processing exposing (init, process)
import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression exposing (..)
import Elm.Syntax.Node as Node
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Writer exposing (writeExpression)
import Parser
import String exposing (fromInt)
import StructuredWriter exposing (..)


extractTestCode : String -> String
extractTestCode original =
    case Elm.Parser.parse original of
        Err error ->
            "Failed: " ++ deadEndsToString error

        Ok rawFile ->
            process init rawFile
                |> .declarations
                |> List.map Node.value
                |> List.concatMap extractFromDeclaration
                |> testsToString


deadEndsToString deadEnds =
    List.map deadEndToString deadEnds
        |> String.join "/n"


deadEndToString deadEnd =
    "( " ++ fromInt deadEnd.row ++ ", " ++ fromInt deadEnd.col ++ " ): " ++ problemToString deadEnd.problem


problemToString : Parser.Problem -> String
problemToString problem =
    case problem of
        Parser.Expecting string ->
            "Expecting string: " ++ string

        Parser.ExpectingInt ->
            "Expecting int"

        Parser.ExpectingHex ->
            "Expecting int"

        Parser.ExpectingOctal ->
            "Expecting int"

        Parser.ExpectingBinary ->
            "Expecting int"

        Parser.ExpectingFloat ->
            "Expecting int"

        Parser.ExpectingNumber ->
            "Expecting int"

        Parser.ExpectingVariable ->
            "Expecting int"

        Parser.ExpectingSymbol string ->
            "Expecting symbol: " ++ string

        Parser.ExpectingKeyword string ->
            "Expecting keyword: " ++ string

        Parser.ExpectingEnd ->
            "Expecting int"

        Parser.UnexpectedChar ->
            "Expecting int"

        Parser.Problem string ->
            "Expecting keywork: " ++ string

        Parser.BadRepeat ->
            "Bad repeat"


testsToString : List ( String, Expression ) -> String
testsToString tests =
    List.map testToWriter tests
        |> breaked
        |> write


testToWriter : ( String, Expression ) -> Writer
testToWriter ( name, code ) =
    [ string name, writeExpression (Node.Node emptyRange code) ]
        |> breaked


extractFromDeclaration : Declaration -> List ( String, Expression )
extractFromDeclaration declaration =
    case declaration of
        Declaration.FunctionDeclaration functionDeclaration ->
            extractFromFunction functionDeclaration

        _ ->
            []


extractFromFunction : Function -> List ( String, Expression )
extractFromFunction functionDeclaration =
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
        extractFromExpression expression

    else
        []


extractFromExpression : Expression -> List ( String, Expression )
extractFromExpression expression =
    case expression of
        Application nodeExpressions ->
            let
                expressions =
                    List.map Node.value nodeExpressions
            in
            case expressions of
                (FunctionOrValue _ functionName) :: xs ->
                    if functionName == "describe" then
                        extractFromDescribeFunction xs

                    else if functionName == "test" then
                        extractFromTestFunction xs

                    else
                        []

                _ ->
                    []

        OperatorApplication _ _ left right ->
            case Node.value left of
                Application nodeExpressions2 ->
                    extractFromExpression (Application (nodeExpressions2 ++ [ right ]))

                _ ->
                    []

        _ ->
            []


{-| describe function should have a string parameter and a
list (of tests or desribe functions, which return a Test)
parameter. We want to process this list
-}
extractFromDescribeFunction : List Expression -> List ( String, Expression )
extractFromDescribeFunction expressions =
    case expressions of
        _ :: (ListExpr testOrDescribes) :: [] ->
            List.concatMap extractFromExpression (List.map Node.value testOrDescribes)

        _ ->
            []


{-| test function should have a string parameter to describe
the test, and then a function for the test. Only lambdas are
supported as the second parameter
-}
extractFromTestFunction : List Expression -> List ( String, Expression )
extractFromTestFunction expressions =
    case expressions of
        (Literal name) :: (LambdaExpression test) :: [] ->
            [ ( name, Node.value test.expression ) ]

        _ ->
            []
