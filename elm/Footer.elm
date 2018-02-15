module Footer exposing (..)

import Html exposing (nav, a, text, div, img, nav, input)
import Html.Attributes exposing (href, src, style, classList, value, name, placeholder)
import Html.Events exposing (onClick, onInput)
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
        , justify_center
        , items_center
        , items_start
        , self_start
        , self_end
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
        , fr
        , w_50_ns
        , fr_ns
        , mt2
        , tc
        , tr
        , tl_ns
        , bg_white
        )


type Msg
    = Modal
    | Email String
    | Fname String
    | Lname String
    | Subscribe


type alias Model =
    { modal : Bool
    , email : String
    , fname : String
    , lname : String
    }


initModel : Model
initModel =
    Model False "" "" ""


createNavItem : String -> Html.Html Msg
createNavItem item =
    Html.a
        [ href ("/" ++ item)
        , classes [ pl2, white, link ]
        ]
        [ Html.text (String.toUpper (String.left 1 item) ++ String.dropLeft 1 item)
        ]


sendSubscription : Model -> Model
sendSubscription model =
    { modal = False
    , fname = ""
    , lname = ""
    , email = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Modal ->
            ( { model | modal = not model.modal }, Cmd.none )

        Fname fname ->
            ( { model | fname = fname }, Cmd.none )

        Lname lname ->
            ( { model | lname = lname }, Cmd.none )

        Email email ->
            ( { model | email = email }, Cmd.none )

        Subscribe ->
            ( sendSubscription model, Cmd.none )


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


modal : Model -> Html.Html Msg
modal model =
    if not model.modal then
        div [] []
    else
        div
            [ classList [ ( "modal", True ) ]
            , classes [ flex, items_center, justify_center ]
            ]
            [ div
                [ classes [ bg_white, flex, flex_column, justify_between ]
                , classList [ ( "modal-box", True ) ]
                ]
                [ div [ classes [ fr, pa2, tr ], onClick Modal ] [ text "close" ]
                , div [ classes [ flex, flex_column ] ]
                    [ input
                        [ name "fname"
                        , value model.fname
                        , placeholder "First name"
                        , onInput Fname
                        ]
                        []
                    , input
                        [ name "lname"
                        , value model.lname
                        , placeholder "Last name"
                        , onInput Lname
                        ]
                        []
                    , input
                        [ name "email"
                        , value model.email
                        , placeholder "email"
                        , onInput Email
                        ]
                        []
                    ]
                , div
                    [ classList [ ( "double_b_btns", True ) ]
                    , classes [ pb1 ]
                    , onClick Subscribe
                    ]
                    [ text "Subscribe" ]
                ]
            ]


view : Model -> Html.Html Msg
view model =
    div
        [ classes [ w_100, flex, flex_column, justify_between ]
        , classList [ ( "bg_cmf_islamic", True ), ( "footer", True ) ]
        ]
        [ modal model
        , div
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
                        [ div [ classList [ ( "double_b_btns", True ) ], onClick Modal ] [ text "Subscribe" ]
                        , div [ classList [ ( "double_b_btns", True ) ] ] [ text "Follow Us" ]
                        ]
                    ]
                ]
            ]
        , div [ classes [ cf, db, pb1, center ] ]
            [ Html.small [ classes [ tc, white ] ] [ text "Company Registration 5461960 | Charity Registration 1114793" ]
            ]
        ]
