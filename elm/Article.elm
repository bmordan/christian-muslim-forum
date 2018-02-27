module Article exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional, requiredAt)
import Http exposing (Error)
import Html exposing (text, div, button, a, strong, img, span, p, node)
import Html.Attributes exposing (href, src, style, id, content, rel, name, classList)
import Html.Events exposing (onClick)
import Dom exposing (Error)
import Dom.Scroll exposing (toTop)
import Task
import Navigation
import Header
import Footer
import Regex
import Search
import List.Extra exposing (elemIndex, getAt)
import Config exposing (graphqlEndpoint, frontendUrl)
import GraphQl exposing (Operation, Variables, Query, Named)
import Helpers exposing (setInnerHtml, forumIcon, capitalise, viewPerson, formatDate, head, chevBlue, slugToTitle, getFeaturedImageSrc)
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( pa2
        , ph3
        , ph4
        , pb3
        , pa0
        , pl2
        , pv3
        , pa3
        , pt1
        , pt2
        , pt3
        , ph2
        , pv4
        , pb0
        , flex
        , flex_wrap
        , flex_column
        , justify_end
        , justify_start
        , justify_between
        , flex_none
        , flex_auto
        , ma2
        , mr2
        , mv1
        , mh2
        , nt4
        , z_1
        , br_100
        , items_center
        , items_start
        , bg_light_gray
        , bg_dark_gray
        , white
        , f2
        , f3
        , f5
        , f6
        , overflow_y_scroll
        , mb4
        , h2
        , tr
        , mw7
        , lh_copy
        , center
        , link
        , dn
        , db
        , dn_ns
        , db_ns
        , db_m
        , db_l
        , f1_ns
        , dib
        , br2
        , fl
        , w_50
        , w_50_ns
        , w_100
        , w_third_ns
        , w_two_thirds_ns
        , v_top
        , relative
        , nt2
        , pr2_ns
        )


main =
    Navigation.program Slug
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


initModel : Navigation.Location -> Model
initModel location =
    { post = Nothing
    , posts = []
    , related = []
    , prev = Nothing
    , next = Nothing
    , slug = maybeSlug location
    , comments = []
    , headerModel = Header.initModel
    , footerModel = Footer.initModel
    , searchModel = Search.initModel
    }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( initModel location, postsRequest "null" )


type Msg
    = Slug Navigation.Location
    | GotPosts (Result Http.Error PostsData)
    | GotPost (Result Http.Error PostBy)
    | GotRelatedPosts (Result Http.Error RelatedPostsData)
    | Scroll
    | HeaderMsg Header.Msg
    | FooterMsg Footer.Msg
    | SearchMsg Search.Msg


type alias PostsData =
    { posts : Posts
    }


type alias RelatedPostsData =
    { posts : RelatedPosts
    }


type alias RelatedPosts =
    { edges : List RelatedPostNode
    }


type alias RelatedPostNode =
    { node : RelatedPost
    }


type alias RelatedPost =
    { title : String
    , slug : String
    , excerpt : String
    , commentCount : Maybe Int
    , featuredImage : Maybe FeaturedImage
    , author : Author
    }


type alias Edges =
    { edges : List Node }


type alias Node =
    { node : Comment }


type alias Comment =
    { content : String
    , date : String
    , author : Author
    }


type alias Posts =
    { pageInfo : PageInfo
    , edges : List PostLabel
    }


type alias PageInfo =
    { hasNextPage : Bool
    , endCursor : Maybe String
    }


type alias PostLabel =
    { slug : String
    , title : String
    }


type alias PostBy =
    { postBy : Post
    }


type alias TagEdges =
    { edges : List TagNode
    }


type alias TagNode =
    { node : Tag
    }


type alias Tag =
    { slug : String
    }


type alias Post =
    { slug : String
    , title : String
    , content : String
    , date : String
    , author : Author
    , featuredImage : Maybe FeaturedImage
    , commentCount : Maybe Int
    , comments : Edges
    , tags : TagEdges
    }


type alias FeaturedImage =
    { sourceUrl : String
    }


type alias Author =
    { name : String
    , bio : String
    , avatar : String
    , faith : String
    }


type alias Person =
    { name : String
    , bio : String
    , avatar : String
    , faith : String
    , tags : List String
    }


