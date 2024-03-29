module ExtractTestCode exposing (..)

import Elm.Parser
import Elm.Processing exposing (init, process)
import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression exposing (..)
import Elm.Syntax.Infix exposing (InfixDirection(..))
import Elm.Syntax.Node as Node
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Writer exposing (writeExpression)
import Json.Encode
import Parser
import String exposing (fromInt)
import StructuredWriter exposing (..)


type alias ExtractedTest =
    { name : String
    , testCode : String
    }


encode : ExtractedTest -> Json.Encode.Value
encode extractedTest =
    Json.Encode.object
        [ ( "name", Json.Encode.string extractedTest.name )
        , ( "testCode", Json.Encode.string extractedTest.testCode )
        ]


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
                |> List.map toExtractedTest
                |> Json.Encode.list encode
                |> Json.Encode.encode 2


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


toExtractedTest : ( String, Expression ) -> ExtractedTest
toExtractedTest ( name, code ) =
    { name = name
    , testCode =
        writeExpression (Node.Node emptyRange code)
            |> write
    }


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
        extractFromExpression [] expression

    else
        []


extractFromExpression : List String -> Expression -> List ( String, Expression )
extractFromExpression descriptions expression =
    case expression of
        Application nodeExpressions ->
            let
                expressions =
                    List.map Node.value nodeExpressions
            in
            case expressions of
                (FunctionOrValue _ functionName) :: xs ->
                    if functionName == "describe" then
                        extractFromDescribeFunction descriptions xs

                    else if functionName == "test" then
                        extractFromTestFunction descriptions xs

                    else if List.member functionName [ "fuzz", "fuzz2", "fuzz3", "fuzzWith" ] then
                        extractFromFuzzFunction descriptions expressions expression

                    else
                        []

                _ ->
                    []

        OperatorApplication _ _ left right ->
            case Node.value left of
                Application nodeExpressions2 ->
                    extractFromExpression descriptions (Application (nodeExpressions2 ++ [ right ]))

                _ ->
                    []

        _ ->
            []


{-| describe function should have a string parameter and a
list (of tests or desribe functions, which return a Test)
parameter. We want to process this list
-}
extractFromDescribeFunction : List String -> List Expression -> List ( String, Expression )
extractFromDescribeFunction descriptions expressions =
    case expressions of
        (Literal description) :: (ListExpr testOrDescribes) :: [] ->
            List.concatMap (extractFromExpression (description :: descriptions)) (List.map Node.value testOrDescribes)

        _ ->
            []


{-| test function should have a string parameter to describe
the test, and then a function for the test. Only lambdas are
supported as the second parameter
-}
extractFromTestFunction : List String -> List Expression -> List ( String, Expression )
extractFromTestFunction descriptions expressions =
    case expressions of
        (Literal name) :: (LambdaExpression test) :: [] ->
            [ ( buildName name descriptions, Node.value test.expression ) ]

        _ ->
            []


{-| fuzz functions should have a string parameter to describe
the test. The full fuzz function is printed because the arguments
are necessary to understand the test
-}
extractFromFuzzFunction : List String -> List Expression -> Expression -> List ( String, Expression )
extractFromFuzzFunction descriptions expressions topExpression =
    let
        finalExpression =
            case topExpression of
                Application nodeExpressions ->
                    case nodeExpressions |> List.reverse of
                        lambda :: rest ->
                            Application (List.reverse (Node.Node emptyRange (ParenthesizedExpression lambda) :: rest))

                        _ ->
                            topExpression

                _ ->
                    topExpression
    in
    case expressions of
        [ FunctionOrValue _ "fuzz", _, Literal name, _ ] ->
            [ ( buildName name descriptions, finalExpression ) ]

        [ FunctionOrValue _ "fuzz2", _, _, Literal name, _ ] ->
            [ ( buildName name descriptions, finalExpression ) ]

        [ FunctionOrValue _ "fuzz3", _, _, _, Literal name, _ ] ->
            [ ( buildName name descriptions, finalExpression ) ]

        [ FunctionOrValue _ "fuzzWith", _, _, Literal name, _ ] ->
            [ ( buildName name descriptions, finalExpression ) ]

        _ ->
            []


buildName : String -> List String -> String
buildName name descriptions =
    (name :: descriptions)
        |> List.reverse
        |> List.drop 1
        |> String.join " > "
