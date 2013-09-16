#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

varying vec4 vertColor;

uniform float fogNear;
uniform float fogFar;
uniform vec4 fogColor;

void main() {

  float depth = gl_FragCoord.z / gl_FragCoord.w;
  float fogFactor = smoothstep( fogNear, fogFar, depth);
  gl_FragColor = mix(vertColor, fogColor, fogFactor);
}
