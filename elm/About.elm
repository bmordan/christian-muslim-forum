module About exposing (..)

import Html exposing (text, div, node)
import Html.Attributes exposing (href, src, id, content, rel, name, classList)
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder, field, int, string, list, bool, nullable)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Helpers exposing (setInnerHtml, head, OpenGraphTags, getFeaturedImageSrc)
import GraphQl exposing (Operation, Variables, Query, Named)
import Config exposing (graphqlEndpoint, frontendUrl)
import Header
import Footer
import Tachyons exposing (..)
import Tachyons.Classes
    exposing
        ( center
        , mw7
        , lh_copy
        , pb3
        , ph3
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
            }
    in
        ( model, sendRequest )


type Msg
    = GotContent (Result Error Data)
    | HeaderMsg Header.Msg


type alias Model =
    { headerModel : Header.Model
    , content : String
    }


type alias Data =
    { pageBy : Page }


type alias Page =
    { content : String
    }


type alias HeaderModel =
    Header.Model


decodeData : Decoder Data
decodeData =
    decode Data
        |> required "pageBy" decodePage


decodePage : Decoder Page
decodePage =
    decode Page
        |> required "content" string


decodeModel : Decoder Model
decodeModel =
    decode Model
        |> required "headerModel" Header.decodeModel
        |> required "content" string


pageRequest : Operation Query Variables
pageRequest =
    GraphQl.named "query"
        [ GraphQl.field "pageBy"
            |> GraphQl.withArgument "uri" (GraphQl.string "about-us")
            |> GraphQl.withSelectors [ GraphQl.field "content" ]
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotContent (Ok data) ->
            ( { model | content = data.pageBy.content }, Cmd.none )

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
    OpenGraphTags "About us" "The Christian Muslim Forum launched in January 2006, realising a strategic initiative, begun by the Archbishop of Canterbury in 2001, considering the advisability of a bilateral forum bringing together in one body the range of Christian Churches and Muslim traditions in England." (getFeaturedImageSrc Nothing) (frontendUrl ++ "/about-us")


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
        , if (model.content == "") then
            node "main" [ classList [ ( "loading", True ) ] ] []
          else
            node "main"
                [ setInnerHtml model.content
                , classes [ ph3, pb3, center, mw7, lh_copy ]
                ]
                []
        , Footer.view
        ]
