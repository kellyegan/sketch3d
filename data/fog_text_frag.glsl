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

void main() {
//  gl_FragColor = vertColor; 
  float depth = gl_FragCoord.z / gl_FragCoord.w;
  float fogFactor = smoothstep( fogNear, fogFar, depth);

  vec4 afterTexCol = texture2D(sprite, texCoord) * vertColor;
  gl_FragColor = vec4(afterTexCol.rgb, (1.0 - fogFactor) * afterTexCol.a);
//  gl_FragColor =   texture2D(sprite, texCoord) * vertColor;
//  gl_FragColor = mix(afterTexCol, fogColor, fogFactor);
}
