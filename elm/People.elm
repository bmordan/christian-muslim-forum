module People exposing (..)

import Html exposing (text, div, node, img, h2)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, requiredAt, optional)
import Helpers exposing (setInnerHtml, slugToTitle, viewPerson, head, OpenGraphTags, getFeaturedImageSrc)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Header
import Footer
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( flex
        , flex_auto
        , flex_none
        , flex_column
        , justify_start
        , justify_between
        , items_center
        , items_start
        , center
        , mw7
        , mb6
        , mt4
        , ph3
        , pa3
        , pr2
        , pr3
        , pl3
        , pb3
        , br_100
        , db
        , pl2
        , f4
        , tr
        , nl4
        , nr4
        , ml0_ns
        , mr0_ns
        , pr3_ns
        , pl3_ns
        , lh_copy
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
            , content = ""
            , people = []
            }
    in
        ( model, sendRequest )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg


type alias Model =
    { headerModel : Header.Model
    , content : String
    , people : List Person
    }


type alias Data =
    { pageBy : Page
    , people : Edges
    }


type alias Page =
    { content : String
    }


type alias Edges =
    { edges : List Node
    }


type alias Node =
    { node : WordpressPerson
    }


type alias FeaturedImage =
    { sourceUrl : String
    }


type alias CategorgyEdges =
    { edges : List SlugNode
    }


type alias SlugNode =
    { node : Slug }


type alias Slug =
    { slug : String
    , name : String
    }


type alias WordpressPerson =
    { title : String
    , content : String
    , featuredImage : FeaturedImage
    , categories : CategorgyEdges
    }


type alias HeaderModel =
    { showMenu : Bool
    }



type alias Person =
    { name : String
    , bio : String
    , avatar : String
    , faith : String
    , tags : List Slug
    }


decodeData : Decoder Data
decodeData =
    decode Data
        |> required "pageBy" decodePage
        |> required "people" decodeEdges


decodePage : Decoder Page
decodePage =
    decode Page
        |> required "content" string


decodeEdges : Decoder Edges
decodeEdges =
    decode Edges
        |> required "edges" (Decode.list decodeNode)


decodeNode : Decoder Node
decodeNode =
    decode Node
        |> required "node" decodeWordpressPerson


decodeWordpressPerson : Decoder WordpressPerson
decodeWordpressPerson =
    decode WordpressPerson
        |> required "title" string
        |> required "content" string
        |> required "featuredImage" decodeFeaturedImage
        |> required "categories" decodeCategorgyEdges


decodeCategorgyEdges : Decoder CategorgyEdges
decodeCategorgyEdges =
    decode CategorgyEdges
        |> required "edges" (Decode.list decodeSlugNode)


decodeSlugNode : Decoder SlugNode
decodeSlugNode =
    decode SlugNode
        |> required "node" decodeSlug


decodeSlug : Decoder Slug
decodeSlug =
    decode Slug
        |> required "slug" string
        |> required "name" string


decodeFeaturedImage : Decoder FeaturedImage
decodeFeaturedImage =
    decode FeaturedImage
        |> required "sourceUrl" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" decodeHeaderModel
        |> required "content" string
        |> required "people" (Decode.list decodePerson)


decodePerson : Decoder Person
decodePerson =
    decode Person
        |> required "name" string
        |> required "bio" string
        |> required "avatar" string
        |> required "faith" string
        |> required "tags" (Decode.list decodeSlug)


decodeHeaderModel : Decoder HeaderModel
decodeHeaderModel =
    decode HeaderModel
        |> required "showMenu" bool



pageRequest : Operation Query Variables
pageRequest =
    GraphQl.named "query"
        [ GraphQl.field "pageBy"
            |> GraphQl.withArgument "uri" (GraphQl.string "people")
            |> GraphQl.withSelectors [ GraphQl.field "content" ]
        , GraphQl.field "people"
            |> GraphQl.withArgument "first" (GraphQl.int 100)
            |> GraphQl.withSelectors
                [ GraphQl.field "edges"
                    |> GraphQl.withSelectors
                        [ GraphQl.field "node"
                            |> GraphQl.withSelectors
                                [ GraphQl.field "title"
                                , GraphQl.field "content"
                                , GraphQl.field "featuredImage"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "sourceUrl"
                                        ]
                                , GraphQl.field "categories"
                                    |> GraphQl.withSelectors
                                        [ GraphQl.field "edges"
                                            |> GraphQl.withSelectors
                                                [ GraphQl.field "node"
                                                    |> GraphQl.withSelectors
                                                        [ GraphQl.field "slug"
                                                        , GraphQl.field "name"
                                                        ]
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


findFaith : List SlugNode -> String
findFaith edges =
    List.map (\{ node } -> node.slug) edges
        |> List.filter (\slug -> (slug == "christian" || slug == "muslim"))
        |> List.head
        |> Maybe.withDefault ""


createPerson : WordpressPerson -> Person
createPerson { title, content, featuredImage, categories } =
    let
        name =
            title

        bio =
            content

        avatar =
            featuredImage.sourceUrl

        faith =
            findFaith categories.edges

        tags =
            List.map (\{ node } -> node) categories.edges
    in
        Person name bio avatar faith tags


createPeopleList : Edges -> List Person
createPeopleList { edges } =
    List.map (\{ node } -> createPerson node) edges
        |> orderPeopleList


withTag : String -> List Person -> List Person
withTag tag people =
    List.filter (\person -> (List.any (\t -> t.slug == tag) person.tags)) people


orderPeopleList : List Person -> List Person
orderPeopleList people =
    let
        patron =
            withTag "patron" people

        presidents =
            withTag "president" people

        trustees =
            withTag "trustee" people

        contributors =
            withTag "contributer" people

        specialists =
            withTag "specialist" people

        consultants =
            withTag "scholar-consultant" people

        alumni =
            withTag "cmf-alumni" people
    in
        List.concat [ patron, trustees, consultants, presidents, specialists, alumni ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotContent (Ok data) ->
            ( { model
                | content = data.pageBy.content
                , people = createPeopleList data.people
              }
            , Cmd.none
            )

        GotContent (Err err) ->
            ( model, Cmd.none )

        HeaderMsg subMsg ->
            let
                ( updatedHeaderModel, headerCmd ) =
                    Header.update subMsg model.headerModel
            in
                ( { model | headerModel = updatedHeaderModel }, Cmd.map HeaderMsg headerCmd )



openGraphTags : OpenGraphTags
openGraphTags =
    OpenGraphTags "Our People" "Our presidents, trustees and contributors" (getFeaturedImageSrc Nothing) (frontendUrl ++ "/people")


viewPage : Model -> Html.Html Msg
viewPage model =
    node "html"
        []
        [ head openGraphTags
        , node "body"
            [ Html.Attributes.style [ ( "min-height", "100vh" ) ] ]
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
            [ classes [ lh_copy ] ]
            [ div [ setInnerHtml model.content, classes [ ph3, pb3, center, mw7 ] ] []
            , if List.isEmpty model.people then
                div [ classList [ ( "loading", True ) ] ] []
              else
                div [] (List.map (viewPerson False) model.people)
            ]
        , Footer.view
        ]
