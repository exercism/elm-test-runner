module ExtractTestCode exposing (..)

import Elm.Parser
import Elm.Processing exposing (init, process)
import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression exposing (..)
import Elm.Syntax.Node as Node exposing (Node(..))
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
                |> List.concatMap findTestsInDeclaration
                |> List.map toExtractedTest
                |> Json.Encode.list encode
                |> Json.Encode.encode 2


deadEndsToString : List Parser.DeadEnd -> String
deadEndsToString deadEnds =
    List.map deadEndToString deadEnds
        |> String.join "\n"


deadEndToString : Parser.DeadEnd -> String
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


findTestsInDeclaration : Node Declaration -> List ( String, Expression )
findTestsInDeclaration (Node _ declaration) =
    case declaration of
        Declaration.FunctionDeclaration functionDeclaration ->
            findTestsInFunction [] functionDeclaration

        _ ->
            []


findTestsInFunction : List String -> Function -> List ( String, Expression )
findTestsInFunction path { declaration } =
    let
        (Node _ { expression }) =
            declaration
    in
    findTestsInExpression path expression


findTestsInExpression : List String -> Node Expression -> List ( String, Expression )
findTestsInExpression path (Node _ expression) =
    case expression of
        -- Only detects tests with names as a literal
        Application [ Node _ (FunctionOrValue _ "test"), Node _ (Literal name), Node _ (LambdaExpression test) ] ->
            [ ( (name :: path)
                    |> List.reverse
                    |> List.drop 1
                    |> String.join " > "
              , Node.value test.expression
              )
            ]

        -- Only detects describes with names as a literal
        Application [ Node _ (FunctionOrValue _ "describe"), Node _ (Literal name), tests ] ->
            findTestsInExpression (name :: path) tests

        Application expressions ->
            List.concatMap (findTestsInExpression path) expressions

        OperatorApplication "<|" _ (Node range (Application app)) right ->
            findTestsInExpression path (Node range (Application (app ++ [ right ])))

        OperatorApplication "|>" _ left (Node range (Application app)) ->
            findTestsInExpression path (Node range (Application (app ++ [ left ])))

        OperatorApplication _ _ a b ->
            List.concatMap (findTestsInExpression path) [ a, b ]

        IfBlock _ a b ->
            List.concatMap (findTestsInExpression path) [ a, b ]

        TupledExpression expressions ->
            List.concatMap (findTestsInExpression path) expressions

        ParenthesizedExpression expr ->
            findTestsInExpression path expr

        LetExpression letBlock ->
            List.concatMap (finTestsInLetDeclaration path) letBlock.declarations
                ++ findTestsInExpression path letBlock.expression

        CaseExpression { cases } ->
            List.concatMap (Tuple.second >> findTestsInExpression path) cases

        LambdaExpression lambda ->
            findTestsInExpression path lambda.expression

        RecordExpr records ->
            List.concatMap (\(Node _ ( _, expr )) -> findTestsInExpression path expr) records

        ListExpr list ->
            List.concatMap (findTestsInExpression path) list

        RecordAccess expr _ ->
            findTestsInExpression path expr

        RecordUpdateExpression _ records ->
            List.concatMap (\(Node _ ( _, expr )) -> findTestsInExpression path expr) records

        -- Other variants without recursive expressions
        _ ->
            []


finTestsInLetDeclaration : List String -> Node LetDeclaration -> List ( String, Expression )
finTestsInLetDeclaration path (Node _ letDeclaration) =
    case letDeclaration of
        LetFunction function ->
            findTestsInFunction path function

        LetDestructuring _ expr ->
            findTestsInExpression path expr