type alias Model =
    { post : Maybe Post
    , posts : List PostLabel
    , related : List RelatedPost
    , prev : Maybe String
    , next : Maybe String
    , slug : Maybe String
    , comments : List Node
    , headerModel : Header.Model
    , footerModel : Footer.Model
    , searchModel : Search.Model
    }


type alias HeaderModel =
    Header.Model


type alias FooterModel =
    Footer.Model


type alias SearchModel =
    Search.Model


decodePostsData : Decoder PostsData
decodePostsData =
    decode PostsData
        |> required "posts" decodePosts


decodePosts : Decoder Posts
decodePosts =
    decode Posts
        |> required "pageInfo" decodePageInfo
        |> required "edges" (Decode.list decodePostLabel)


decodeRelatedPostsData : Decoder RelatedPostsData
decodeRelatedPostsData =
    decode RelatedPostsData
        |> required "posts" decodeRelatedPostsEdges


decodeRelatedPostsEdges : Decoder RelatedPosts
decodeRelatedPostsEdges =
    decode RelatedPosts
        |> required "edges" (Decode.list decodeRelatedPostNode)


decodeRelatedPostNode : Decoder RelatedPostNode
decodeRelatedPostNode =
    decode RelatedPostNode
        |> required "node" decodeRelatedPost


decodeRelatedPost : Decoder RelatedPost
decodeRelatedPost =
    decode RelatedPost
        |> required "title" string
        |> required "slug" string
        |> required "excerpt" string
        |> required "commentCount" (nullable int)
        |> required "featuredImage" (nullable decodeFeaturedImage)
        |> required "author" decodeAuthor


decodePageInfo : Decoder PageInfo
decodePageInfo =
    decode PageInfo
        |> required "hasNextPage" bool
        |> required "endCursor" (nullable string)


decodePostLabel : Decoder PostLabel
decodePostLabel =
    decode PostLabel
        |> requiredAt [ "node", "slug" ] string
        |> requiredAt [ "node", "title" ] string


decodePostBy : Decoder PostBy
decodePostBy =
    decode PostBy
        |> required "postBy" decodePost


decodePost : Decoder Post
decodePost =
    decode Post
        |> required "slug" string
        |> required "title" string
        |> required "content" string
        |> required "date" string
        |> required "author" decodeAuthor
        |> required "featuredImage" (nullable decodeFeaturedImage)
        |> required "commentCount" (nullable int)
        |> required "comments" decodeEdges
        |> required "tags" decodeTagEdges


decodeTagEdges : Decoder TagEdges
decodeTagEdges =
    decode TagEdges
        |> required "edges" (Decode.list decodeTagNode)


decodeTagNode : Decoder TagNode
decodeTagNode =
    decode TagNode
        |> required "node" decodeTag


decodeTag : Decoder Tag
decodeTag =
    decode Tag
        |> required "slug" string


decodeFeaturedImage : Decoder FeaturedImage
decodeFeaturedImage =
    decode FeaturedImage
        |> required "sourceUrl" string


decodeAuthor : Decoder Author
decodeAuthor =
    decode Author
        |> required "name" string
        |> required "bio" string
        |> requiredAt [ "avatar", "url" ] string
        |> required "faith" string


decodeEdges : Decoder Edges
decodeEdges =
    decode Edges
        |> required "edges" (Decode.list decodeNode)


decodeNode : Decoder Node
decodeNode =
    decode Node
        |> required "node" decodeComment


decodeComment : Decoder Comment
decodeComment =
    decode Comment
        |> required "content" string
        |> required "date" string
        |> required "author" decodeAuthor


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "post" (nullable decodePost)
        |> required "posts" (Decode.list decodePostLabel)
        |> required "related" (Decode.list decodeRelatedPost)
        |> required "prev" (nullable string)
        |> required "next" (nullable string)
        |> required "slug" (nullable string)
        |> required "comments" (Decode.list decodeNode)
        |> required "headerModel" Header.decodeModel
        |> required "footerModel" Footer.decodeModel
        |> required "searchModel" Search.decodeModel


