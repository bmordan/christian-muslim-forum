module Search exposing (..)

import Html exposing (text, div, input, span, img)
import Html.Attributes exposing (href, src, id, content, rel, name, value, classList, style)
import Html.Events exposing (onClick, onInput, onFocus)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, requiredAt)
import Helpers exposing (setInnerHtml, head, onKeyDown, getFeaturedImageSrc, trim160)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw5
        , mw7
        , ml2
        , mb2
        , lh_copy
        , pt2
        , pb3
        , pb2
        , ph2
        , ph3
        , pa1
        , pa2
        , pl2
        , pv2
        , underline
        , br2
        , flex
        , flex_auto
        , flex_none
        , flex_wrap
        , items_start
        , items_center
        , justify_end
        , v_top
        , w_100
        , br_100
        , dib
        , nl2
        , nr2
        , pointer
        , relative
        , near_black
        , near_white
        , bg_near_white
        , link
        , tr
        , h3
        , w3
        )


initModel : Model
initModel =
    Model "" "" [] []


type Msg
    = GotTags (Result Error Tags)
    | GotSearch (Result Error Results)
    | Term String
    | Search
    | AutoSearch String
    | Clear
    | KeyDown Int


type alias Model =
    { term : String
    , currentTerm : String
    , tags : List Tag
    , results : List SearchResult
    }


type alias Tags =
    { tags : TagsEdges }


type alias TagsEdges =
    { edges : List TagNode }


type alias TagNode =
    { node : Tag }


type alias Tag =
    { slug : String
    , count : Int
    }


type alias Results =
    { posts : ResultsEdges }


type alias ResultsEdges =
    { edges : List NodeResult }


type alias NodeResult =
    { node : SearchResult }


type alias SearchResult =
    { title : String
    , slug : String
    , excerpt : String
    , commentCount : Maybe Int
    , featuredImage : Maybe FeaturedImage
    , author : Author
    }


type alias FeaturedImage =
    { sourceUrl : String
    }


type alias Author =
    { name : String
    , faith : String
    , bio : String
    , avatar : String
    }


decodeTags : Decoder Tags
decodeTags =
    decode Tags
        |> required "tags" decodeTagsEdges


decodeTagsEdges : Decoder TagsEdges
decodeTagsEdges =
    decode TagsEdges
        |> required "edges" (Decode.list decodeTagNode)


decodeTagNode : Decoder TagNode
decodeTagNode =
    decode TagNode
        |> required "node" decodeTag


decodeTag : Decoder Tag
decodeTag =
    decode Tag
        |> required "slug" string
        |> required "count" int


decodeResults : Decoder Results
decodeResults =
    decode Results
        |> required "posts" decodeResultsEdges


decodeResultsEdges : Decoder ResultsEdges
decodeResultsEdges =
    decode ResultsEdges
        |> required "edges" (Decode.list decodeNodeResult)


decodeNodeResult : Decoder NodeResult
decodeNodeResult =
    decode NodeResult
        |> required "node" decodeSearchResult


decodeSearchResult : Decoder SearchResult
decodeSearchResult =
    decode SearchResult
        |> required "title" string
        |> required "slug" string
        |> required "excerpt" string
        |> required "commentCount" (nullable int)
        |> required "featuredImage" (nullable decodeFeaturedImage)
        |> required "author" decodeAuthor


decodeFeaturedImage : Decoder FeaturedImage
decodeFeaturedImage =
    decode FeaturedImage
        |> required "sourceUrl" string


decodeAuthor : Decoder Author
decodeAuthor =
    decode Author
        |> required "name" string
        |> required "bio" string
        |> required "faith" string
        |> requiredAt [ "avatar", "url" ] string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "term" string
        |> required "currentTerm" string
        |> required "tags" (Decode.list decodeTag)
        |> required "results" (Decode.list decodeSearchResult)


tagsQuery : Operation Query Variables
tagsQuery =
    GraphQl.named "tags"
        [ GraphQl.field "tags"
            |> GraphQl.withArgument "last" (GraphQl.int 23)
            |> GraphQl.withArgument "where" (GraphQl.queryArgs [ ( "orderby", GraphQl.type_ "COUNT" ) ])
            |> GraphQl.withSelectors
                [ GraphQl.field "edges"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "node"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "slug"
                                , GraphQl.field "count"
                                ]
                        ]
                ]
        ]
        |> GraphQl.withVariables []


baseTagsRequest :
    Operation Query Variables
    -> Decoder Tags
    -> GraphQl.Request Query Variables Tags
baseTagsRequest =
    GraphQl.query graphqlEndpoint


sendTagsRequest : Cmd Msg
sendTagsRequest =
    baseTagsRequest tagsQuery decodeTags
        |> GraphQl.send GotTags


