module Home exposing (..)

import Html exposing (text, div, node, img)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style, httpEquiv)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml, head, formatDate, forumIcon)
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
        , pa2
        , pa3
        , ph3
        , pl2
        , tc
        , w4
        , w_60_ns
        , pt3
        , mt7
        , mb7
        , mt3
        , relative
        , absolute
        , flex
        , flex_column
        , flex_auto
        , flex_none
        , items_start
        , items_center
        , justify_between
        , justify_start
        , link
        , br_100
        , f3
        , w_100
        , mv3
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
            , articles = []
            , articlesMore = True
            , articlesNext = "null"
            }
    in
        ( model, sendRequest )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg
    | FooterMsg Footer.Msg
    | SearchMsg Search.Msg
    | GetArticles String
    | GotArticles (Result Error ArticlesOnlyData)


type alias Model =
    { headerModel : Header.Model
    , footerModel : Footer.Model
    , searchModel : Search.Model
    , title : String
    , content : String
    , events : List Event
    , articles : List Article
    , articlesMore : Bool
    , articlesNext : String
    }


type alias Data =
    { pageBy : Page, events : EventsEdges, articles : ArticlesResponse }


type alias ArticlesOnlyData =
    { articles : ArticlesResponse }


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


type alias ArticlesResponse =
    { pageInfo : ArticlesPageInfo
    , edges : List ArticleNode
    }


type alias ArticlesEdges =
    { edges : List ArticleNode
    }


type alias ArticlesPageInfo =
    { hasNextPage : Bool
    , endCursor : String
    }


type alias ArticleNode =
    { node : Article
    }


type alias Article =
    { slug : String
    , title : String
    , excerpt : String
    , commentCount : Maybe Int
    , featuredImage : Maybe FeaturedImage
    , author : Author
    }


type alias Author =
    { name : String
    , bio : String
    , faith : String
    , avatar : Avatar
    }


type alias Avatar =
    { url : String
    }


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
        |> required "articles" decodeArticlesResponse


decodeArticlesOnlyData : Decoder ArticlesOnlyData
decodeArticlesOnlyData =
    decode ArticlesOnlyData
        |> required "articles" decodeArticlesResponse


decodePage : Decoder Page
decodePage =
    decode Page
        |> required "title" string
        |> required "content" string


decodeArticlesResponse : Decoder ArticlesResponse
decodeArticlesResponse =
    decode ArticlesResponse
        |> required "pageInfo" decodePageInfo
        |> required "edges" (Decode.list decodeArticleNode)


decodePageInfo : Decoder ArticlesPageInfo
decodePageInfo =
    decode ArticlesPageInfo
        |> required "hasNextPage" bool
        |> required "endCursor" string


decodeArticleNode : Decoder ArticleNode
decodeArticleNode =
    decode ArticleNode
        |> required "node" decodeArticle


decodeArticle : Decoder Article
decodeArticle =
    decode Article
        |> required "slug" string
        |> required "title" string
        |> required "excerpt" string
        |> required "commentCount" (nullable int)
        |> required "featuredImage" (nullable decodeFeaturedImage)
        |> required "author" decodeAuthor


decodeAuthor : Decoder Author
decodeAuthor =
    decode Author
        |> required "name" string
        |> required "bio" string
        |> required "faith" string
        |> required "avatar" decodeAvatar


