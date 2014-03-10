#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

//This shader creates a depth based fog as well as highlighting a specific zDepth plane.

varying vec4 vertColor;
varying vec3 ecNormal;
varying vec3 lightDir;

uniform float zPlane;
uniform float fogNear;
uniform float fogFar;
uniform vec4 fogColor;
uniform bool zPlaneIndicatorOn;

const vec4 highlightCol = vec4(1.0, 0.0, 0.0, 1.0);

void main() {
  vec3 direction = normalize(lightDir);
  vec3 normal = normalize( ecNormal );
  float intensity = max( 0.0, dot( direction, normal) );


  float depth = 1.0 / gl_FragCoord.w;
  float hlFactor = 1.0 / (pow( zPlane - depth, 2.0) + 1.0); 
  float fogFactor = 0.9 * smoothstep( fogNear, fogFar, depth );


  vec4 lit = vec4(intensity, intensity, intensity, 1) * vertColor;
  gl_FragColor = mix( lit, vertColor, 0.6 );
  gl_FragColor = mix(gl_FragColor, fogColor, fogFactor);

  
  if( zPlaneIndicatorOn ) {
    if( abs(zPlane - depth) < 10.0 ) {
      //gl_FragColor = mix(gl_FragColor, highlightCol, hlFactor); 
      gl_FragColor = mix(gl_FragColor, highlightCol, 0.8 );
    }
  }
}

