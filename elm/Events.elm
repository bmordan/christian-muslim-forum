module Events exposing (..)

import Html exposing (text, div, node)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style, name)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml, head, formatDate, getFeaturedImageSrc)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Header
import Footer
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw5
        , mw7
        , lh_copy
        , pb3
        , ph3
        , flex
        , flex_auto
        , flex_none
        , flex_column
        , items_center
        , items_start
        , justify_start
        , justify_between
        )


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { headerModel = Header.initModel
            , footerModel = Footer.initModel
            , events = []
            }
    in
        ( model, sendRequest )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg
    | FooterMsg Footer.Msg


type alias Model =
    { headerModel : Header.Model
    , footerModel : Footer.Model
    , events : List Event
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


type alias FooterModel =
    Footer.Model


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
        |> required "footerModel" Footer.decodeModel
        |> required "events" (Decode.list decodeEvent)


pageRequest : Operation Query Variables
pageRequest =
    GraphQl.named "query"
        [ GraphQl.field "events"
            |> GraphQl.withArgument "where" (GraphQl.queryArgs [ ( "status", GraphQl.type_ "FUTURE" ) ])
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


sendRequest : Cmd Msg
sendRequest =
    baseRequest pageRequest decodeData
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

        FooterMsg subMsg ->
            let
                ( updatedFooterModel, footerCmd ) =
                    Footer.update subMsg model.footerModel
            in
                ( { model | footerModel = updatedFooterModel }, Cmd.map FooterMsg footerCmd )


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ head "Events"
        , node "body"
            [ Html.Attributes.style [ ( "min-height", "100vh" ) ] ]
            [ div [ id "elm-root" ] [ view model ]
            , node "script" [ src "bundle.js" ] []
            , node "script" [ id "elm-js" ] []
            ]
        ]


viewFullEvent : Event -> Html.Html Msg
viewFullEvent { slug, title, content, date, featuredImage } =
    let
        image =
            getFeaturedImageSrc featuredImage
    in
        div [ classList [ ( "event", True ) ] ]
            [ Html.a [ name slug ] []
            , div
                [ style [ ( "background-image", "url(" ++ image ++ ")" ) ]
                , classList [ ( "event-img", True ) ]
                , classes [ mw5 ]
                ]
                []
            , div [] [ text title ]
            , div
                [ classes [ flex_none, flex, flex_column, items_center, justify_between ]
                , classList [ ( "event-date", True ) ]
                ]
                [ div [] [ text (formatDate "%b" date) ]
                , div [] [ text (formatDate "%d" date) ]
                , div [] [ text (formatDate "%a" date) ]
                ]
            , div [ setInnerHtml content ] []
            ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , node "main"
            [ classes [ ph3, pb3, center, mw7, lh_copy ]
            ]
            [ if List.isEmpty model.events then
                div [] [ text "As you can see, at present there are no events on our website. Why not follow us on Twitter or subscribe to our mailing list so you'll be the first to hear about our next event." ]
              else
                div [] (List.map viewFullEvent model.events)
            ]
        , Html.map FooterMsg (Footer.view model.footerModel)
        ]
