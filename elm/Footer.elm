module Footer exposing (..)

import Html exposing (nav, a, text, div, img, nav, input, node)
import Html.Attributes exposing (href, src, style, classList, value, name, placeholder)
import Html.Events exposing (onClick, onInput)
import Http exposing (..)
import Config exposing (frontendUrl)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, requiredAt)
import Dom exposing (Error)
import Dom.Scroll exposing (toLeft, toRight)
import Task
import Process
import Time
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
        , tc
        , tr
        , tl_ns
        , bg_white
        , f7
        , br2
        , h4
        )


type Msg
    = Modal
    | Email String
    | Fname String
    | Lname String
    | Subscribe
    | SubscriptionRes (Result Http.Error Subscription)
    | CloseModal


type alias Model =
    { modal : Bool
    , email : String
    , fname : String
    , lname : String
    , message : String
    }


type alias Subscription =
    { status : String
    , fname : String
    , email : String
    }


initModel : Model
initModel =
    Model False "" "" "" ""


subscribtionRequest : Model -> Http.Request Subscription
subscribtionRequest model =
    Http.post (frontendUrl ++ "/subscribe") (Http.jsonBody (encodePayload model)) decodeSubscription


encodePayload : Model -> Encode.Value
encodePayload { email, fname, lname } =
    Encode.object
        [ ( "email", (Encode.string email) )
        , ( "fname", (Encode.string fname) )
        , ( "lname", (Encode.string lname) )
        ]


decodeSubscription : Decoder Subscription
decodeSubscription =
    decode Subscription
        |> required "status" string
        |> required "fname" string
        |> required "email" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "modal" bool
        |> required "email" string
        |> required "fname" string
        |> required "lname" string
        |> required "message" string


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
            ( model, Http.send SubscriptionRes (subscribtionRequest model) )

        SubscriptionRes (Ok res) ->
            ( { model
                | message = "Successfully Subscribed"
              }
            , pauseThen CloseModal
            )

        SubscriptionRes (Err err) ->
            ( { model | message = stringifyError err }, Cmd.none )

        CloseModal ->
            ( { model
                | modal = False
                , message = ""
                , email = ""
                , fname = ""
                , lname = ""
              }
            , Cmd.none
            )


pauseThen : Msg -> Cmd Msg
pauseThen msg =
    Process.sleep (2 * Time.second)
        |> Task.perform (\_ -> msg)


stringifyError : Http.Error -> String
stringifyError err =
    case err of
        BadUrl msg ->
            "Failed. BadUrl" ++ msg

        Timeout ->
            "Failed. Subscription service took too long to respond"

        NetworkError ->
            "Failed. Something is wrong with the connection to the network"

        BadStatus res ->
            "Failed. Something is wrong"

        BadPayload msg res ->
            "Failed. Something is wrong with these values"


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
        , Html.br [] []
        , div [classes [tc, tl_ns]]
          [
            Html.a [ href "https://www.facebook.com/groups/christianmuslimforum/", classes [ link, dib, white, mb1, mr2 ] ] [
                img [src (frontendUrl ++ "/facebook.svg")] []
            ]
            , Html.a [ href "https://twitter.com/ChrisMusForum", classes [ link, dib, white, mb1 ] ] [
                img [src (frontendUrl ++ "/twitter.svg")] []
            ]
          ]
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
                [ classes [ bg_white, flex, flex_column, justify_between, br2 ]
                , classList [ ( "modal-box", True ) ]
                ]
                [ div [ classes [ fr, pa2, tr ], onClick CloseModal ] [ text "close" ]
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
                , if model.message /= "" then
                    div [ classes [ pa3, tc ] ] [ text model.message ]
                  else
                    div [] []
                , div
                    [ classList [ ( "bg_cmf_islamic", True ) ]
                    , classes [ h4, flex, items_center, justify_center ]
                    ]
                    [ div
                        [ classList [ ( "double_b_btns", True ) ]
                        , onClick Subscribe
                        ]
                        [ text "Subscribe" ]
                    ]
                ]
            ]


view : Model -> Html.Html Msg
view model =
    div
        [ classes [ w_100, flex, flex_column, justify_start ]
        , classList [ ( "bg_cmf_islamic", True ), ( "footer", True ) ]
        ]
        [ modal model
        , div
            [ classes [ w_100, db, flex_auto ]
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
                        , Html.a
                            [ href "https://twitter.com/intent/follow?screen_name=ChrisMusForum"
                            , classes [ link ]
                            ]
                            [ div [ classList [ ( "double_b_btns", True ) ] ] [ text "Follow Us" ]
                            ]
                        , Html.a
                            [ href "https://cafdonate.cafonline.org/695#/DonationDetails"
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