decodeAvatar : Decoder Avatar
decodeAvatar =
    decode Avatar
        |> required "url" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" Header.decodeModel
        |> required "footerModel" Footer.decodeModel
        |> required "searchModel" Search.decodeModel
        |> required "title" string
        |> required "content" string
        |> required "events" (Decode.list decodeEvent)
        |> required "articles" (Decode.list decodeArticle)
        |> required "articlesMore" bool
        |> required "articlesNext" string


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
        , GraphQl.field "posts"
            |> GraphQl.withAlias "articles"
            |> GraphQl.withArgument "first" (GraphQl.int 4)
            |> GraphQl.withArgument "after" (GraphQl.string "null")
            |> GraphQl.withSelectors
                [ GraphQl.field "pageInfo"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "hasNextPage"
                        , GraphQl.field "endCursor"
                        ]
                , GraphQl.field "edges"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "node"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "slug"
                                , GraphQl.field "title"
                                , GraphQl.field "excerpt"
                                , GraphQl.field "commentCount"
                                , GraphQl.field "featuredImage"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "sourceUrl"
                                        ]
                                , GraphQl.field "author"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "name"
                                        , GraphQl.field "description"
                                            |> GraphQl.withAlias "bio"
                                        , GraphQl.field "nickname"
                                            |> GraphQl.withAlias "faith"
                                        , GraphQl.field "avatar"
                                            |> GraphQl.withSelectors
                                                [ GraphQl.field "url"
                                                ]
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


articlesRequest : String -> Operation Query Variables
articlesRequest cursor =
    GraphQl.named "articles"
        [ GraphQl.field "posts"
            |> GraphQl.withAlias "articles"
            |> GraphQl.withArgument "first" (GraphQl.int 4)
            |> GraphQl.withArgument "after" (GraphQl.string cursor)
            |> GraphQl.withSelectors
                [ GraphQl.field "pageInfo"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "hasNextPage"
                        , GraphQl.field "endCursor"
                        ]
                , GraphQl.field "edges"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "node"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "slug"
                                , GraphQl.field "title"
                                , GraphQl.field "excerpt"
                                , GraphQl.field "commentCount"
                                , GraphQl.field "featuredImage"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "sourceUrl"
                                        ]
                                , GraphQl.field "author"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "name"
                                        , GraphQl.field "description"
                                            |> GraphQl.withAlias "bio"
                                        , GraphQl.field "nickname"
                                            |> GraphQl.withAlias "faith"
                                        , GraphQl.field "avatar"
                                            |> GraphQl.withSelectors
                                                [ GraphQl.field "url"
                                                ]
                                        ]
                                ]
                        ]
                ]
        ]
        |> GraphQl.withVariables []


baseArticlesRequest :
    Operation Query Variables
    -> Decoder ArticlesOnlyData
    -> GraphQl.Request Query Variables ArticlesOnlyData
baseArticlesRequest =
    GraphQl.query graphqlEndpoint


sendArticlesRequest : String -> Cmd Msg
sendArticlesRequest cursor =
    baseArticlesRequest (articlesRequest cursor) decodeArticlesOnlyData
        |> GraphQl.send GotArticles


createEvent : EventNode -> Event
createEvent { node } =
    Event node.title node.slug node.excerpt node.date node.featuredImage


createArticle : ArticleNode -> Article
createArticle { node } =
    Article node.slug node.title node.excerpt node.commentCount node.featuredImage node.author


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
                        , articles = List.map createArticle data.articles.edges
                        , articlesMore = data.articles.pageInfo.hasNextPage
                        , articlesNext = data.articles.pageInfo.endCursor
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

        GetArticles cursor ->
            ( model, sendArticlesRequest (Debug.log "cursor" cursor) )

        GotArticles (Ok data) ->
            let
                checkingData =
                    Debug.log "pageInfo" data.articles.pageInfo
            in
                ( { model
                    | articles = model.articles ++ (List.map createArticle data.articles.edges)
                    , articlesMore = data.articles.pageInfo.hasNextPage
                    , articlesNext = (Debug.log "endCursor" data.articles.pageInfo.endCursor)
                  }
                , Cmd.none
                )

        GotArticles (Err err) ->
            let
                checkingData =
                    Debug.log "articles err" err
            in
                ( model, Cmd.none )


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


viewMoreBtn : Model -> Html.Html Msg
viewMoreBtn { articlesMore, articlesNext } =
    let
        btnClasses =
            [ center, mv3, w_100 ]
    in
        if articlesMore then
            div [ classList [ ( "double_b_btns", True ) ], onClick (GetArticles articlesNext) ] [ text "load more" ]
        else
            div [ classList [ ( "double_b_btns", True ) ] ] [ text "no more articles" ]