postsQuery : String -> Operation Query Variables
postsQuery cursor =
    GraphQl.named "postsQuery"
        [ GraphQl.field "posts"
            |> GraphQl.withArgument "first" (GraphQl.int 100)
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
                                ]
                        ]
                ]
        ]
        |> GraphQl.withVariables []


basePostsRequest :
    Operation Query Variables
    -> Decoder PostsData
    -> GraphQl.Request Query Variables PostsData
basePostsRequest =
    GraphQl.query graphqlEndpoint


postsRequest : String -> Cmd Msg
postsRequest cursor =
    basePostsRequest (postsQuery cursor) decodePostsData
        |> GraphQl.send GotPosts


postQuery : String -> Operation Query Variables
postQuery slug =
    GraphQl.named "postQuery"
        [ GraphQl.field "postBy"
            |> GraphQl.withArgument "slug" (GraphQl.string slug)
            |> GraphQl.withSelectors
                [ GraphQl.field "slug"
                , GraphQl.field "title"
                , GraphQl.field "content"
                , GraphQl.field "date"
                , GraphQl.field "author"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "name"
                        , GraphQl.field "description"
                            |> GraphQl.withAlias "bio"
                        , GraphQl.field "avatar"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "url"
                                ]
                        , GraphQl.field "nickname"
                            |> GraphQl.withAlias "faith"
                        ]
                , GraphQl.field "featuredImage"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "sourceUrl"
                        ]
                , GraphQl.field "commentCount"
                , GraphQl.field "comments"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "edges"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "node"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "content"
                                        , GraphQl.field "date"
                                        , GraphQl.field "author"
                                            |> GraphQl.withSelectors
                                                [ GraphQl.field "... on User"
                                                    |> GraphQl.withSelectors
                                                        [ GraphQl.field "name"
                                                        , GraphQl.field "description"
                                                            |> GraphQl.withAlias "bio"
                                                        , GraphQl.field "avatar"
                                                            |> GraphQl.withSelectors
                                                                [ GraphQl.field "url"
                                                                ]
                                                        , GraphQl.field "nickname"
                                                            |> GraphQl.withAlias "faith"
                                                        ]
                                                ]
                                        ]
                                ]
                        ]
                , GraphQl.field "tags"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "edges"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "node"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "slug"
                                        ]
                                ]
                        ]
                ]
        ]
        |> GraphQl.withVariables []


basePostRequest :
    Operation Query Variables
    -> Decoder PostBy
    -> GraphQl.Request Query Variables PostBy
basePostRequest =
    GraphQl.query graphqlEndpoint


postRequest : String -> Cmd Msg
postRequest slug =
    basePostRequest (postQuery slug) decodePostBy
        |> GraphQl.send GotPost


stringifyTags : List String -> String
stringifyTags tags =
    toString tags
        |> Regex.replace Regex.All (Regex.regex "\"") (\_ -> "'")


relatedPostsQuery : List String -> Operation Query Variables
relatedPostsQuery tags =
    GraphQl.named "relatedPostsQuery"
        [ GraphQl.field "posts"
            |> GraphQl.withArgument "first" (GraphQl.int 4)
            |> GraphQl.withArgument "where" (GraphQl.queryArgs [ ( "tagSlugIn", (GraphQl.type_ (toString tags)) ) ])
            |> GraphQl.withSelectors
                [ GraphQl.field "edges"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "node"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "title"
                                , GraphQl.field "slug"
                                , GraphQl.field "excerpt"
                                , GraphQl.field "date"
                                , GraphQl.field "commentCount"
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
                                , GraphQl.field "featuredImage"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "sourceUrl"
                                        ]
                                ]
                        ]
                ]
        ]
        |> GraphQl.withVariables []


baseRelatedPostsRequest :
    Operation Query Variables
    -> Decoder RelatedPostsData
    -> GraphQl.Request Query Variables RelatedPostsData
baseRelatedPostsRequest =
    GraphQl.query graphqlEndpoint


relatedPostsRequest : List String -> Cmd Msg
relatedPostsRequest tags =
    baseRelatedPostsRequest (relatedPostsQuery tags) decodeRelatedPostsData
        |> GraphQl.send GotRelatedPosts


