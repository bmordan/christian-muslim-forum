module Home exposing (..)

import Html exposing (text, div, node, img)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style, httpEquiv)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml, head, formatDate, forumIcon, getFeaturedImageSrc, OpenGraphTags, monthToInt)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Header
import Footer
import Search
import Date
import Task
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw7
        , mt6
        , mb2
        , mb3
        , lh_title
        , lh_copy
        , pa1
        , pa2
        , pa3
        , ph1
        , ph2
        , ph3
        , pv4
        , pl1
        , pl2
        , ph2
        , pt5
        , pb2
        , pb4
        , pr2
        , pr2_ns
        , tc
        , tr
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
        , white
        , br_100
        , cf
        , fl
        , f1
        , f1_ns
        , f2_m
        , f2
        , f3
        , b
        , w_100
        , w_50
        , w_50_ns
        , w_third_ns
        , w_two_thirds_ns
        , mv3
        , bg_dark_red
        , bg_light_gray
        , bg_near_white
        , bg_white
        , db
        , dn
        , db_ns
        , dn_m
        , near_black
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
            , searchModel = Search.initModel
            , title = ""
            , content = ""
            , featuredImage = Nothing
            , events = []
            , articles = []
            , articlesMore = True
            , articlesNext = "null"
            , year = Nothing
            , month = Nothing
            , day = Nothing
            }
    in
        ( model, Task.perform GotDate <| Date.now )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg
    | SearchMsg Search.Msg
    | GetArticles String
    | GotArticles (Result Error ArticlesOnlyData)
    | GotDate Date.Date


type alias Model =
    { headerModel : Header.Model
    , searchModel : Search.Model
    , title : String
    , content : String
    , featuredImage : Maybe FeaturedImage
    , events : List Event
    , articles : List Article
    , articlesMore : Bool
    , articlesNext : String
    , year : Maybe Int
    , month : Maybe Int
    , day : Maybe Int
    }


type alias Data =
    { pageBy : Page, events : EventsEdges, articles : ArticlesResponse }


type alias ArticlesOnlyData =
    { articles : ArticlesResponse }


type alias Page =
    { title : String
    , content : String
    , featuredImage : Maybe FeaturedImage
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
        |> required "featuredImage" (nullable decodeFeaturedImage)


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
        |> required "searchModel" Search.decodeModel
        |> required "title" string
        |> required "content" string
        |> required "featuredImage" (nullable decodeFeaturedImage)
        |> required "events" (Decode.list decodeEvent)
        |> required "articles" (Decode.list decodeArticle)
        |> required "articlesMore" bool
        |> required "articlesNext" string
        |> required "year" (nullable int)
        |> required "month" (nullable int)
        |> required "day" (nullable int)


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


pageRequest : Model -> Operation Query Variables
pageRequest model =
    GraphQl.named "query"
        [ GraphQl.field "pageBy"
            |> GraphQl.withArgument "uri" (GraphQl.string "home")
            |> GraphQl.withSelectors
                [ GraphQl.field "title"
                , GraphQl.field "content"
                , GraphQl.field "featuredImage"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "sourceUrl"
                        ]
                ]
        , GraphQl.field "events"
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


sendRequest : Model -> Cmd Msg
sendRequest model =
    baseRequest (pageRequest model) decodeData
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
                        , featuredImage = data.pageBy.featuredImage
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

        SearchMsg subMsg ->
            let
                ( updatedSearchModel, searchCmd ) =
                    Search.update subMsg model.searchModel
            in
                ( { model | searchModel = updatedSearchModel }, Cmd.map SearchMsg searchCmd )

        GetArticles cursor ->
            ( model, sendArticlesRequest cursor )

        GotArticles (Ok data) ->
            ( { model
                | articles = model.articles ++ (List.map createArticle data.articles.edges)
                , articlesMore = data.articles.pageInfo.hasNextPage
                , articlesNext = data.articles.pageInfo.endCursor
              }
            , Cmd.none
            )

        GotArticles (Err err) ->
            ( model, Cmd.none )

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
    OpenGraphTags "Christian Muslim Forum" "Christian muslim forum website. Where Christian and Muslim thinkers meet." (getFeaturedImageSrc Nothing) frontendUrl


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ head openGraphTags
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
            , div [ classes [ flex_auto, pl2 ] ] [ text author.name ]
            ]


