module Search exposing (..)

import Html exposing (text, div, input, span, img)
import Html.Attributes exposing (href, src, id, content, rel, name, value)
import Html.Events exposing (onClick, onInput, onFocus)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, requiredAt)
import Helpers exposing (setInnerHtml, head)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw7
        , lh_copy
        , pb3
        , ph3
        , pa2
        , underline
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
            { term = ""
            , currentTerm = ""
            , tags = []
            , results = []
            }
    in
        ( model, sendTagsRequest )


type Msg
    = GotTags (Result Error Tags)
    | GotSearch (Result Error Results)
    | Term String
    | Search
    | AutoSearch String
    | Clear


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
                    | term = ""
                    , currentTerm = currentTerm
                    , results = searchresults
                  }
                , Cmd.none
                )

        GotSearch (Err err) ->
            ( model, Cmd.none )

        Term str ->
            ( { model | term = str }, Cmd.none )

        Search ->
            ( model, (sendSearchRequest "search" model.term) )

        AutoSearch term ->
            ( { model | term = term }, (sendSearchRequest "tag" term) )

        Clear ->
            ( { model | term = "", results = [], currentTerm = "" }, Cmd.none )


viewSearchSuggestions : Tag -> Html.Html Msg
viewSearchSuggestions { slug } =
    span
        [ classes [ pa2, underline ]
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
        div [ classes [ pa2 ] ] [ text header ]


viewSearchResult : SearchResult -> Html.Html Msg
viewSearchResult result =
    div []
        [ div [] [ text result.title ]
        , div [ setInnerHtml result.excerpt ] []
        ]


view : Model -> Html.Html Msg
view model =
    div []
        [ div []
            [ input [ onInput Term, onFocus Clear, value model.term, classes [ pa2 ] ] []
            , img [ onClick Search, src (frontendUrl ++ "/search.svg") ] []
            ]
        , if List.isEmpty model.results then
            div [] (List.map viewSearchSuggestions model.tags)
          else
            div []
                [ viewResultsHeading model
                , div [] (List.map viewSearchResult model.results)
                ]
        ]
