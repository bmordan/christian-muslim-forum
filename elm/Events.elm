module Events exposing (..)

import Html exposing (text, div, node)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style, name)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml, head, formatDate, getFeaturedImageSrc, OpenGraphTags, monthToInt)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Header
import Footer
import Dom exposing (Error)
import Dom.Scroll exposing (toTop)
import Task
import Date
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw5
        , mw7
        , mb3
        , lh_copy
        , pa2
        , pb2
        , pb3
        , ph3
        , pl2
        , pl4_ns
        , ph3
        , flex
        , flex_auto
        , flex_none
        , flex_column
        , items_center
        , items_start
        , justify_start
        , justify_between
        , justify_end
        , w_100
        , pv4
        , ph2
        , pv2
        , f2
        , f2_ns
        , f4
        , pb4
        , near_black
        , bg_near_white
        , bg_light_gray
        , bg_dark_red
        , bg_white
        , tc
        , tl
        , tr
        , tl_ns
        , dn_m
        , db_ns
        , dn
        , pa1
        , link
        , b
        , f1_ns
        , f2_m
        , white
        , pl2
        , lh_title
        , lh_copy
        , overflow_y_scroll
        )


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


init : ( Model, Cmd Msg )
init =
    ( { headerModel = Header.initModel
      , events = []
      , year = Nothing
      , month = Nothing
      , day = Nothing
      }
    , Task.perform GotDate <| Date.now
    )


type Msg
    = GotContent (Result Http.Error Data)
    | HeaderMsg Header.Msg
    | GotDate Date.Date


type alias Model =
    { headerModel : Header.Model
    , events : List Event
    , year : Maybe Int
    , month : Maybe Int
    , day : Maybe Int
    }


type alias FeaturedImage =
    { sourceUrl : String }


type alias Data =
    { events : EventsEdges }


type alias EventsEdges =
    { edges : List EventNode
    }


type alias EventNode =
    { node : Event }


type alias Event =
    { slug : String
    , title : String
    , content : String
    , date : String
    , featuredImage : Maybe FeaturedImage
    }


type alias HeaderModel =
    Header.Model



decodeData : Decoder Data
decodeData =
    decode Data
        |> required "events" decodeEventsEdges


decodeEventsEdges : Decoder EventsEdges
decodeEventsEdges =
    decode EventsEdges
        |> required "edges" (Decode.list decodeEventNode)


decodeEventNode : Decoder EventNode
decodeEventNode =
    decode EventNode
        |> required "node" decodeEvent


decodeEvent : Decoder Event
decodeEvent =
    decode Event
        |> required "slug" string
        |> required "title" string
        |> required "content" string
        |> required "date" string
        |> required "featuredImage" (nullable decodeFeaturedImage)


decodeFeaturedImage : Decoder FeaturedImage
decodeFeaturedImage =
    decode FeaturedImage
        |> required "sourceUrl" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" Header.decodeModel
        |> required "events" (Decode.list decodeEvent)
        |> required "year" (nullable int)
        |> required "month" (nullable int)
        |> required "day" (nullable int)


pageRequest : Model -> Operation Query Variables
pageRequest model =
    GraphQl.named "query"
        [ GraphQl.field "events"
            |> GraphQl.withArgument "where"
                (GraphQl.queryArgs
                    [ ( "status", GraphQl.type_ "FUTURE" )
                    , ( "dateQuery"
                      , GraphQl.queryArgs
                            [ ( "after"
                              , GraphQl.queryArgs
                                    [ ( "day", GraphQl.int (Maybe.withDefault 1 model.day) )
                                    , ( "month", GraphQl.int (Maybe.withDefault 1 model.month) )
                                    , ( "year", GraphQl.int (Maybe.withDefault 2018 model.year) )
                                    ]
                              )
                            ]
                      )
                    ]
                )
            |> GraphQl.withSelectors
                [ GraphQl.field "edges"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "node"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "slug"
                                , GraphQl.field "title"
                                , GraphQl.field "content"
                                , GraphQl.field "date"
                                , GraphQl.field "featuredImage"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "sourceUrl"
                                        ]
                                ]
                        ]
                ]
        ]
        |> GraphQl.withVariables []


