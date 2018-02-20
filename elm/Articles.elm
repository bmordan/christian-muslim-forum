module Articles exposing (main, decodeModel, viewPage)

import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Http exposing (Error)
import Html exposing (text, div, button, a, strong, img, span, node)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style)
import Html.Events exposing (onClick)
import Config exposing (graphqlEndpoint, frontendUrl)
import GraphQl exposing (Operation, Variables, Query, Named)
import Helpers exposing (setInnerHtml, forumIcon, head)
import Header
import Footer
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( pa2
        , pa3
        , pl2
        , db
        , mv3
        , mt2
        , center
        , w_100
        , ba
        , b__light_gray
        , link
        , flex
        , flex_column
        , flex_auto
        , flex_none
        , flex_wrap
        , justify_start
        , justify_end
        , items_center
        , flex_none
        , flex_auto
        , mr2
        , br_100
        , w2
        , h2
        , tr
        , ph3
        , pl3
        , lh_copy
        , mw6
        , mw9
        , pt6
        , br_100
        , cf
        , w_third_ns
        , pa1_ns
        , db
        , f3
        )


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


type Msg
    = GotPosts (Result Error Data)
    | GetPosts String
    | HeaderMsg Header.Msg
    | FooterMsg Footer.Msg


type alias Data =
    { posts : Posts }


type alias Posts =
    { pageInfo : PageInfo
    , edges : List Node
    }


type alias PageInfo =
    { hasNextPage : Bool
    , endCursor : Maybe String
    }


type alias Edges =
    { edges : List Node
    }


type alias Node =
    { node : Post
    }


type alias Post =
    { slug : String
    , title : String
    , excerpt : String
    , featuredImage : Maybe FeaturedImage
    , author : Author
    , commentCount : Maybe Int
    }


type alias Author =
    { name : String
    , avatar : Avatar
    }


type alias Avatar =
    { url : Maybe String
    }


type alias FeaturedImage =
    { sourceUrl : String
    }


type alias Model =
    { headerModel : Header.Model
    , footerModel : Footer.Model
    , hasNextPage : Bool
    , nextCursor : String
    , posts : List Node
    }


type alias FooterModel =
    { modal : Bool
    , fname : String
    , lname : String
    , email : String
    , message : String
    }


type alias HeaderModel =
    { scrollLeft : Bool
    }


decodeData : Decoder Data
decodeData =
    decode Data
        |> required "posts" decodePosts


decodePosts : Decoder Posts
decodePosts =
    decode Posts
        |> required "pageInfo" decodePageInfo
        |> required "edges" (Decode.list decodeNode)


decodePageInfo : Decoder PageInfo
decodePageInfo =
    decode PageInfo
        |> required "hasNextPage" bool
        |> required "endCursor" (nullable string)


decodeEdges : Decoder Edges
decodeEdges =
    decode Edges
        |> required "edges" (Decode.list decodeNode)


decodeNode : Decoder Node
decodeNode =
    decode Node
        |> required "node" decodePost


decodePost : Decoder Post
decodePost =
    decode Post
        |> required "slug" string
        |> required "title" string
        |> required "excerpt" string
        |> required "featuredImage" (nullable decodeFeaturedImage)
        |> required "author" decodeAuthor
        |> required "commentCount" (nullable int)


decodeAuthor : Decoder Author
decodeAuthor =
    decode Author
        |> required "name" string
        |> required "avatar" decodeAvatar


decodeAvatar : Decoder Avatar
decodeAvatar =
    decode Avatar
        |> required "url" (nullable string)


decodeFeaturedImage : Decoder FeaturedImage
decodeFeaturedImage =
    decode FeaturedImage
        |> required "sourceUrl" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" decodeHeaderModel
        |> required "footerModel" decodeFooterModel
        |> required "hasNextPage" bool
        |> required "nextCursor" string
        |> required "posts" (Decode.list decodeNode)


decodeHeaderModel : Decoder HeaderModel
decodeHeaderModel =
    decode HeaderModel
        |> required "scrollLeft" bool


decodeFooterModel : Decoder FooterModel
decodeFooterModel =
    decode FooterModel
        |> required "modal" bool
        |> required "fname" string
        |> required "lname" string
        |> required "email" string
        |> required "message" string