updatePosts : Model -> PostsData -> ( Model, Cmd Msg )
updatePosts model { posts } =
    let
        hasNextPage =
            posts.pageInfo.hasNextPage

        cursor =
            Maybe.withDefault "null" posts.pageInfo.endCursor

        newModel =
            { model | posts = List.append model.posts posts.edges }

        slug =
            case model.slug of
                Just slug ->
                    slug

                Nothing ->
                    ""

        nextCmd =
            if hasNextPage then
                postsRequest cursor
            else
                Cmd.batch [ (postRequest slug), Cmd.map SearchMsg Search.sendTagsRequest ]
    in
        ( newModel, nextCmd )


add1 : Int -> Int
add1 n =
    n + 1


subtract1 : Int -> Int
subtract1 n =
    n - 1


maybeSlug : Navigation.Location -> Maybe String
maybeSlug { hash } =
    if String.length hash > 0 then
        Just (String.dropLeft 1 hash)
    else
        Nothing


maybeLink : Model -> (Int -> Int) -> Maybe String
maybeLink model fn =
    let
        posts =
            List.map (\post -> post.slug) model.posts

        slug =
            case model.slug of
                Just val ->
                    val

                Nothing ->
                    ""

        index =
            elemIndex slug posts
    in
        case index of
            Just ind ->
                getAt (fn ind) posts

            Nothing ->
                Nothing


updatePost : Model -> PostBy -> Model
updatePost model postdata =
    let
        slug =
            postdata.postBy.slug

        newModel =
            { model
                | post = Just postdata.postBy
                , comments = postdata.postBy.comments.edges
            }
    in
        newModel


createRelatedPost : RelatedPostNode -> RelatedPost
createRelatedPost { node } =
    RelatedPost node.title node.slug node.excerpt node.commentCount node.featuredImage node.author


scrollToTop : Cmd Msg
scrollToTop =
    Task.attempt (always Scroll) <| toTop "elm-root"


createQueryTagString : TagEdges -> List String
createQueryTagString { edges } =
    List.map (\{ node } -> node.slug) edges


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Slug location ->
            let
                slug =
                    String.dropLeft 1 (Debug.log "hash" location.hash)
            in
                ( { model | slug = maybeSlug location }, postRequest slug )

        GotPosts (Ok postsdata) ->
            updatePosts model postsdata

        GotPosts (Err err) ->
            ( model, Cmd.none )

        GotPost (Ok postdata) ->
            ( updatePost model postdata, relatedPostsRequest (createQueryTagString postdata.postBy.tags) )

        GotPost (Err err) ->
            ( model, Cmd.none )

        GotRelatedPosts (Ok relatedposts) ->
            ( { model
                | related = (List.map createRelatedPost relatedposts.posts.edges)
                , prev = maybeLink model subtract1
                , next = maybeLink model add1
              }
            , scrollToTop
            )

        GotRelatedPosts (Err err) ->
            ( model, scrollToTop )

        Scroll ->
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


createPerson : Author -> Person
createPerson { name, bio, avatar, faith } =
    { name = name, bio = bio, avatar = avatar, faith = faith, tags = [] }


viewAuthor : Model -> Html.Html Msg
viewAuthor model =
    case model.post of
        Just post ->
            div
                [ classes [ relative, nt4, z_1 ]
                , classList [ ( "cmf-blue", True ) ]
                ]
                [ viewPerson True (createPerson post.author) ]

        Nothing ->
            div [] []


viewHero : Model -> Html.Html Msg
viewHero model =
    case model.post of
        Just post ->
            let
                image =
                    getFeaturedImageSrc post.featuredImage
            in
                div
                    [ style [ ( "background-image", "url(" ++ image ++ ")" ) ]
                    , classList [ ( "article-hero", True ) ]
                    ]
                    [ div
                        [ classList [ ( "article-card-title", True ) ]
                        , classes [ f2, f1_ns, pa2 ]
                        , setInnerHtml post.title
                        ]
                        []
                    ]

        Nothing ->
            div [] []


viewContent : Model -> Html.Html Msg
viewContent model =
    let
        content =
            case model.post of
                Just post ->
                    post.content

                Nothing ->
                    "..."
    in
        div
            [ setInnerHtml content
            , classes [ pa2, mw7, center ]
            ]
            []


