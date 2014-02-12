#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

//This shader creates a depth based fog as well as highlighting a specific zDepth plane.

varying vec4 vertColor;

uniform float zPlane;

uniform float fogFar;
uniform vec4 fogColor;
uniform bool zPlaneIndicatorOn;

const vec4 highlightCol = vec4(1.0, 0.0, 0.0, 1.0);

void main() {
  if( zPlaneIndicatorOn ) {
    float depth = 1.0 / gl_FragCoord.w;
  
    float hlFactor = 0.8 / (pow( zPlane - depth, 3.0) + 1.0); 
  
    if( depth > zPlane ) {
      float fogFactor = 0.2 * smoothstep( zPlane, fogFar, depth ) + 0.3;
      gl_FragColor = mix(vertColor, fogColor, fogFactor);
    } else {
      gl_FragColor = vertColor;
    }
  
    gl_FragColor = mix(gl_FragColor, highlightCol, hlFactor); 
  } else {
    gl_FragColor = vertColor;
  }
}
