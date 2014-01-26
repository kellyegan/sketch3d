#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D sprite;

varying vec4 vertColor;
varying vec2 texCoord;

uniform float fogNear;
uniform float fogFar;
uniform vec4 fogColor;
uniform float zPlane;


const vec4 highlightCol = vec4( 0.8, 0.0, 0.0, 1.0);

//Creates a slightly fuzzy highlight
vec4 calcHighlight( float depth, float hldepth, vec4 color, vec4 highlight ) {
  float hlWidth = 10.0;
  float factor = smoothstep( hldepth - (hlWidth / 2.0), zPlane, depth);
  factor = factor - smoothstep( hldepth, zPlane + (hlWidth / 2.0), depth);

  return mix(color, highlight, factor);
}

void main() {
  float eyeDepth = 1.0 / gl_FragCoord.w;

  float fogRange = 500.0;

  float fogFactor = smoothstep( fogNear, fogFar, eyeDepth);

  vec4 beforeTexCol = vec4(0.0);
  if( eyeDepth > zPlane) { 
    beforeTexCol = mix( vertColor, fogColor, clamp(fogFactor, 0.5, 1.0) );
  } else {
    beforeTexCol = vertColor;
  }
  beforeTexCol = calcHighlight( eyeDepth, zPlane, beforeTexCol, highlightCol);

  gl_FragColor = texture2D(sprite, texCoord) * beforeTexCol;
}
