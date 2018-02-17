module Contact exposing (..)

import Html exposing (text, div, node, img, h2)
import Html.Attributes exposing (href, src, id, content, rel, name, classList, style)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, requiredAt, optional)
import Helpers exposing (setInnerHtml)
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
        , justify_start
        , items_center
        , items_start
        , center
        , mw7
        , mt4
        , mb6
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
            , footerModel = Footer.initModel
            , content = ""
            , people = []
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
    { slug : String }


type alias WordpressPerson =
    { title : String
    , content : String
    , featuredImage : FeaturedImage
    , categories : CategorgyEdges
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


type alias Person =
    { name : String
    , bio : String
    , avatar : String
    , faith : String
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


decodeFeaturedImage : Decoder FeaturedImage
decodeFeaturedImage =
    decode FeaturedImage
        |> required "sourceUrl" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" decodeHeaderModel
        |> required "footerModel" decodeFooterModel
        |> required "content" string
        |> required "people" (Decode.list decodePerson)


decodePerson : Decoder Person
decodePerson =
    decode Person
        |> required "name" string
        |> required "bio" string
        |> required "avatar" string
        |> required "faith" string


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


pageRequest : Operation Query Variables
pageRequest =
    GraphQl.named "query"
        [ GraphQl.field "pageBy"
            |> GraphQl.withArgument "uri" (GraphQl.string "contact")
            |> GraphQl.withSelectors [ GraphQl.field "content" ]
        , GraphQl.field "people"
            |> GraphQl.withArgument "where" (GraphQl.queryArgs [ ( "categoryName", (GraphQl.string "staff") ) ])
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
    in
        Person name bio avatar faith


createPeopleList : Edges -> List Person
createPeopleList { edges } =
    List.map (\{ node } -> createPerson node) edges


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
        [ node "head"
            []
            [ node "link" [ href "https://unpkg.com/tachyons@4.9.0/css/tachyons.min.css", rel "stylesheet" ] []
            , node "link" [ href "/style.css", rel "stylesheet" ] []
            , node "meta" [ name "viewport", content "width=device-width, initial-scale=1.0" ] []
            , node "title" [] [ text "Contact Us" ]
            , node "script" [ src "https://platform.twitter.com/widgets.js" ] []
            ]
        , node "body"
            [ Html.Attributes.style [ ( "min-height", "100vh" ) ] ]
            [ div [ id "elm-root" ] [ view model ]
            , node "script" [ src "bundle.js" ] []
            , node "script" [ id "elm-js" ] []
            ]
        ]


viewPerson : Person -> Html.Html Msg
viewPerson person =
    div [ classes [ mb6, mt4 ] ]
        [ div [ classList [ ( "person", True ) ] ]
            [ if person.faith == "christian" then
                viewChristianPerson person
              else
                viewMuslimPerson person
            ]
        , div [ classes [ db, pa3, mw7, mt4, center ], setInnerHtml person.bio ] []
        ]


viewChristianPerson : Person -> Html.Html Msg
viewChristianPerson person =
    div
        [ classes [ flex, items_center, justify_start, mw7, center ]
        , classList [ ( "person", True ) ]
        ]
        [ div
            [ classes [ br_100, flex_none, nl4, ml0_ns ]
            , classList [ ( "avatar", True ) ]
            , style [ ( "background-image", "url(" ++ person.avatar ++ ")" ) ]
            ]
            []
        , div [ classes [ flex_auto ] ]
            [ div
                [ classes [ f4, pl2, pl3_ns ]
                , classList [ ( "cmf-blue", True ) ]
                ]
                [ text person.name ]
            ]
        , img [ src (frontendUrl ++ "/cross.svg"), classes [ flex_none, pr3 ], classList [ ( "icon", True ) ] ] []
        ]


viewMuslimPerson : Person -> Html.Html Msg
viewMuslimPerson person =
    div
        [ classes [ flex, items_center, justify_start, mw7, center ]
        , classList [ ( "person", True ) ]
        ]
        [ img
            [ src (frontendUrl ++ "/moon.svg")
            , classes [ flex_none, pl3 ]
            , classList [ ( "icon", True ) ]
            ]
            []
        , div [ classes [ flex_auto ] ]
            [ div
                [ classes [ f4, pr2, pr3_ns, tr ]
                , classList [ ( "cmf-blue", True ) ]
                ]
                [ text person.name ]
            ]
        , div
            [ classes [ br_100, flex_none, nr4, mr0_ns ]
            , classList [ ( "avatar", True ) ]
            , style [ ( "background-image", "url(" ++ person.avatar ++ ")" ) ]
            ]
            []
        ]


view : Model -> Html.Html Msg
view model =
    div []
        [ Html.map HeaderMsg (Header.view model.headerModel)
        , node "main"
            [ classes [ lh_copy ] ]
            [ div [ setInnerHtml model.content, classes [ ph3, pb3, center, mw7 ] ] []
            , if List.isEmpty model.people then
                div [] []
              else
                div [] (List.map viewPerson model.people)
            ]
        , Html.map FooterMsg (Footer.view model.footerModel)
        ]