baseRequest :
    Operation Query Variables
    -> Decoder Data
    -> GraphQl.Request Query Variables Data
baseRequest =
    GraphQl.query graphqlEndpoint


sendRequest : Model -> Cmd Msg
sendRequest model =
    baseRequest (pageRequest model) decodeData
        |> GraphQl.send GotContent


createEvent : EventNode -> Event
createEvent { node } =
    Event node.slug node.title node.content node.date node.featuredImage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotContent (Ok data) ->
            ( { model | events = List.map createEvent data.events.edges }, Cmd.none )

        GotContent (Err err) ->
            ( model, Cmd.none )

        HeaderMsg subMsg ->
            let
                ( updatedHeaderModel, headerCmd ) =
                    Header.update subMsg model.headerModel
            in
                ( { model | headerModel = updatedHeaderModel }, Cmd.map HeaderMsg headerCmd )

        GotDate date ->
            let
                modelWithDate =
                    { model
                        | day = Just (Date.day date)
                        , month = Just (monthToInt (Date.month date))
                        , year = Just (Date.year date)
                    }
            in
                ( modelWithDate, (sendRequest modelWithDate) )


openGraphTags : OpenGraphTags
openGraphTags =
    OpenGraphTags "Events" "What's on? Find out here" (getFeaturedImageSrc Nothing) (frontendUrl ++ "/events")


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ head openGraphTags
        , node "body"
            []
            [ div [ id "elm-root" ] [ view model ]
            , node "script" [ src "events.js" ] []
            , node "script" [ id "elm-js" ] []
            ]
        ]


viewDate : String -> Html.Html Msg
viewDate date =
    div
        [ classes [ flex_none, flex, flex_column, items_center, justify_between, bg_near_white ]
        , classList [ ( "event-date", True ) ]
        ]
        [ div [ classes [ bg_dark_red, white, w_100, tc ] ] [ text (formatDate "%b" date) ]
        , div [ classes [ f2, f2_m, f1_ns, b, tc, w_100, link, near_black, ph3 ] ] [ text (formatDate "%d" date) ]
        , div
            [ classes [ w_100, pa1, dn, db_ns, dn_m, w_100, tc, bg_light_gray, near_black ]
            ]
            [ text (formatDate "%A" date) ]
        ]


viewEvent : Event -> Html.Html Msg
viewEvent { title, slug, content, date, featuredImage } =
    let
        image =
            getFeaturedImageSrc featuredImage
    in
        Html.a
            [ id slug
            , classList [ ( "event", True ) ]
            , href (frontendUrl ++ "/events/" ++ slug)
            ]
            [ div
                [ style [ ( "background-image", "url(" ++ image ++ ")" ) ]
                , classList [ ( "event-img", True ) ]
                ]
                [ div
                    [ classes [ flex, items_center, justify_end, pl2, pl4_ns ]
                    ]
                    [ div
                        [ classes [ flex_auto, white, pl2, pb2 ]
                        , classList [ ( "event-title", True ), ( "bg_trans_yellow", True ) ]
                        ]
                        [ div [ classes [ f2, f1_ns ] ] [ text title ]
                        , div [ classes [ f4 ] ] [ text (formatDate "%a %d %b - %l:%M %P" date) ]
                        ]
                    , div [] [ viewDate date ]
                    ]
                ]
            , div [ classes [ pa2 ], setInnerHtml content ] []
            ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , node "main"
            [ classes [ pb3, center, mw7, lh_copy ]
            , style [ ( "margin-top", "-4rem" ) ]
            ]
            [ if List.isEmpty model.events then
                div [ classList [ ( "loading", True ) ] ] []
              else
                div [ classes [ pb4 ] ]
                    [ div
                        [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                        , classes [ f2, ph2, pv4, w_100, center, mw7, tr ]
                        ]
                        [ text "Events" ]
                    , div [] (List.map viewEvent (List.reverse model.events))
                    ]
            ]
        , Footer.view
        ]