viewPrevLink : Maybe String -> Html.Html Msg
viewPrevLink postLink =
    let
        url =
            case postLink of
                Just val ->
                    ("#" ++ val)

                Nothing ->
                    "/articles"

        label =
            case postLink of
                Just val ->
                    slugToTitle val

                Nothing ->
                    "back to articles"
    in
        Html.a
            [ Html.Attributes.href url
            , classes [ flex, items_center, justify_start, link, f3 ]
            , classList [ ( "cmf-blue", True ) ]
            ]
            [ div [ classes [ ph4 ], style [ ( "transform", "rotate(180deg)" ) ] ] [ chevBlue ]
            , div [ classes [ link, dn, db_m, db_l ] ] [ text label ]
            , div [ classes [ link, dn_ns ], classList [ ( "cmf-blue", True ) ] ] [ text "Prev" ]
            ]


viewNextLink : Maybe String -> Html.Html Msg
viewNextLink postLink =
    let
        url =
            case postLink of
                Just val ->
                    ("#" ++ val)

                Nothing ->
                    "/articles"

        label =
            case postLink of
                Just val ->
                    slugToTitle val

                Nothing ->
                    "back to articles"
    in
        Html.a
            [ Html.Attributes.href url
            , classes [ flex, items_center, justify_start, link, f3 ]
            , classList [ ( "cmf-blue", True ) ]
            ]
            [ div [ classes [ link, dn, db_m, db_l, tr ] ] [ text label ]
            , div [ classes [ link, dn_ns ] ] [ text "Next" ]
            , div [ classes [ ph4 ] ] [ chevBlue ]
            ]


viewLinks : Model -> Html.Html Msg
viewLinks model =
    div [ classes [ flex, items_center, justify_between, pv4 ] ]
        [ viewPrevLink model.prev
        , viewNextLink model.next
        ]


viewComments : Model -> Html.Html Msg
viewComments { comments } =
    if List.isEmpty comments then
        div [] []
    else
        div [ classList [ ( "article-person", True ) ] ] (List.map viewComment comments)


viewComment : Node -> Html.Html Msg
viewComment { node } =
    div []
        [ viewPerson True (createPerson node.author)
        , div
            [ setInnerHtml node.content
            , classes [ mw7, center, ph3, pt3 ]
            ]
            []
        ]


viewPage : Model -> Html.Html Msg
viewPage model =
    let
        title =
            case model.post of
                Just val ->
                    val.title

                Nothing ->
                    "Christian Muslim Forum Article"
    in
        node "html"
            []
            [ head "Article"
            , node "body"
                [ Html.Attributes.style [ ( "min-height", "100vh" ) ] ]
                [ div [ id "elm-root" ] [ view model ]
                , node "script" [ src "article.js" ] []
                , node "script" [ id "elm-js" ] []
                ]
            ]


viewRelatedPosts : Model -> Html.Html Msg
viewRelatedPosts model =
    if List.isEmpty model.related then
        div [] []
    else
        div [ classes [ fl, w_100, w_two_thirds_ns ] ]
            [ div
                [ classes [ f2, pa2, pv4 ]
                , classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
                ]
                [ text "Related Articles" ]
            , div
                [ classList [ ( "bg_cmf_teal", True ) ]
                , classes [ nt2 ]
                ]
                (List.map viewRelatedPost model.related)
            ]


viewRelatedPost : RelatedPost -> Html.Html msg
viewRelatedPost post =
    div [ classes [ pa2, fl, w_100, w_50_ns ] ] [ Search.viewSearchResult post ]


viewSearch : Model -> Html.Html Msg
viewSearch model =
    div [ classes [ fl, w_100, w_third_ns, pr2_ns ] ]
        [ div
            [ classes [ pa2, f2, tr, ph4 ]
            , classList [ ( "feature-font", True ), ( "cmf-blue", True ) ]
            ]
            [ text "Search" ]
        , Html.map SearchMsg (Search.view model.searchModel)
        ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , node "main"
            [ classes [ lh_copy, pa0 ]
            ]
            [ viewHero model
            , viewAuthor model
            , viewContent model
            , viewComments model
            , viewLinks model
            , viewRelatedPosts model
            , viewSearch model
            ]
        , Html.map FooterMsg (Footer.view model.footerModel)
        ]
