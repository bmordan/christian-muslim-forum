module Helpers exposing (..)

import Html exposing (text, div, img, text)
import Html.Attributes exposing (href, src, id, content, property, rel, name, classList, style, httpEquiv, size, async)
import Html.Events exposing (keyCode, on)
import Config exposing (frontendUrl)
import Json.Encode as Encode
import Json.Decode as Decode
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Date
import Date.Format as Format
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( db
        , pa3
        , mw7
        , mt4
        , center
        , br_100
        , nr4
        , mr0_ns
        , pr2
        , pl2
        , pr3
        , pv4
        , pr3_ns
        , pl3_ns
        , tr
        , f4
        , f6
        , flex
        , flex_auto
        , flex_none
        , pl3
        , justify_start
        , items_center
        , justify_between
        , flex_column
        , ml0_ns
        , nl4
        , mb6
        , dn
        , db_ns
        , ph3
        , link
        , white
        )


type alias Person =
    { name : String
    , bio : String
    , avatar : String
    , faith : String
    , tags : List Slug
    }


type alias FeaturedImage =
    { sourceUrl : String }


type alias OpenGraphTags =
    { title : String
    , description : String
    , image : String
    , url : String
    }

type alias Slug =
    { slug : String
    , name : String
    }

setInnerHtml : String -> Html.Attribute msg
setInnerHtml str =
    (Html.Attributes.property "innerHTML" (Encode.string str))


chev : Svg.Svg msg
chev =
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


chevBlue : Svg.Svg msg
chevBlue =
    svg
        [ width "8"
        , height "20"
        ]
        [ Svg.path
            [ d "M7.1 9.326l.365.242-.101.153.101.154-.364.242-5.718 8.604-.376-.25L6.82 9.72 1.007.971l.376-.25 5.718 8.605z"
            , stroke "#6BABB5"
            , fill "none"
            ]
            []
        ]


navItems : List String
navItems =
    [ "home"
    , "people"
    , "about"
    , "contact"
    , "resources"
    ]


slugToTitle : String -> String
slugToTitle str =
    String.split "-" str
        |> String.join " "
        |> capitalise


capitalise : String -> String
capitalise str =
    (String.toUpper (String.left 1 str) ++ String.dropLeft 1 str)


forumIcon : Maybe Int -> Html.Html msg
forumIcon commentCount =
    if ((Maybe.withDefault 0 commentCount) < 1) then
        div [] []
    else
        img
            [ src (frontendUrl ++ "/forum.svg")
            , classList [ ( "article-forum-icon", True ) ]
            ]
            []


trim160 : String -> String
trim160 str =
    ((String.slice 0 120 str) ++ "...")


head : OpenGraphTags -> Html.Html msg
head { title, description, image, url } =
    node "head"
        []
        [ node "script" [ async True, src "https://www.googletagmanager.com/gtag/js?id=UA-101196212-1"] []
        , node "script" [ Html.Attributes.id "gtag"] []
        , node "link" [ href "https://unpkg.com/tachyons@4.9.0/css/tachyons.min.css", rel "stylesheet" ] []
        , node "link" [ href "/style.css", rel "stylesheet" ] []
        , node "meta" [ Html.Attributes.name "viewport", content "width=device-width, initial-scale=1.0" ] []
        , node "meta" [ httpEquiv "Content-Security-Policy", content "default-src 'self'; font-src 'self' data: fonts.gstatic.com;" ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-57x57.png") ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-60x60.png") ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-72x72.png") ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-76x76.png") ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-114x114.png") ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-120x120.png") ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-144x144.png") ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-152x152.png") ] []
        , node "link" [ rel "apple-touch-icon", href (frontendUrl ++ "/apple-icon-180x180.png") ] []
        , node "link" [ rel "icon", href (frontendUrl ++ "/apple-icon-192x192.png") ] []
        , node "link" [ rel "icon", href (frontendUrl ++ "/apple-icon-32x32.png") ] []
        , node "link" [ rel "icon", href (frontendUrl ++ "/apple-icon-96x96.png") ] []
        , node "link" [ rel "icon", href (frontendUrl ++ "/apple-icon-16x16.png") ] []
        , node "link" [ rel "manifest", href (frontendUrl ++ "/manifest.json") ] []
        , node "meta" [ Html.Attributes.name "msapplication-TileColor", content "#ffffff" ] []
        , node "meta" [ Html.Attributes.name "msapplication-TileImage", content image ] []
        , node "meta" [ Html.Attributes.name "twitter:card", content "summary" ] []
        , node "meta" [ Html.Attributes.name "twitter:site", content "@ChrisMusForum" ] []
        , node "meta" [ Html.Attributes.name "twitter:creator", content "@ChrisMusForum" ] []
        , node "meta" [ Html.Attributes.id "og:title", Html.Attributes.property "property" (Encode.string "og:title"), content title ] []
        , node "meta" [ Html.Attributes.id "og:site_name", Html.Attributes.property "property" (Encode.string "og:site_name"), content "Christian Muslim Forum" ] []
        , node "meta" [ Html.Attributes.id "og:description", Html.Attributes.property "property" (Encode.string "og:description"), content description ] []
        , node "meta" [ Html.Attributes.id "og:image", Html.Attributes.property "property" (Encode.string "og:image"), content image ] []
        , node "meta" [ Html.Attributes.id "og:url", Html.Attributes.property "property" (Encode.string "og:url"), content url ] []
        , node "meta" [ Html.Attributes.id "og:type", Html.Attributes.property "property" (Encode.string "og:type"), content "article" ] []
        , node "meta" [ Html.Attributes.id "og:locale", Html.Attributes.property "property" (Encode.string "og:locale"), content "en_GB" ] []
        , node "title" [] [ Html.text title ]
        ]


