auto vert="
#version 400

layout(location=0) in vec3 VertexPosition;
layout(location=1) in vec3 VertexColor;
layout(location=2) in vec2 VertexTexCoord;

out vec3 Color;
out vec2 TexCoord;

uniform mat4 RotationMatrix;

void main()
{
	Color=VertexColor;
	TexCoord=VertexTexCoord;
	gl_Position = RotationMatrix * vec4(VertexPosition, 1.0);
}
";


auto frag="
#version 400

in vec3 Color;

out vec4 FragColor;

void main()
{
	FragColor = vec4(Color, 1.0);
}
";
