#define PROCESSING_LIGHT_SHADER

uniform mat4 modelview;
uniform mat4 transform;
uniform mat3 normalMatrix;

uniform vec4 lightPosition;
uniform vec3 lightNormal;

attribute vec4 vertex;    //vertex -----> gl_Vertex
attribute vec4 color;     //color ------> gl_Color
attribute vec3 normal;

varying vec4 vertColor;
varying vec3 ecNormal;
varying vec3 lightDir;

void main() {
  gl_Position = transform * vertex; // gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
  vec3 ecVertex = vec3(modelview * vertex);

  ecNormal = normalize( normalMatrix * normal );
  lightDir = normalize( lightPosition.xyz - ecVertex );
  vertColor = color;
}