searchQuery : String -> String -> Operation Query Variables
searchQuery field term =
    GraphQl.named "search"
        [ GraphQl.field "posts"
            |> GraphQl.withArgument "first" (GraphQl.int 26)
            |> GraphQl.withArgument "where" (GraphQl.queryArgs [ ( field, GraphQl.string term ) ])
            |> GraphQl.withSelectors
                [ GraphQl.field "edges"
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


baseSearchRequest :
    Operation Query Variables
    -> Decoder Results
    -> GraphQl.Request Query Variables Results
baseSearchRequest =
    GraphQl.query graphqlEndpoint


sendSearchRequest : String -> String -> Cmd Msg
sendSearchRequest field term =
    baseSearchRequest (searchQuery field term) decodeResults
        |> GraphQl.send GotSearch


createSearchResult : NodeResult -> SearchResult
createSearchResult { node } =
    SearchResult node.title node.slug node.excerpt node.commentCount node.featuredImage node.author


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTags (Ok tags) ->
            let
                searchabletags =
                    List.map (\{ node } -> Tag node.slug node.count) tags.tags.edges
            in
                ( { model | tags = searchabletags }, Cmd.none )

        GotTags (Err err) ->
            ( model, Cmd.none )

        GotSearch (Ok results) ->
            let
                searchresults =
                    List.map createSearchResult results.posts.edges

                currentTerm =
                    model.term
            in
                ( { model
                    | currentTerm = currentTerm
                    , results = searchresults
                  }
                , Cmd.none
                )

        GotSearch (Err err) ->
            ( model, Cmd.none )

        Term str ->
            ( { model | term = str }, Cmd.none )

        Search ->
            if (model.term /= "") then
                ( model, (sendSearchRequest "search" model.term) )
            else
                ( model, Cmd.none )

        AutoSearch term ->
            ( { model | term = term }, (sendSearchRequest "tag" term) )

        Clear ->
            ( { model | term = "", results = [], currentTerm = "" }, Cmd.none )

        KeyDown code ->
            if (code == 13 && model.term /= "") then
                ( model, (sendSearchRequest "search" model.term) )
            else
                ( model, Cmd.none )


viewPage : Model -> Html.Html Msg
viewPage model =
    div [ id "search" ] [ view model ]


viewSearchSuggestions : Tag -> Html.Html Msg
viewSearchSuggestions { slug } =
    div
        [ classes [ dib, pa2, underline, v_top, pointer, near_white ]
        , onClick (AutoSearch slug)
        ]
        [ text slug ]


viewResultsHeading : Model -> Html.Html Msg
viewResultsHeading model =
    let
        resultsLength =
            model.results
                |> List.length

        plural =
            if resultsLength == 1 then
                ""
            else
                "s "

        header =
            (toString resultsLength) ++ " search result" ++ plural ++ " for " ++ model.currentTerm
    in
        div [ classes [ pv2 ] ] [ text header ]


viewSearchResult : SearchResult -> Html.Html Msg
viewSearchResult result =
    let
        image =
            getFeaturedImageSrc result.featuredImage

        forum =
            case result.commentCount of
                Just count ->
                    span [] [ img [ src (frontendUrl ++ "/forum.svg") ] [] ]

                Nothing ->
                    span [] []
    in
        Html.a
            [ href (frontendUrl ++ "/article.html#" ++ result.slug)
            , classes [ relative, flex, items_start, link, near_black, pb2, bg_near_white, mb2 ]
            ]
            [ div
                [ style [ ( "background-image", "url(" ++ image ++ ")" ) ]
                , classList [ ( "result-img", True ) ]
                , classes [ flex_none ]
                ]
                []
            , div [ classes [ pl2 ] ]
                [ div [ classList [ ( "cmf-blue", True ), ( "feature-font", True ) ] ] [ text result.title ]
                , div [ classList [ ( "article-forum-icon", True ) ] ] [ forum ]
                , div [ setInnerHtml (trim160 result.excerpt) ] []
                , div
                    [ classes [ flex, items_center, justify_end ]
                    , classList [ ( "cmf-teal", True ) ]
                    ]
                    [ text result.author.name
                    , img
                        [ src result.author.avatar
                        , classes [ br_100, h3, w3, ml2, flex_none ]
                        ]
                        []
                    ]
                ]
            ]


view : Model -> Html.Html Msg
view model =
    div
        [ classes [ pa2 ]
        , classList [ ( "bg_cmf_blue", True ) ]
        ]
        [ div
            [ classes [ flex, items_center, justify_end, br2, bg_near_white ]
            , classList [ ( "search-box", True ) ]
            ]
            [ input
                [ onInput Term
                , onKeyDown KeyDown
                , onFocus Clear
                , value model.term
                , classes [ pa2, flex_auto ]
                ]
                []
            , img
                [ onClick Search
                , src (frontendUrl ++ "/search.svg")
                , classes [ ph2, flex_none ]
                ]
                []
            ]
        , if List.isEmpty model.results then
            div [ classes [ flex_wrap, nl2, nr2 ] ] (List.map viewSearchSuggestions model.tags)
          else
            div []
                [ viewResultsHeading model
                , div [] (List.map viewSearchResult model.results)
                ]
        ]
