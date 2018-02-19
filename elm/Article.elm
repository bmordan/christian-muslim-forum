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
import List.Extra exposing (elemIndex, getAt)
import Config exposing (graphqlEndpoint, frontendUrl)
import GraphQl exposing (Operation, Variables, Query, Named)
import Helpers exposing (setInnerHtml, forumIcon, capitalise, viewPerson, formatDate)
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( pa2
        , pa3
        , pt2
        , pt3
        , flex
        , justify_end
        , justify_start
        , flex_none
        , flex_auto
        , mr2
        , br_100
        , items_center
        , bg_light_gray
        , bg_dark_gray
        , white
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
        , ph3
        , pb3
        , pa0
        , pl2
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
    , prev = Nothing
    , next = Nothing
    , slug = maybeSlug location
    , comments = []
    , headerModel = Header.initModel
    , footerModel = Footer.initModel
    }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( initModel location, postsRequest "null" )


type Msg
    = Slug Navigation.Location
    | GotPosts (Result Http.Error PostsData)
    | GotPost (Result Http.Error PostBy)
    | Scroll
    | HeaderMsg Header.Msg
    | FooterMsg Footer.Msg


type alias PostsData =
    { posts : Posts
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


type alias Post =
    { slug : String
    , title : String
    , content : String
    , date : String
    , author : Author
    , featuredImage : Maybe FeaturedImage
    , commentCount : Maybe Int
    , comments : Edges
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
    , prev : Maybe String
    , next : Maybe String
    , slug : Maybe String
    , comments : List Node
    , headerModel : Header.Model
    , footerModel : Footer.Model
    }


type alias HeaderModel =
    { scrollLeft : Bool
    }


type alias FooterModel =
    { modal : Bool
    , fname : String
    , lname : String
    , email : String
    , message : String
    }


decodePostsData : Decoder PostsData
decodePostsData =
    decode PostsData
        |> required "posts" decodePosts


decodePosts : Decoder Posts
decodePosts =
    decode Posts
        |> required "pageInfo" decodePageInfo
        |> required "edges" (Decode.list decodePostLabel)


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
        |> required "prev" (nullable string)
        |> required "next" (nullable string)
        |> required "slug" (nullable string)
        |> required "comments" (Decode.list decodeNode)
        |> required "headerModel" decodeHeaderModel
        |> required "footerModel" decodeFooterModel


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
                postRequest slug
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
                , prev = maybeLink model subtract1
                , next = maybeLink model add1
                , comments = postdata.postBy.comments.edges
            }
    in
        newModel


scrollToTop : Cmd Msg
scrollToTop =
    Task.attempt (always Scroll) <| toTop "elm-root"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Slug location ->
            let
                slug =
                    String.dropLeft 1 location.hash
            in
                ( { model | slug = maybeSlug location }, postRequest slug )

        GotPosts (Ok postsdata) ->
            updatePosts model postsdata

        GotPosts (Err err) ->
            ( model, Cmd.none )

        GotPost (Ok postdata) ->
            ( updatePost model postdata, scrollToTop )

        GotPost (Err err) ->
            ( model, Cmd.none )

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


viewFeaturedImage : Maybe FeaturedImage -> String
viewFeaturedImage featured =
    case featured of
        Just val ->
            val.sourceUrl

        Nothing ->
            "/defaultImg.jpg"


createPerson : Author -> Person
createPerson { name, bio, avatar, faith } =
    { name = name, bio = bio, avatar = avatar, faith = faith, tags = [] }


viewPost : Model -> Html.Html Msg
viewPost model =
    case model.post of
        Just post ->
            div [ Html.Attributes.id post.slug ]
                [ div
                    [ style [ ( "background-image", "url(" ++ (viewFeaturedImage post.featuredImage) ++ ")" ) ]
                    , classList [ ( "article-hero", True ) ]
                    ]
                    [ div [ classList [ ( "article-card-title", True ) ] ]
                        [ div
                            [ setInnerHtml post.title
                            , classes [ pa3, f3 ]
                            , classList [ ( "feature-font", True ) ]
                            ]
                            [ div [ classes [ f5 ] ] [ text (formatDate "%e %b '%y" post.date) ] ]
                        , forumIcon post.commentCount
                        ]
                    ]
                , div [ classList [ ( "article-person", True ) ] ] [ (viewPerson True (createPerson post.author)) ]
                , div
                    [ setInnerHtml post.content
                    , classes [ pa3, mw7, center ]
                    , classList [ ( "article-copy", True ) ]
                    ]
                    []
                ]

        Nothing ->
            div [] []


viewPrevLink : Maybe String -> Html.Html Msg
viewPrevLink postLink =
    case postLink of
        Just link ->
            a [ Html.Attributes.href ("#" ++ link) ] [ text ("<- " ++ link) ]

        Nothing ->
            a [ Html.Attributes.href "/articles" ] [ text "<- back to articles" ]


viewNextLink : Maybe String -> Html.Html Msg
viewNextLink postLink =
    case postLink of
        Just link ->
            a [ Html.Attributes.href ("#" ++ link) ] [ text (link ++ " ->") ]

        Nothing ->
            a [ Html.Attributes.href "/articles" ] [ text "back to articles ->" ]


viewLinks : Model -> Html.Html Msg
viewLinks model =
    div [ classes [ pt3 ] ]
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
            [ node "head"
                []
                [ node "link" [ href "https://unpkg.com/tachyons@4.9.0/css/tachyons.min.css", rel "stylesheet" ] []
                , node "link" [ href "/style.css", rel "stylesheet" ] []
                , node "meta" [ name "viewport", content "width=device-width, initial-scale=1.0" ] []
                , node "title" [] [ text title ]
                , node "script" [ src "https://platform.twitter.com/widgets.js" ] []
                ]
            , node "body"
                [ Html.Attributes.style [ ( "min-height", "100vh" ) ] ]
                [ div [ id "elm-root" ] [ view model ]
                , node "script" [ src "article.js" ] []
                , node "script" [ id "elm-js" ] []
                ]
            ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , node "main"
            [ classes [ lh_copy, pa0 ]
            ]
            [ viewPost model
            , viewComments model
            , viewLinks model
            ]
        , Html.map FooterMsg (Footer.view model.footerModel)
        ]