postsQuery : String -> Operation Query Variables
postsQuery cursor =
    GraphQl.named "postsQuery"
        [ GraphQl.field "posts"
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
                                , GraphQl.field "featuredImage"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "sourceUrl"
                                        ]
                                , GraphQl.field "author"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "name"
                                        , GraphQl.field "avatar"
                                            |> GraphQl.withSelectors
                                                [ GraphQl.field "url"
                                                ]
                                        ]
                                , GraphQl.field "commentCount"
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


sendPostsQuery : String -> Cmd Msg
sendPostsQuery cursor =
    baseRequest (postsQuery cursor) decodeData
        |> GraphQl.send GotPosts


init : ( Model, Cmd Msg )
init =
    let
        model =
            { headerModel = Header.initModel
            , footerModel = Footer.initModel
            , hasNextPage = False
            , nextCursor = "null"
            , posts = []
            }
    in
        ( model, (sendPostsQuery "null") )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPosts (Ok data) ->
            ( updateModelWithPosts model data, Cmd.none )

        GotPosts (Err err) ->
            ( model, Cmd.none )

        GetPosts cursor ->
            ( model, sendPostsQuery cursor )

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


updateModelWithPosts : Model -> Data -> Model
updateModelWithPosts model data =
    { model
        | hasNextPage = data.posts.pageInfo.hasNextPage
        , nextCursor = Maybe.withDefault "" data.posts.pageInfo.endCursor
        , posts = List.append model.posts data.posts.edges
    }


renderPost : Node -> Html.Html Msg
renderPost { node } =
    let
        imgSrc =
            case node.featuredImage of
                Just src ->
                    src.sourceUrl

                Nothing ->
                    "/defaultImg.jpg"

        excerpt =
            String.split "<p>" node.excerpt
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
                [ style [ ( "background-image", "url(" ++ imgSrc ++ ")" ) ]
                , classList [ ( "article-card-img", True ) ]
                , href (frontendUrl ++ "/article.html#" ++ node.slug)
                ]
                [ div [ classList [ ( "article-card-title", True ) ] ]
                    [ div
                        [ setInnerHtml node.title
                        , classes [ pa3, f3 ]
                        , classList [ ( "feature-font", True ) ]
                        ]
                        []
                    , forumIcon node.commentCount
                    ]
                ]
            , viewAuthor node.author
            , div
                [ setInnerHtml (excerpt ++ "...")
                , classes [ pa3 ]
                , classList [ ( "article-card-excerpt", True ) ]
                ]
                []
            ]


viewAuthor : Author -> Html.Html Msg
viewAuthor author =
    let
        url =
            Maybe.withDefault (frontendUrl ++ "/defaultImg.jpg") author.avatar.url
    in
        div
            [ classList [ ( "article-card-author", True ) ]
            , classes [ flex, items_center, justify_start ]
            ]
            [ img [ src url, classes [ br_100, flex_none ] ] []
            , div [ classes [ flex_auto, pl2 ] ] [ text ("by " ++ author.name) ]
            ]


renderPosts : List Node -> Html.Html Msg
renderPosts nodes =
    if List.isEmpty nodes then
        div [ classes [ center ] ] [ text "no articles..." ]
    else
        div
            [ classes [ center ]
            , classList [ ( "articles", True ) ]
            ]
            (List.map renderPost nodes)


renderMoreBtn : Model -> Html.Html Msg
renderMoreBtn model =
    let
        btnClasses =
            [ center, mv3, w_100 ]
    in
        if model.hasNextPage then
            div [ classList [ ( "double_b_btns", True ) ], onClick (GetPosts model.nextCursor) ] [ text "load more" ]
        else
            div [ classList [ ( "double_b_btns", True ) ] ] [ text "no more articles" ]


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ head "Latests Articles"
        , node "body"
            []
            [ div [ id "elm-root" ] [ view model ]
            , node "script" [ src "bundle.js" ] []
            , node "script" [ id "elm-js" ] []
            ]
        ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , node "main"
            [ classes [ lh_copy, pt6 ]
            ]
            [ renderPosts model.posts
            , div [] [ renderMoreBtn model ]
            ]
        , Html.map FooterMsg (Footer.view model.footerModel)
        ]
