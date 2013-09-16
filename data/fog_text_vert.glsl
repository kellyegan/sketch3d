#define PROCESSING_LINE_SHADER

uniform mat4 projection;     // Added from sprite
uniform mat4 modelview;      // Added from sprite
uniform float weight;        // Added from sprite

uniform vec4 viewport;       // dimensions of viewing rectangle (x,y, width, height)

uniform mat4 transform;
uniform mat4 texMatrix;

attribute vec4 inVertex;     //xyzw coordinates of the incoming line vertex
attribute vec4 inColor;      //rgba color of the incoming line vertex
attribute vec4 inLine;       //the xyz coordinates store the vertex opposite to the 
                             //current (incoming) along the direction of the 
                             //line segment, while w stores the displacement along 
                             //the normal to the line segment (lines are rendered 
                             //as a sequence of rectangular segments that are always screen facing)

attribute vec4 vertex;
attribute vec4 color;
attribute vec4 direction;
attribute vec2 offset;       // Added from sprite

varying vec4 vertColor;
varying vec2 texCoord;       // Added from sprite

vec3 clipToWindow(vec4 clip, vec4 viewport) {
  vec3 dclip = clip.xyz / clip.w;
  vec2 xypos = (dclip.xy + vec2(1.0, 1.0)) * 0.5 * viewport.zw;
  return vec3(xypos, dclip.z * 0.5 + 0.5);
}

void main() {
  vec4 clip0 = transform * vertex;
  vec4 clip1 = clip0 + transform * vec4(direction.xyz, 0);
  float thickness = direction.w;
  
  vec3 win0 = clipToWindow(clip0, viewport); 
  vec3 win1 = clipToWindow(clip1, viewport); 
  vec2 tangent = win1.xy - win0.xy;
    
  vec2 normal = normalize(vec2(-tangent.y, tangent.x));
  vec2 offset = normal * thickness;
  gl_Position.xy = clip0.xy + offset.xy;
  gl_Position.zw = clip0.zw;

//  vec4 pos = modelview * vertex;
//  vec4 clip = projection * pos;
//  
//  gl_Position = clip + projection * vec4(offset, 0, 0);
  
  texCoord = (vec2(0.5) + offset / weight);
  
  vertColor = color;

}





