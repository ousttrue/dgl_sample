module shader.simple;


import semantics;
immutable Semantics[string] vertexAttributes;
static this(){
	vertexAttributes=[
		"aPosition": Semantics.Position,
		"aColor": Semantics.Color,
		"aTexCoord0": Semantics.TexCoord0,
	];
}

auto vert="#version 330

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aColor;
layout(location=2) in vec2 aTexCoord0;

out vec3 fColor;
out vec2 fTexCoord0;

uniform mat4 uRotationMatrix;

void main()
{
	fColor=aColor;
	fTexCoord0=aTexCoord0;
	gl_Position = uRotationMatrix * vec4(aPosition, 1.0);
}
";


auto frag="#version 330

in vec3 fColor;

layout(location=0) out vec4 out_FragColor;

void main()
{
	out_FragColor = vec4(fColor, 1.0);
}
";
