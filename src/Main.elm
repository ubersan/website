module Main exposing (main)

{-
   Rotating triangle, that is a "hello world" of the WebGL
-}

import Browser
import Browser.Dom exposing (getViewport)
import Browser.Events exposing (onAnimationFrameDelta, onResize)
import Html exposing (Html)
import Html.Attributes exposing (width, height, style)
import WebGL exposing (Mesh, Shader)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Json.Decode exposing (Value)
import Task

main : Program Value Model Msg
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
    }

type Msg
    = Resize Float Float
    | Tick Float


init : (Model, Cmd Msg)
init =
    ( { 
      screenWidth = 500
    , screenHeight = 500
    , dt = 0
    }
    , Task.perform (\{viewport} -> Resize viewport.width viewport.height) getViewport
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
    [ onResize (\w h -> Resize (toFloat w) (toFloat h))
    , onAnimationFrameDelta Tick
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

view : Model -> Html msg
view model =
    WebGL.toHtmlWith
        [ WebGL.clearColor 0.3 0.3 0.3 1
        , WebGL.alpha True
        , WebGL.antialias
        , WebGL.depth 1
        ]
        [ width (round model.screenWidth)
        , height (round model.screenHeight)
        , style "position" "absolute"
        , style "top" "0"
        , style "left" "0"
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
    WebGL.triangles
        [ ( Vertex (vec3 0 0 0) (vec3 1 0 0)
          , Vertex (vec3 1 1 0) (vec3 0 1 0)
          , Vertex (vec3 1 -1 0) (vec3 0 0 1)
          )
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