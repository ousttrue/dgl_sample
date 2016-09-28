auto vert="
#version 400

layout(location=0) in vec3 VertexPosition;
layout(location=1) in vec3 VertexTexCoord;

out vec3 TexCoord;

void main()
{
    TexCoord=VertexTexCoord;
    gl_Position = vec4(VertexPosition, 1.0);
}
";


auto frag="
#version 400

in vec3 TexCoord;
layout (location = 0) out vec4 FragColor;

uniform BlobSettings {
    vec4 InnerColor;
    vec4 OuterColor;
    float RadiusInner;
    float RadiusOuter;
};

void main()
{
	FragColor=vec4(1, 1, 1, 1);
    float dx = TexCoord.x - 0.5;
    float dy = TexCoord.y - 0.5;
    float dist = sqrt(dx * dx + dy * dy);
    FragColor = mix(InnerColor, OuterColor
            , smoothstep(RadiusInner, RadiusOuter, dist)
            );
}
";

