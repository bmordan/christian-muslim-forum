module About exposing (..)

import Html exposing (text, div, node)
import Html.Attributes exposing (href, src, id, content, rel, name)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Header
import Footer
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw7
        , lh_copy
        , pb3
        , ph3
        )


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
    let
        model =
            { headerModel = Header.initModel
            , footerModel = Footer.initModel
            , content = ""
            }
    in
        ( model, sendRequest )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg
    | FooterMsg Footer.Msg


type alias Model =
    { headerModel : Header.Model
    , footerModel : Footer.Model
    , content : String
    }


type alias Data =
    { pageBy : Page }


type alias Page =
    { content : String
    }


type alias HeaderModel =
    { scrollLeft : Bool
    }


type alias FooterModel =
    { modal : Bool
    , fname : String
    , lname : String
    , email : String
    , message : String
    }


decodeData : Decoder Data
decodeData =
    decode Data
        |> required "pageBy" decodePage


decodePage : Decoder Page
decodePage =
    decode Page
        |> required "content" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" decodeHeaderModel
        |> required "footerModel" decodeFooterModel
        |> required "content" string


decodeHeaderModel : Decoder HeaderModel
decodeHeaderModel =
    decode HeaderModel
        |> required "scrollLeft" bool


decodeFooterModel : Decoder FooterModel
decodeFooterModel =
    decode FooterModel
        |> required "modal" bool
        |> required "fname" string
        |> required "lname" string
        |> required "email" string
        |> required "message" string


pageRequest : Operation Query Variables
pageRequest =
    GraphQl.named "query"
        [ GraphQl.field "pageBy"
            |> GraphQl.withArgument "uri" (GraphQl.string "about-us")
            |> GraphQl.withSelectors [ GraphQl.field "content" ]
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
            ( { model | content = data.pageBy.content }, Cmd.none )

        GotContent (Err err) ->
            ( model, Cmd.none )

        HeaderMsg subMsg ->
            let
                ( updatedHeaderModel, headerCmd ) =
                    Header.update subMsg model.headerModel
            in
                ( { model | headerModel = updatedHeaderModel }, Cmd.map HeaderMsg headerCmd )

        FooterMsg subMsg ->
            let
                ( updatedFooterModel, footerCmd ) =
                    Footer.update subMsg model.footerModel
            in
                ( { model | footerModel = updatedFooterModel }, Cmd.map FooterMsg footerCmd )


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ node "head"
            []
            [ node "link" [ href "https://unpkg.com/tachyons@4.9.0/css/tachyons.min.css", rel "stylesheet" ] []
            , node "link" [ href "/style.css", rel "stylesheet" ] []
            , node "meta" [ name "viewport", content "width=device-width, initial-scale=1.0" ] []
            , node "title" [] [ text "About Us" ]
            , node "script" [ src "https://platform.twitter.com/widgets.js" ] []
            ]
        , node "body"
            [ Html.Attributes.style [ ( "min-height", "100vh" ) ] ]
            [ div [ id "elm-root" ] [ view model ]
            , node "script" [ src "bundle.js" ] []
            , node "script" [ id "elm-js" ] []
            ]
        ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , node "main"
            [ setInnerHtml model.content
            , classes [ ph3, pb3, center, mw7, lh_copy ]
            ]
            []
        , Html.map FooterMsg (Footer.view model.footerModel)
        ]