getFeatruedImageSrc : Maybe FeaturedImage -> String
getFeatruedImageSrc featuredImage =
    case featuredImage of
        Just val ->
            val.sourceUrl

        Nothing ->
            (frontendUrl ++ "/defaultImg.jpg")


viewAuthor : Author -> Html.Html Msg
viewAuthor author =
    let
        url =
            author.avatar.url
    in
        div
            [ classList [ ( "article-card-author", True ) ]
            , classes [ flex, items_center, justify_start ]
            ]
            [ img [ src url, classes [ br_100, flex_none ] ] []
            , div [ classes [ flex_auto, pl2 ] ] [ text ("by " ++ author.name) ]
            ]


viewEvent : Event -> Html.Html Msg
viewEvent { title, slug, excerpt, date, featuredImage } =
    let
        image =
            getFeatruedImageSrc featuredImage
    in
        Html.a
            [ href (frontendUrl ++ "/events/index.html#" ++ slug)
            , classList [ ( "event-card", True ) ]
            , classes [ flex, items_center, justify_start, link ]
            ]
            [ div
                [ classList [ ( "event-card-img", True ) ]
                , style [ ( "background-image", "url(" ++ image ++ ")" ) ]
                , classes [ flex_none ]
                ]
                []
            , div [ classes [ pl2 ] ]
                [ div [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ] ] [ text title ]
                , div [ setInnerHtml excerpt ] []
                ]
            , div
                [ classes [ flex_none, flex, flex_column, items_center, justify_between ]
                , classList [ ( "event-card-date", True ) ]
                ]
                [ div [] [ text (formatDate "%b" date) ]
                , div [] [ text (formatDate "%d" date) ]
                , div [] [ text (formatDate "%a" date) ]
                ]
            ]


viewArticle : Article -> Html.Html Msg
viewArticle { slug, title, excerpt, featuredImage, commentCount, author } =
    let
        image =
            getFeatruedImageSrc featuredImage

        trimmedexcerpt =
            String.split "<p>" excerpt
                |> String.join ""
                |> String.split "</p>"
                |> String.join ""
                |> String.slice 0 180
    in
        div
            [ classes [ flex, flex_column, justify_start ]
            , classList [ ( "article-card", True ) ]
            ]
            [ Html.a
                [ style [ ( "background-image", "url(" ++ image ++ ")" ) ]
                , classList [ ( "article-card-img", True ) ]
                , href (frontendUrl ++ "/article.html#" ++ slug)
                ]
                [ div [ classList [ ( "article-card-title", True ) ] ]
                    [ div
                        [ setInnerHtml title
                        , classes [ pa3, f3 ]
                        , classList [ ( "feature-font", True ) ]
                        ]
                        []
                    , forumIcon commentCount
                    ]
                ]
            , viewAuthor author
            , div
                [ setInnerHtml (trimmedexcerpt ++ "...")
                , classes [ pa3 ]
                , classList [ ( "article-card-excerpt", True ) ]
                ]
                []
            ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , div
            [ classes [ center, mw7, lh_copy, ph3 ]
            ]
            [ div [ setInnerHtml model.content ] []
            ]
        , if List.isEmpty model.events then
            div [] []
          else
            div []
                [ div
                    [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                    , classes [ pa2 ]
                    ]
                    [ text "Events" ]
                , div [] (List.map viewEvent model.events)
                ]
        , if List.isEmpty model.articles then
            div [] []
          else
            div []
                [ div
                    [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                    , classes [ pa2 ]
                    ]
                    [ text "Latest Articles" ]
                , div [] (List.map viewArticle model.articles)
                , viewMoreBtn model
                ]
        , div []
            [ div
                [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                , classes [ pa2 ]
                ]
                [ text "Search" ]
            , Html.map SearchMsg (Search.view model.searchModel)
            ]
        , Html.map FooterMsg (Footer.view model.footerModel)
        ]
