module shader.imgui;


import semantics;
immutable Semantics[string] vertexAttributes;
static this(){
	vertexAttributes=[
		"Position": Semantics.Position,
		"UV": Semantics.TexCoord0,
		"Color": Semantics.Color
	];
}

auto vert ="#version 330
uniform mat4 ProjMtx;
layout(location = 0)in vec2 Position;
layout(location = 1)in vec2 UV;
layout(location = 2)in vec4 Color;
out vec2 Frag_UV;
out vec4 Frag_Color;
void main()
{
	Frag_UV = UV;
	Frag_Color = Color;
	gl_Position = ProjMtx * vec4(Position.xy,0,1);
}
";

auto frag ="#version 330
uniform sampler2D Texture;
in vec2 Frag_UV;
in vec4 Frag_Color;
out vec4 Out_Color;
void main()
{
	Out_Color = Frag_Color * texture( Texture, Frag_UV.st);
	//Out_Color = vec4(1, 1, 1, 1);
}
";
