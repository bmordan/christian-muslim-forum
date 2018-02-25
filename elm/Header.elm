module Header exposing (..)

import Html exposing (nav, a, text, div, img, nav)
import Html.Attributes exposing (href, src, style, classList, id)
import Html.Events exposing (onClick)
import Config exposing (frontendUrl)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required)
import Dom exposing (Error)
import Dom.Scroll exposing (toLeft, toRight)
import Task
import Helpers exposing (chev, navItems, capitalise, createNavItem)
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( fixed
        , flex
        , flex_auto
        , flex_none
        , justify_end
        , items_center
        , items_start
        , pr1
        , pl2
        , pv2
        , pr2
        , pa2
        , white
        , overflow_x_scroll
        , link
        , dn_ns
        , fr_ns
        , w_100
        , z_2
        , top_0
        )


type Msg
    = Scroll
    | Noop


type alias Model =
    { scrollLeft : Bool
    }


initModel : Model
initModel =
    Model False


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "scrollLeft" bool


scrollToLeft : Cmd Msg
scrollToLeft =
    Task.attempt (always Noop) <| toLeft "header-nav"


scrollToRight : Cmd Msg
scrollToRight =
    Task.attempt (always Noop) <| toRight "header-nav"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Scroll ->
            let
                cmd =
                    if model.scrollLeft then
                        scrollToLeft
                    else
                        scrollToRight
            in
                ( { model | scrollLeft = not model.scrollLeft }, cmd )

        Noop ->
            ( model, Cmd.none )


flipChev : Model -> Html.Attribute msg
flipChev model =
    let
        deg =
            if model.scrollLeft then
                "0"
            else
                "180"
    in
        Html.Attributes.style [ ( "transform", "rotate(" ++ deg ++ "deg)" ) ]


view : Model -> Html.Html Msg
view model =
    div
        [ classes [ fixed, z_2, w_100, flex, items_start, justify_end, top_0 ]
        , classList [ ( "bg_cmf_islamic", True ), ( "header", True ) ]
        ]
        [ Html.a [ href "/" ]
            [ img
                [ src (frontendUrl ++ "/cmf-circle-logo.png")
                , classList [ ( "header-img", True ) ]
                , classes [ flex_none ]
                ]
                []
            ]
        , div
            [ classes [ pr2, flex_auto, overflow_x_scroll ]
            , Html.Attributes.style [ ( "width", "200px" ) ]
            , Html.Attributes.id "header-nav"
            ]
            [ nav
                [ classes [ flex, items_center, fr_ns, pv2 ]
                ]
                (List.map createNavItem navItems)
            ]
        , div
            [ classes [ flex_none, items_center, justify_end, pl2, pv2, pr1, dn_ns ]
            , onClick Scroll
            , flipChev model
            ]
            [ chev ]
        ]
