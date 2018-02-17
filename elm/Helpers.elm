module Helpers exposing (..)

import Html exposing (..)
import Html.Attributes exposing (href, src)
import Json.Encode as Encode
import Svg exposing (..)
import Svg.Attributes exposing (..)


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
    , "events"
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