viewRoleFromTag : List Slug -> String
viewRoleFromTag tags =
    List.filter(\({slug}) -> slug /= "christian") tags
        |> List.filter(\({slug}) -> slug /= "muslim")
        |> List.head
        |> Maybe.withDefault { slug = "contributor", name = "Contributor" }
        |> .name


viewPerson : Bool -> Person -> Html.Html msg
viewPerson withBio person =
    div [ classes [ pv4 ] ]
        [ div [ classList [ ( "person", True ) ] ]
            [ if (String.toLower person.faith) == "christian" then
                viewChristianPerson withBio person
              else
                viewMuslimPerson withBio person
            ]
        , if withBio then
            div [] []
          else
            div
                [ classes [ db, pa3, mw7, mt4, center ]
                , setInnerHtml person.bio
                ]
                []
        ]


viewChristianPerson : Bool -> Person -> Html.Html msg
viewChristianPerson withBio person =
    div
        [ classes [ flex, items_center, justify_start, mw7, center ]
        , classList [ ( "person", True ) ]
        ]
        [ div
            [ classes [ br_100, flex_none, nl4, ml0_ns ]
            , classList [ ( "avatar", True ) ]
            , Html.Attributes.style [ ( "background-image", "url(" ++ person.avatar ++ ")" ) ]
            ]
            []
        , div [ classes [ flex_auto, flex, flex_column, justify_between ] ]
            [ div
                [ classes [ f4, pl2, pl3_ns ]
                ]
                [ Html.text person.name ]
            , if withBio then
                div [ classes [ f6, dn, db_ns, ph3 ] ] [ Html.text (trim160 person.bio) ]
              else
                div
                    [ classes [ pl2, pl3_ns ]
                    ]
                    [ Html.text (viewRoleFromTag person.tags) ]
            ]
        , img [ src (frontendUrl ++ "/" ++ (String.toLower person.faith) ++ ".svg"), classes [ flex_none, pr3 ], classList [ ( "icon", True ) ] ] []
        ]


viewMuslimPerson : Bool -> Person -> Html.Html msg
viewMuslimPerson withBio person =
    div
        [ classes [ flex, items_center, justify_start, mw7, center ]
        , classList [ ( "person", True ) ]
        ]
        [ img
            [ src (frontendUrl ++ "/" ++ (String.toLower person.faith) ++ ".svg")
            , classes [ flex_none, pl3 ]
            , classList [ ( "icon", True ) ]
            ]
            []
        , div [ classes [ flex_auto ] ]
            [ div
                [ classes [ f4, pr2, pr3_ns, tr ]
                ]
                [ Html.text person.name ]
            , if withBio then
                div [ classes [ f6, dn, db_ns, ph3, tr ] ] [ Html.text (trim160 person.bio) ]
              else
                div
                    [ classes [ pr2, pr3_ns, tr ]
                    ]
                    [ Html.text (viewRoleFromTag person.tags) ]
            ]
        , div
            [ classes [ br_100, flex_none, nr4, mr0_ns ]
            , classList [ ( "avatar", True ) ]
            , Html.Attributes.style [ ( "background-image", "url(" ++ person.avatar ++ ")" ) ]
            ]
            []
        ]


formatDate : String -> String -> String
formatDate formatter str =
    let
        date =
        String.left 19 str
        |> String.split " "
        |> String.join "T"
        |> Date.fromString
    in
        case date of
            Ok val ->
                Format.format formatter val

            Err err ->
                ""


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)


getFeaturedImageSrc : Maybe FeaturedImage -> String
getFeaturedImageSrc featuredImage =
    case featuredImage of
        Just val ->
            val.sourceUrl

        Nothing ->
            (frontendUrl ++ "/defaultImg.jpg")


createNavItem : String -> Html.Html msg
createNavItem item =
    let
        route =
            if item == "home" then
                ""
            else
                item
    in
        Html.a
            [ href ("/" ++ route)
            , classes [ pl2, white, link ]
            ]
            [ Html.text (capitalise item)
            ]

monthToWord : Date.Date -> String
monthToWord date =
  case (Date.month date) of
    Date.Jan -> "Jan"
    Date.Feb -> "Feb"
    Date.Mar -> "Mar"
    Date.Apr -> "Apr"
    Date.May -> "May"
    Date.Jun -> "Jun"
    Date.Jul -> "Jul"
    Date.Aug -> "Aug"
    Date.Sep -> "Sep"
    Date.Oct -> "Oct"
    Date.Nov -> "Nov"
    Date.Dec -> "Dec"


monthToInt : Date.Month -> Int
monthToInt month =
    case month of
        Date.Jan ->
            1

        Date.Feb ->
            2

        Date.Mar ->
            3

        Date.Apr ->
            4

        Date.May ->
            5

        Date.Jun ->
            6

        Date.Jul ->
            7

        Date.Aug ->
            8

        Date.Sep ->
            9

        Date.Oct ->
            10

        Date.Nov ->
            11

        Date.Dec ->
            12


stripPtags : String -> String
stripPtags str =
    String.split "<p>" str
        |> String.join ""
        |> String.split "</p>"
        |> String.join ""
