port module Main exposing (main)

import Browser
import Browser.Dom exposing (getViewport)
import Browser.Events exposing (onAnimationFrameDelta, onResize)
import Html exposing (Html, div, button, text)
import Html.Attributes exposing (width, height, style)
import Html.Events exposing (onClick)
import WebGL exposing (Mesh, Shader)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Task
import Json.Decode as Decode exposing (Decoder, field, int)
import Json.Encode as Encode
import Http

import Debug exposing (log)

main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


type alias Model =
    { screenWidth : Float
    , screenHeight : Float
    , dt : Float
    , debug : String
    , model : String
    }

type Msg
    = Resize Float Float
    | Tick Float
    | ButtonClick
    | MeshLoaded String
    | DataFetched (Result Http.Error String)

port loadedMesh : (String -> msg) -> Sub msg


init : (Model, Cmd Msg)
init =
    ( { 
      screenWidth = 500
    , screenHeight = 500
    , dt = 0
    , debug = ""
    , model = "default model"
    }
    , Task.perform (\{viewport} -> Resize viewport.width viewport.height) getViewport
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
    [ onResize (\w h -> Resize (toFloat w) (toFloat h))
    , onAnimationFrameDelta Tick
    , loadedMesh MeshLoaded
    ]
    
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Tick frame_dt ->
            ({ model
                | dt = model.dt + frame_dt
            }
            , Cmd.none)
        
        Resize w h ->
            ( { model
                | screenWidth = w,
                  screenHeight = h
              }
            , Cmd.none)

        ButtonClick ->
            ( model
            , Http.send DataFetched (Http.getString "https://twostepsfrombadcode.com/data"))

        MeshLoaded input ->
            ( { model
                | model = input
            }
            , Cmd.none)

        DataFetched (Ok data) ->
            ( { model
                | model = data
            } |> log "fetched new data!",
            Cmd.none)

        DataFetched (Err err) ->
            ( { model
                | model = log "DataFetched" "err"
            }
            , Cmd.none)

testDecoder : Decoder Int
testDecoder =
    field "test" int

view : Model -> Html Msg
view model =
    div
    [ style "position" "absolute"
    , style "top" "0"
    , style "left" "0"
    ]
    [ renderWebGL model
    , renderTestingButton
    , renderModel model
    , renderOtherButton
    ]
    

renderWebGL : Model -> Html msg
renderWebGL model =
    WebGL.toHtmlWith
        [ WebGL.clearColor 0.3 0.3 0.3 1
        , WebGL.alpha True
        , WebGL.antialias
        , WebGL.depth 1
        ]
        [ width (round model.screenWidth)
        , height (round model.screenHeight)
        , style "display" "block"
        ]
        (let
            aspectRatio =
                model.screenWidth / model.screenHeight
        in
        [ WebGL.entity
            vertexShader
            fragmentShader
            mesh
            { perspective = perspective (model.dt / 1000) aspectRatio }
        ]
        )

renderOtherButton : Html Msg
renderOtherButton =
    div
    [ style "position" "fixed"
    , style "right" "10px"
    , style "top" "30px"
    ]
    [ button
    [ onClick ButtonClick ]
    [ text "Other" ]
    ]

renderTestingButton : Html Msg
renderTestingButton =
    div
    [ style "position" "fixed"
    , style "right" "10px"
    , style "top" "10px"
    ]
    [ button
      [ onClick ButtonClick ]
      [ text "Debug" ]
    ]

renderModel : Model -> Html Msg
renderModel model =
    div
    [ style "position" "fixed"
    , style "left" "10px"
    , style "top" "10px"
    , style "color" "white"
    ]
    [ text model.model ]


perspective : Float -> Float -> Mat4
perspective t aspectRatio =
    Mat4.mul
        (Mat4.makePerspective 45 aspectRatio 0.1 100)
        (Mat4.makeLookAt (vec3 (4 * cos t) 0 (4 * sin t)) (vec3 0 0 0) (vec3 0 1 0))



-- Mesh


type alias Vertex =
    { position : Vec3
    , color : Vec3
    }


mesh : Mesh Vertex
mesh =
    WebGL.indexedTriangles
        [ Vertex (vec3 0 0 0) (vec3 1 0 0)
        , Vertex (vec3 1 1 0) (vec3 0 1 0)
        , Vertex (vec3 1 -1 0) (vec3 0 0 1)
        ]
        [ (0, 1, 2)
        ]



-- Shaders


type alias Uniforms =
    { perspective : Mat4 }


vertexShader : Shader Vertex Uniforms { vcolor : Vec3 }
vertexShader =
    [glsl|
        attribute vec3 position;
        attribute vec3 color;
        uniform mat4 perspective;
        varying vec3 vcolor;
        void main () {
            gl_Position = perspective * vec4(position, 1.0);
            vcolor = color;
        }
    |]


fragmentShader : Shader {} Uniforms { vcolor : Vec3 }
fragmentShader =
    [glsl|
        precision mediump float;
        varying vec3 vcolor;
        void main () {
            gl_FragColor = vec4(vcolor, 1.0);
        }
    |]