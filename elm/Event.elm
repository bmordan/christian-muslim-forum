module Event exposing (..)

import Html exposing (text, div, node, span)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style, name)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml, head, formatDate, getFeaturedImageSrc, OpenGraphTags, monthToInt, stripPtags)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Header
import Footer
import Search
import Navigation
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
        , tr_ns
        , tl_ns
        , dn_m
        , dn_l
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
        , w_third_ns
        , w_two_thirds_ns
        , fl
        , nt2
        , ph4
        )


main =
    Navigation.program Slug
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( { headerModel = Header.initModel
      , searchModel = Search.initModel
      , events = []
      , event = maybeSlug location
      , year = Nothing
      , month = Nothing
      , day = Nothing
      }
    , Task.perform GotDate <| Date.now
    )


type Msg
    = GotContent (Result Http.Error Data)
    | HeaderMsg Header.Msg
    | SearchMsg Search.Msg
    | Slug Navigation.Location
    | GotDate Date.Date


type alias Model =
    { headerModel : Header.Model
    , searchModel : Search.Model
    , events : List Event
    , event : Maybe String
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
    , excerpt : String
    , content : String
    , date : String
    , featuredImage : Maybe FeaturedImage
    }


type alias HeaderModel =
    Header.Model


type alias SearchModel =
    Search.Model


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
        |> required "excerpt" string
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
        |> required "searchModel" Search.decodeModel
        |> required "events" (Decode.list decodeEvent)
        |> required "event" (nullable string)
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
                                , GraphQl.field "excerpt"
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
    Event node.slug node.title node.excerpt node.content node.date node.featuredImage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotContent (Ok data) ->
            ( { model | events = List.map createEvent data.events.edges }, Cmd.map SearchMsg Search.sendTagsRequest )

        GotContent (Err err) ->
            ( model, Cmd.none )

        HeaderMsg subMsg ->
            let
                ( updatedHeaderModel, headerCmd ) =
                    Header.update subMsg model.headerModel
            in
                ( { model | headerModel = updatedHeaderModel }, Cmd.map HeaderMsg headerCmd )

        SearchMsg subMsg ->
            let
                ( updatedSearchModel, searchCmd ) =
                    Search.update subMsg model.searchModel
            in
                ( { model | searchModel = updatedSearchModel }, Cmd.map SearchMsg searchCmd )

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

        Slug location ->
            ( { model | event = maybeSlug location }, Cmd.none )


maybeSlug : Navigation.Location -> Maybe String
maybeSlug location =
    String.split "/events/" location.pathname
        |> List.reverse
        |> List.head
        |> Maybe.withDefault "/"
        |> String.slice 0 -1
        |> Just


openGraphTags : Model -> OpenGraphTags
openGraphTags model =
    let
        defaultOpenGraphTags =
            OpenGraphTags "Event" "Christian muslim forum event" (getFeaturedImageSrc Nothing) (frontendUrl ++ "/events")
    in
        case model.event of
            Just slug ->
                let
                    event =
                        List.filter (\evt -> evt.slug == slug) model.events
                            |> List.head
                in
                    case event of
                        Just { slug, title, excerpt, featuredImage } ->
                            OpenGraphTags title (stripPtags excerpt) (getFeaturedImageSrc featuredImage) (frontendUrl ++ "/events/" ++ slug)

                        Nothing ->
                            defaultOpenGraphTags

            Nothing ->
                defaultOpenGraphTags


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ head (openGraphTags model)
        , node "body"
            []
            [ div [ id "elm-root" ] []
            , node "script" [ src (frontendUrl ++ "/events/bundle.js") ] []
            , node "script" [ id "elm-js" ] [ text "Elm.Event.embed(document.getElementById(\"elm-root\"))" ]
            ]
        ]


viewShares : Html.Html msg
viewShares =
    div [ classes [ pa2, mw7, center ] ]
        [ div [ classList [ ( "addthis_inline_share_toolbox", True ) ] ] []
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
viewEvent { title, slug, excerpt, content, date, featuredImage } =
    let
        image =
            getFeaturedImageSrc featuredImage
    in
        div
            [ id slug
            , classList [ ( "event", True ) ]
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
                        , div [ classes [ f4 ] ] [ text (formatDate "%a %d %B - %l:%M %P" date) ]
                        ]
                    , div [] [ viewDate date ]
                    ]
                ]
            , div [ classes [ pa2 ], setInnerHtml content ] []
            , viewShares
            ]


viewSmallEvent : Event -> Html.Html Msg
viewSmallEvent { title, slug, excerpt, date, featuredImage } =
    let
        image =
            getFeaturedImageSrc featuredImage
    in
        Html.a
            [ href ("/events/" ++ slug)
            , classList [ ( "event-card", True ) ]
            , classes [ flex, items_center, justify_start, link, bg_white, near_black, lh_title, mw7, center, w_100 ]
            ]
            [ div
                [ classList [ ( "event-card-img", True ) ]
                , style [ ( "background-image", "url(" ++ image ++ ")" ) ]
                , classes [ flex_none ]
                ]
                []
            , div [ classes [ pl2 ] ]
                [ div
                    [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                    , classes [ link ]
                    , setInnerHtml title
                    ]
                    []
                , div
                    [ setInnerHtml excerpt
                    ]
                    []
                ]
            , div
                [ classes [ flex_none, flex, flex_column, items_center, justify_between ]
                , classList [ ( "event-card-date", True ) ]
                ]
                [ div [ classes [ bg_dark_red, white, w_100, tc ] ] [ text (formatDate "%b" date) ]
                , div [ classes [ f2, f2_m, f1_ns, b, tc, w_100, link ] ] [ text (formatDate "%d" date) ]
                , div
                    [ classes [ w_100, pa1, dn, db_ns, dn_m, w_100, tc, bg_light_gray, near_black ]
                    ]
                    [ text (formatDate "%A" date) ]
                ]
            ]


view : Model -> Html.Html Msg
view model =
    let
        event =
            case model.event of
                Just slug ->
                    let
                        featureEvent =
                            List.filter (\e -> e.slug == slug) model.events
                                |> List.head
                    in
                        case featureEvent of
                            Just evt ->
                                viewEvent evt

                            Nothing ->
                                div [] []

                Nothing ->
                    div [] []

        events =
            case model.event of
                Just slug ->
                    List.filter (\e -> e.slug /= slug) model.events

                Nothing ->
                    []
    in
        div []
            [ Html.map HeaderMsg (Header.view model.headerModel)
            , node "main"
                [ classes [ pb3, center, mw7, lh_copy ]
                , style [ ( "margin-top", "-4rem" ) ]
                ]
                [ event ]
            , div [ classes [ fl, w_100, w_two_thirds_ns ] ]
                [ div
                    [ classes [ f2, pv2, ph4 ]
                    , classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                    ]
                    [ text "Other Events" ]
                , div
                    [ classList [ ( "bg_cmf_christian", True ) ]
                    , classes [ pv4 ]
                    ]
                    (List.map viewSmallEvent events)
                ]
            , div [ classes [ fl, w_100, w_third_ns ] ]
                [ div
                    [ classes [ f2, pv2, tr_ns, ph4 ]
                    , classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                    ]
                    [ text "Search"
                    , span [ classes [ dn_m ] ] [ text " Articles" ]
                    ]
                , Html.map SearchMsg (Search.view model.searchModel)
                ]
            , Footer.view
            , node "script" [ src "http://s7.addthis.com/js/300/addthis_widget.js#pubid=ra-5a59d97a9c28847a" ] []
            ]
