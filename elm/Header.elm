module Header exposing (..)

import Html exposing (nav, a, text, div, img, nav)
import Html.Attributes exposing (href, src, style, classList, id)
import Html.Events exposing (onClick)
import Config exposing (frontendUrl)
import Json.Encode as Encode
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Dom exposing (Error)
import Dom.Scroll exposing (toLeft, toRight)
import Task
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
        , w_100
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


scrollToLeft : Cmd Msg
scrollToLeft =
    Task.attempt (always Noop) <| toLeft "header-nav"


scrollToRight : Cmd Msg
scrollToRight =
    Task.attempt (always Noop) <| toRight "header-nav"


chevRight : Svg.Svg msg
chevRight =
    svg
        [ width "8"
        , height "20"
        ]
        [ Svg.path
            [ d "M7.1 9.326l.365.242-.101.153.101.154-.364.242-5.718 8.604-.376-.25L6.82 9.72 1.007.971l.376-.25 5.718 8.605z"
            , stroke "#FBFBFB"
            , fill "none"
            ]
            []
        ]


navItems : List String
navItems =
    [ "articles"
    , "events"
    , "people"
    , "about"
    , "contact"
    ]


createNavItem : String -> Html.Html Msg
createNavItem item =
    Html.a
        [ href ("/" ++ item)
        , classes [ pl2, white, link ]
        ]
        [ Html.text (String.toUpper (String.left 1 item) ++ String.dropLeft 1 item)
        ]


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
    div [ classes [ fixed, w_100, flex, items_start, justify_end ], classList [ ( "bg_cmf_islamic", True ) ] ]
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
                [ classes [ flex_auto, flex, items_center, pv2 ]
                ]
                (List.map createNavItem navItems)
            ]
        , div
            [ classes [ flex_none, items_center, justify_end, pl2, pv2, pr1, dn_ns ]
            , onClick Scroll
            , flipChev model
            ]
            [ chevRight ]
        ]
