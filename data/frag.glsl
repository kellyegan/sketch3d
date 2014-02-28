#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_COLOR_SHADER


//This shader creates a depth based fog as well as highlighting a specific zDepth plane.

varying vec4 vertColor;

uniform float zPlane;
uniform float fogNear;
uniform float fogFar;
uniform vec4 fogColor;

const vec4 highlightCol = vec4(1.0, 0.0, 0.0, 1.0);

void main() {
  float depth = 1.0 / gl_FragCoord.w;
  float hlFactor = 1.0 / (pow( zPlane - depth, 2.0) + 1.0); 
  float fogFactor = smoothstep( fogNear, fogFar, depth );
  gl_FragColor = mix(vertColor, fogColor, fogFactor);

  
    gl_FragColor = mix(gl_FragColor, highlightCol, hlFactor); 
    gl_FragColor = gl_FragColor;
}


