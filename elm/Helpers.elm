module Helpers exposing (..)

import Html exposing (text, div, img)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style, httpEquiv)
import Config exposing (frontendUrl)
import Json.Encode as Encode
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
        )


type alias Person =
    { name : String
    , bio : String
    , avatar : String
    , faith : String
    , tags : List String
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


navItems : List String
navItems =
    [ "articles"
    , "people"
    , "about"
    , "contact"
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
            [ src (frontendUrl ++ "/illustrations/forum.svg")
            , classList [ ( "article-forum-icon", True ) ]
            ]
            []


trim160 : String -> String
trim160 str =
    ((String.slice 0 160 str) ++ "...")


head : String -> Html.Html msg
head title =
    node "head"
        []
        [ node "link" [ href "https://unpkg.com/tachyons@4.9.0/css/tachyons.min.css", rel "stylesheet" ] []
        , node "link" [ href "/style.css", rel "stylesheet" ] []
        , node "meta" [ Html.Attributes.name "viewport", content "width=device-width, initial-scale=1.0" ] []
        , node "meta" [ httpEquiv "Content-Security-Policy", content "default-src 'self'; font-src 'self' data: fonts.gstatic.com;" ] []
        , node "title" [] [ Html.text title ]
        , node "script" [ src "https://platform.twitter.com/widgets.js" ] []
        ]


viewRoleFromTag : List String -> String
viewRoleFromTag tags =
    List.head tags
        |> Maybe.withDefault "contributor"
        |> slugToTitle


viewPerson : Bool -> Person -> Html.Html msg
viewPerson withBio person =
    div [ classes [ mt4 ] ]
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
                [ classes [ db, pa3, mw7, mt4, mb6, center ]
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
        , img [ src (frontendUrl ++ "/cross.svg"), classes [ flex_none, pr3 ], classList [ ( "icon", True ) ] ] []
        ]


viewMuslimPerson : Bool -> Person -> Html.Html msg
viewMuslimPerson withBio person =
    div
        [ classes [ flex, items_center, justify_start, mw7, center ]
        , classList [ ( "person", True ) ]
        ]
        [ img
            [ src (frontendUrl ++ "/moon.svg")
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
            Date.fromString str
    in
        case date of
            Ok val ->
                Format.format formatter val

            Err err ->
                ""
