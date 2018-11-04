module Header exposing (..)

import Html exposing (nav, a, text, div, img, nav)
import Html.Attributes exposing (href, src, style, classList, id)
import Html.Events exposing (onClick)
import Config exposing (frontendUrl)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required)
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
        , dn_m
        , dn_l
        , db_ns
        , fr_ns
        , w_100
        , z_2
        , top_0
        )


type Msg
    = Show
    | Noop


type alias Model =
    { showMenu: Bool
    }


initModel : Model
initModel =
    Model False


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "showMenu" bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Show -> 
            ( { model | showMenu = not model.showMenu }, Cmd.none )
        Noop ->
            ( model, Cmd.none )

viewMenu : Bool -> Html.Html Msg
viewMenu show =
  if show then
    div [] [text "show"]
  else
    div [] []

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
                [ classes [ flex, items_center, justify_end, fr_ns, pv2 ]
                , classList [("nav-lg", True)]
                ]
                (List.map createNavItem navItems)
            , nav
                [ classes [ white ]
                , classList [("nav-sm", True)]
                ]
                [img [src (frontendUrl ++ "/menu.svg"), onClick (Show)] []
                , (viewMenu model.showMenu)
                ]
            ]
        
        ]
