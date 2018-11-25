module Footer exposing (..)

import Html exposing (nav, a, text, div, img, nav, input, node)
import Html.Attributes exposing (href, src, style, classList, value, name, placeholder, target)
import Config exposing (frontendUrl)
import Helpers exposing (chev, navItems, createNavItem)
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
        , pa3
        , pb1
        , white
        , red
        , link
        , dn_ns
        , w_100
        , db
        , dib
        , mw9
        , mb1
        , mr2
        , center
        , ph3
        , cf
        , fl
        , fr
        , w_50_ns
        , fr_ns
        , mt2
        , mh2
        , tc
        , tr
        , tl_ns
        , bg_white
        , f7
        , br2
        , h4
        )

address : Html.Html msg
address =
    div [ classes [ white, pl3, db ] ]
        [ div [ classes [ mb1, tc, tl_ns ] ] [ text "Christian Muslim Forum" ]
        , div [ classes [ mb1, tc, tl_ns ] ] [ text "200a Pentonville Road" ]
        , div [ classes [ mb1, tc, tl_ns ] ] [ text "King's Cross" ]
        , div [ classes [ mb1, tc, tl_ns ] ] [ text "London N1 9JP" ]
        , Html.br [] []
        , Html.a [ href "tel:02078325841", classes [ link, db, white, mb1, tc, tl_ns ] ] [ text "020 7832 5841" ]
        , Html.a [ href "mailto:info@christianmuslimforum.org", classes [ link, db, white, tc, tl_ns ] ] [ text "info@christianmuslimforum.org" ]
        , Html.br [] []
        , div [classes [tc, tl_ns]]
          [
            Html.a [ href "https://www.facebook.com/ChrisMusForum", classes [ link, dib, white, mb1 ] ] [
                img [src (frontendUrl ++ "/facebook.svg")] []
            ]
            , Html.a [ href "https://twitter.com/ChrisMusForum", classes [ link, dib, white, mb1, mh2 ] ] [
                img [src (frontendUrl ++ "/twitter.svg")] []
            ]
            , Html.a [ href "https://www.instagram.com/chrismusforum/", classes [ link, dib, white, mb1 ] ] [
                img [src (frontendUrl ++ "/instagram.svg")] []
            ]
          ]
        ]

view : Html.Html msg
view =
    div
        [ classes [ w_100, flex, flex_column, justify_start ]
        , classList [ ( "bg_cmf_islamic", True ), ( "footer", True ) ]
        ]
        [ div
            [ classes [ w_100, db, flex_auto ]
            , Html.Attributes.style [ ( "width", "100vw" ) ]
            , Html.Attributes.id "footer-nav"
            ]
            [ nav
                [ classes [ flex_auto, flex, items_center, justify_end, pv2, pr2, pr3_ns ]
                ]
                (List.map createNavItem navItems)
            ]
        , div [ classes [ mw9, center, w_100, pt6, pt0_ns ] ]
            [ div [ classes [ cf ] ]
                [ div [ classes [ fl, w_100, w_50_ns ] ]
                    [ address ]
                , div [ classes [ fl, w_100, w_50_ns ] ]
                    [ div [ classes [ fr_ns, pv6, pb0_ns, pt0_ns, pr3_ns ] ]
                        [ Html.a
                            [ href "https://christianmuslimforum.us14.list-manage.com/subscribe?u=eceafff6c1e4b765f4437fa07&id=d7f8ff1bcb"
                            ,  target "_blank"
                            , classes [ link ]
                            ]
                            [ div [ classList [ ( "double_b_btns", True ) ] ] [ text "Subscribe" ]
                            ]
                        , Html.a
                            [ href "https://twitter.com/intent/follow?screen_name=ChrisMusForum"
                            ,  target "_blank"
                            , classes [ link ]
                            ]
                            [ div [ classList [ ( "double_b_btns", True ) ] ] [ text "Follow Us" ]
                            ]
                        , Html.a
                            [ href "https://cafdonate.cafonline.org/695#/DonationDetails"
                            ,  target "_blank"
                            , classes [ link ]
                            ]
                            [ div [ classList [ ( "double_b_btns", True ) ] ] [ text "Donate" ]
                            ]
                        ]
                    ]
                ]
            ]
        , div [ classes [ cf, db, pb1, center ] ]
            [ Html.small [ classes [ f7, tc, white ] ] [ text "Company Registration 5461960 | Charity Registration 1114793" ]
            ]
        , node "script" [ src "https://platform.twitter.com/widgets.js" ] []
        ]
