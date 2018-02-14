module Home exposing (..)

import Html exposing (text, div, node)
import Html.Attributes exposing (href, src, id, content, rel, name)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint)
import Header


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }


init : ( Model, Cmd Msg )
init =
    ( Model Header.initModel "" "", sendRequest )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg


type alias Model =
    { headerModel : Header.Model
    , title : String
    , content : String
    }


type alias Data =
    { pageBy : Page }


type alias Page =
    { title : String
    , content : String
    }


type alias HeaderModel =
    { scrollLeft : Bool
    }


decodeData : Decoder Data
decodeData =
    decode Data
        |> required "pageBy" decodePage


decodePage : Decoder Page
decodePage =
    decode Page
        |> required "title" string
        |> required "content" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" decodeHeaderModel
        |> required "title" string
        |> required "content" string


decodeHeaderModel : Decoder HeaderModel
decodeHeaderModel =
    decode HeaderModel
        |> required "scrollLeft" bool


pageRequest : Operation Query Variables
pageRequest =
    GraphQl.named "query"
        [ GraphQl.field "pageBy"
            |> GraphQl.withArgument "uri" (GraphQl.string "home")
            |> GraphQl.withSelectors
                [ GraphQl.field "title"
                , GraphQl.field "content"
                ]
        ]
        |> GraphQl.withVariables []


baseRequest :
    Operation Query Variables
    -> Decoder Data
    -> GraphQl.Request Query Variables Data
baseRequest =
    GraphQl.query graphqlEndpoint


sendRequest : Cmd Msg
sendRequest =
    baseRequest pageRequest decodeData
        |> GraphQl.send GotContent


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotContent (Ok data) ->
            ( { model | title = data.pageBy.title, content = data.pageBy.content }, Cmd.none )

        GotContent (Err err) ->
            ( model, Cmd.none )

        HeaderMsg subMsg ->
            let
                ( updatedHeaderModel, headerCmd ) =
                    Header.update subMsg model.headerModel
            in
                ( { model | headerModel = updatedHeaderModel }, Cmd.map HeaderMsg headerCmd )


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ node "head"
            []
            [ node "link" [ href "https://unpkg.com/tachyons@4.9.0/css/tachyons.min.css", rel "stylesheet" ] []
            , node "link" [ href "/style.css", rel "stylesheet" ] []
            , node "meta" [ name "viewport", content "width=device-width, initial-scale=1.0" ] []
            , node "title" [] [ text model.title ]
            ]
        , node "body"
            []
            [ div [ id "elm-root" ] [ view model ]
            , node "script" [ src "bundle.js" ] []
            , node "script" [ id "elm-js" ] []
            ]
        ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , div [ setInnerHtml model.content ] []
        ]
