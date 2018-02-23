module Home exposing (..)

import Html exposing (text, div, node, img)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style, httpEquiv)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml, head)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Slides exposing (slides)
import Header
import Footer
import Search
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw7
        , lh_copy
        , ph3
        , tc
        , w4
        , w_60_ns
        , pt3
        , mt7
        , mb7
        , mt3
        , relative
        , absolute
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
            , searchModel = Search.initModel
            , title = ""
            , content = ""
            , events = []
            }
    in
        ( model, sendRequest )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg
    | FooterMsg Footer.Msg
    | SearchMsg Search.Msg


type alias Model =
    { headerModel : Header.Model
    , footerModel : Footer.Model
    , searchModel : Search.Model
    , title : String
    , content : String
    , events : List Event
    }


type alias Data =
    { pageBy : Page, events : EventsEdges }


type alias Page =
    { title : String
    , content : String
    }


type alias EventsEdges =
    { edges : List EventNode
    }


type alias EventNode =
    { node : Event }


type alias Event =
    { title : String
    , slug : String
    , excerpt : String
    , date : String
    , featuredImage : Maybe FeaturedImage
    }


type alias FeaturedImage =
    { sourceUrl : String }


type alias HeaderModel =
    Header.Model


type alias FooterModel =
    Footer.Model


type alias SearchModel =
    Search.Model


decodeData : Decoder Data
decodeData =
    decode Data
        |> required "pageBy" decodePage
        |> required "events" decodeEventsEdges


decodePage : Decoder Page
decodePage =
    decode Page
        |> required "title" string
        |> required "content" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" Header.decodeModel
        |> required "footerModel" Footer.decodeModel
        |> required "searchModel" Search.decodeModel
        |> required "title" string
        |> required "content" string
        |> required "events" (Decode.list decodeEvent)


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
        |> required "title" string
        |> required "slug" string
        |> required "excerpt" string
        |> required "date" string
        |> required "featuredImage" (nullable decodeFeaturedImage)


decodeFeaturedImage : Decoder FeaturedImage
decodeFeaturedImage =
    decode FeaturedImage
        |> required "sourceUrl" string


pageRequest : Operation Query Variables
pageRequest =
    GraphQl.named "query"
        [ GraphQl.field "pageBy"
            |> GraphQl.withArgument "uri" (GraphQl.string "home")
            |> GraphQl.withSelectors
                [ GraphQl.field "title"
                , GraphQl.field "content"
                ]
        , GraphQl.field "events"
            |> GraphQl.withArgument "where" (GraphQl.queryArgs [ ( "status", GraphQl.type_ "FUTURE" ) ])
            |> GraphQl.withSelectors
                [ GraphQl.field "edges"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "node"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "title"
                                , GraphQl.field "slug"
                                , GraphQl.field "excerpt"
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
    Event node.title node.slug node.excerpt node.date node.featuredImage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotContent (Ok data) ->
            let
                newModel =
                    { model
                        | title = data.pageBy.title
                        , content = data.pageBy.content
                        , events = List.map createEvent data.events.edges
                    }
            in
                ( newModel, Cmd.map SearchMsg Search.sendTagsRequest )

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

        SearchMsg subMsg ->
            let
                ( updatedSearchModel, searchCmd ) =
                    Search.update subMsg model.searchModel
            in
                ( { model | searchModel = updatedSearchModel }, Cmd.map SearchMsg searchCmd )


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ head model.title
        , node "body"
            []
            [ div [ id "elm-root" ] [ view model ]
            , node "script" [ src "bundle.js" ] []
            , node "script" [ id "elm-js" ] []
            ]
        ]


viewEvent : Event -> Html.Html Msg
viewEvent { title, slug, excerpt, date, featuredImage } =
    let
        image =
            case featuredImage of
                Just val ->
                    val.sourceUrl

                Nothing ->
                    (frontendUrl ++ "/defaultImg.jpg")
    in
        Html.a [ href (frontendUrl ++ "/events/index.html#" ++ slug) ]
            [ div [] [ img [ src image ] [] ]
            , div [] [ text title ]
            , div [ setInnerHtml excerpt ] []
            ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , node "main"
            [ classes [ center, mw7, lh_copy, ph3 ]
            ]
            [ div [ setInnerHtml model.content ] []
            ]
        , if List.isEmpty model.events then
            div [] []
          else
            div [] (List.map viewEvent model.events)
        , Html.map SearchMsg (Search.view model.searchModel)
        , Html.map FooterMsg (Footer.view model.footerModel)
        ]