viewEvent : Event -> Html.Html msg
viewEvent { title, slug, excerpt, date, featuredImage } =
    let
        image =
            getFeaturedImageSrc featuredImage
    in
        Html.a
            [ href (frontendUrl ++ "/events/" ++ slug)
            , classList [ ( "event-card", True ) ]
            , classes [ flex, items_center, justify_start, mb3, link, bg_white, near_black, lh_title, mw7, center, w_100 ]
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


viewArticle : Article -> Html.Html Msg
viewArticle { slug, title, excerpt, featuredImage, commentCount, author } =
    let
        image =
            getFeaturedImageSrc featuredImage

        trimmedexcerpt =
            String.split "<p>" excerpt
                |> String.join ""
                |> String.split "</p>"
                |> String.join ""
                |> String.slice 0 160
    in
        div
            [ classes [ flex, flex_column, justify_start, fl, w_100, w_50_ns, pa1 ]
            , classList [ ( "article-card", True ) ]
            ]
            [ Html.a
                [ style [ ( "background-image", "url(" ++ image ++ ")" ) ]
                , classList [ ( "article-card-img", True ) ]
                , href (frontendUrl ++ "/articles/" ++ slug)
                ]
                [ div [ classList [ ( "article-card-title", True ) ] ]
                    [ div
                        [ setInnerHtml title
                        , classes [ pa3, f3, lh_title ]
                        , classList [ ( "feature-font", True ) ]
                        ]
                        []
                    , forumIcon commentCount
                    ]
                ]
            , viewAuthor author
            , div
                [ setInnerHtml (trimmedexcerpt ++ "...")
                , classes [ pa3, lh_title ]
                , classList [ ( "article-card-excerpt", True ) ]
                ]
                []
            ]


view : Model -> Html.Html Msg
view model =
    div [classList [ ( "hero-bg" , True) ]
    , style [ ("background-image", "url(" ++ (getFeaturedImageSrc model.featuredImage) ++ ")") ]
    ]
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , div
            [ classes [ ph3, pt5, pb4, relative ]
            , classList [ ( "hero-content" , True) ]
            ]
            [ div [ setInnerHtml model.content, classes [center, mw7, lh_copy] ] []
            ]
        , if List.isEmpty model.events then
            div [] []
          else
            div [ classes [ pb4, bg_near_white ], classList [ ( "bg_cmf_christian", True ) ] ]
                [ div
                    [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                    , classes [ f2, ph2, pv4, w_100, center, mw7 ]
                    ]
                    [ text "Upcoming Events" ]
                , div [] (List.map viewEvent (List.reverse model.events))
                ]
        , if List.isEmpty model.articles then
            div [ classList [ ( "loading", True ) ] ] []
          else
            div [ classes [ fl, w_100, w_two_thirds_ns ] ]
                [ div
                    [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                    , classes [ f2, ph2, pv4, w_100 ]
                    ]
                    [ text "Latest Articles" ]
                , div [ classes [ cf, ph1 ] ] (List.map viewArticle model.articles)
                , div [ classes [ w_100, pb4 ] ] [ viewMoreBtn model ]
                ]
        , div [ classes [ fl, w_100, w_third_ns, pr2_ns ] ]
            [ div
                [ classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                , classes [ f2, tr, ph2, pv4, w_100, center, mw7 ]
                ]
                [ text "Search" ]
            , Html.map SearchMsg (Search.view model.searchModel)
            ]
        , Footer.view
        ]
