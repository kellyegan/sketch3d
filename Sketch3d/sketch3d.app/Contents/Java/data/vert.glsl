#define PROCESSING_COLOR_SHADER

uniform mat4 transform;   //transform --> gl_ModelViewProjectionMatrix

attribute vec4 vertex;    //vertex -----> gl_Vertex
attribute vec4 color;     //color ------> gl_Color

varying vec4 vertColor;

void main() {
  gl_Position = transform * vertex; // gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
  vertColor = color;
}
