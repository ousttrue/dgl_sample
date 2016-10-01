module shader.circle;

import std.typecons;
import gfm.math;
alias Vertex=Tuple!(
vec3!float, "aPosition"
, vec3!float, "aColor"
, vec2!float, "aTexCoord0"
);

auto vert="#version 400

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aColor;
layout(location=2) in vec2 aTexCoord0;

out vec3 fColor;
out vec2 fTexCoord;

void main()
{
	fColor=aColor;
    fTexCoord=aTexCoord0;
    gl_Position = vec4(aPosition, 1.0);
}
";

auto frag="#version 400

in vec3 fColor;
in vec2 fTexCoord;

layout (location = 0) out vec4 out_Color;

uniform BlobSettings {
    vec4 uInnerColor;
    vec4 uOuterColor;
    float uRadiusInner;
    float uRadiusOuter;
};

void main()
{

    float dx = fTexCoord.x - 0.5;
    float dy = fTexCoord.y - 0.5;
    float dist = sqrt(dx * dx + dy * dy);

	//out_Color=vec4(dist, dist, dist, 1);
    out_Color = mix(uInnerColor, uOuterColor
            , smoothstep(uRadiusInner, uRadiusOuter, dist)
            );
}
";
