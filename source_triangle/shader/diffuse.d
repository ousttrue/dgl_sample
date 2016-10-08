module shader.diffuse;


import semantics;
immutable Semantics[string] vertexAttributes;
static this(){
	vertexAttributes=[
		"aPosition": Semantics.Position,
		"aNormal": Semantics.Normal,
	];
}

auto vert="#version 330

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;

out vec3 fLightIntensity;

uniform vec4 uLightPosition;
uniform vec3 uKd;
uniform vec3 uLd;

uniform mat4 uModelViewMatrix;
uniform mat3 uNormalMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uMVP;

void main()
{
    vec3 tnorm = normalize(uNormalMatrix * aNormal);
    vec4 eyeCoords = uModelViewMatrix * vec4(aPosition, 1.0);
    vec3 s = normalize(vec3 h(LightPosition - eyeCoords));

    fLightIntensity = Ld * Kd * max(dot(s, tnorm), 0.0);

    gl_Position = MVP * vec4(aPosition, 1.0);
}
";

auto frag="#version 330

in vec3 fLightIntensity;

layout(location=0)out vec4 FragColor;

void main()
{
    FragColor = vec4(fLightIntensity, 1.0);
}
";
