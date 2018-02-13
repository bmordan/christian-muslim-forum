module Helpers exposing (setInnerHtml)

import Html exposing (..)
import Html.Attributes exposing (href, src)
import Json.Encode as Encode


setInnerHtml : String -> Html.Attribute msg
setInnerHtml str =
    (Html.Attributes.property "innerHTML" (Encode.string str))
