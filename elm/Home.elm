module Home exposing (..)

import Html exposing (text, div, node, img)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style, httpEquiv)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml, head)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Slides exposing (slides)
import Header
import Footer
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw7
        , lh_copy
        , ph3
        , tc
        , w4
        , w_60_ns
        , pt3
        , mt7
        , mb7
        , mt3
        , relative
        , absolute
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
            , title = ""
            , content = ""
            , skip = False
            }
    in
        ( model, sendRequest )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg
    | FooterMsg Footer.Msg
    | Skip


type alias Model =
    { headerModel : Header.Model
    , footerModel : Footer.Model
    , title : String
    , content : String
    , skip : Bool
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
        |> required "title" string
        |> required "content" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" decodeHeaderModel
        |> required "footerModel" decodeFooterModel
        |> required "title" string
        |> required "content" string
        |> required "skip" bool


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

        FooterMsg subMsg ->
            let
                ( updatedFooterModel, footerCmd ) =
                    Footer.update subMsg model.footerModel
            in
                ( { model | footerModel = updatedFooterModel }, Cmd.map FooterMsg footerCmd )

        Skip ->
            ( { model | skip = True }, Cmd.none )


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ head model.title
        , node "body"
            []
            [ div [ id "elm-root" ] [ view model ]
            , node "script" [ src "bundle.js" ] []
            , node "script" [ id "elm-js" ] []
            ]
        ]


viewSlide : ( String, String ) -> Html.Html Msg
viewSlide slide =
    div [ classes [ ph3 ] ]
        [ div [ classes [ tc, mt7 ] ]
            [ img
                [ src (Tuple.first slide)
                , classes [ w4 ]
                ]
                []
            ]
        , div
            [ classes [ center, tc, w_60_ns, mb7, mt3 ]
            , classList [ ( "cmf-teal", True ) ]
            ]
            [ text (Tuple.second slide) ]
        ]


view : Model -> Html.Html Msg
view model =
    let
        skip =
            if model.skip then
                Tachyons.Classes.dn
            else
                Tachyons.Classes.db
    in
        div []
            [ Html.map HeaderMsg (Header.view model.headerModel)
            , node "main"
                [ classes [ center, mw7, lh_copy, ph3 ]
                ]
                [ div [ classes [ skip, relative ] ]
                    [ div
                        [ onClick Skip
                        , classList [ ( "double_b_btns", True ), ( "btns_teal", True ) ]
                        , classes [ tc, center, absolute ]
                        , style [ ( "top", "50vh" ) ]
                        ]
                        [ text "Skip Intro" ]
                    , div [ style [ ( "margin-top", "-16rem" ) ] ] (List.map viewSlide slides)
                    ]
                , div [ setInnerHtml model.content ] []
                ]
            , Html.map FooterMsg (Footer.view model.footerModel)
            ]
