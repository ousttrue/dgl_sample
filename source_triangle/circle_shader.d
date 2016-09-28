auto vert="
#version 400

layout(location=0) in vec3 VertexPosition;
layout(location=1) in vec3 VertexColor;
layout(location=2) in vec2 VertexTexCoord;

out vec3 Color;
out vec2 TexCoord;

void main()
{
	Color=VertexColor;
    TexCoord=VertexTexCoord;
    gl_Position = vec4(VertexPosition, 1.0);
}
";


auto frag="
#version 400

in vec3 Color;
in vec2 TexCoord;

layout (location = 0) out vec4 FragColor;

uniform BlobSettings {
    vec4 InnerColor;
    vec4 OuterColor;
    float RadiusInner;
    float RadiusOuter;
};

void main()
{

    float dx = TexCoord.x - 0.5;
    float dy = TexCoord.y - 0.5;
    float dist = sqrt(dx * dx + dy * dy);

	FragColor=vec4(dist, dist, dist, 1);

    FragColor = mix(InnerColor, OuterColor
            , smoothstep(RadiusInner, RadiusOuter, dist)
            );
}
";
