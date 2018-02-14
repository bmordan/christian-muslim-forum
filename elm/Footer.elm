module Footer exposing (..)

import Html exposing (nav, a, text, div, img, nav)
import Html.Attributes exposing (href, src, style, classList, id)
import Html.Events exposing (onClick)
import Config exposing (frontendUrl)
import Json.Encode as Encode
import Dom exposing (Error)
import Dom.Scroll exposing (toLeft, toRight)
import Task
import Helpers exposing (chev, navItems)
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( flex
        , flex_auto
        , flex_none
        , flex_column
        , justify_end
        , justify_start
        , justify_between
        , items_center
        , items_start
        , pr1
        , pl2
        , pv2
        , pr2
        , pr3
        , pl3
        , pt0_ns
        , pr3_ns
        , pb0_ns
        , pt3
        , pt6
        , pv6
        , pa2
        , pb1
        , white
        , link
        , dn_ns
        , w_100
        , db
        , mw9
        , mb1
        , center
        , ph3
        , cf
        , fl
        , w_50_ns
        , fr_ns
        , mt2
        , tc
        , tl_ns
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
    Task.attempt (always Noop) <| toLeft "footer-nav"


scrollToRight : Cmd Msg
scrollToRight =
    Task.attempt (always Noop) <| toRight "footer-nav"


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


address : Html.Html Msg
address =
    div [ classes [ white, pl3, db ] ]
        [ div [ classes [ mb1, tc, tl_ns ] ] [ text "Christian Muslim Forum" ]
        , div [ classes [ mb1, tc, tl_ns ] ] [ text "200a Pentonville Road" ]
        , div [ classes [ mb1, tc, tl_ns ] ] [ text "King's Cross" ]
        , div [ classes [ mb1, tc, tl_ns ] ] [ text "London N1 9JP" ]
        , Html.br [] []
        , Html.a [ href "tel:02078325841", classes [ link, db, white, mb1, tc, tl_ns ] ] [ text "020 7832 5841" ]
        , Html.a [ href "mailto:info@christianmuslimforum.org", classes [ link, db, white, tc, tl_ns ] ] [ text "info@christianmuslimforum.org" ]
        ]


view : Model -> Html.Html Msg
view model =
    div
        [ classes [ w_100, flex, flex_column, justify_between ]
        , classList [ ( "bg_cmf_islamic", True ), ( "footer", True ) ]
        ]
        [ div
            [ classes [ w_100, db ]
            , Html.Attributes.style [ ( "width", "100vw" ) ]
            , Html.Attributes.id "footer-nav"
            ]
            [ nav
                [ classes [ flex_auto, flex, items_center, justify_end, pv2, pr3 ]
                ]
                (List.map createNavItem navItems)
            ]
        , div [ classes [ mw9, center, w_100, pt6, pt0_ns ] ]
            [ div [ classes [ cf ] ]
                [ div [ classes [ fl, w_100, w_50_ns ] ]
                    [ address ]
                , div [ classes [ fl, w_100, w_50_ns ] ]
                    [ div [ classes [ fr_ns, pv6, pb0_ns, pt0_ns, pr3_ns ] ]
                        [ div [ classList [ ( "double_b_btns", True ) ] ] [ text "Subscribe" ]
                        , div [ classList [ ( "double_b_btns", True ) ] ] [ text "Follow Us" ]
                        ]
                    ]
                ]
            ]
        , div [ classes [ cf, db, pb1, center ] ]
            [ Html.small [ classes [ tc, white ] ] [ text "Company Registration 5461960 | Charity Registration 1114793" ]
            ]
        ]
