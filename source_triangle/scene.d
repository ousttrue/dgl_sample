import gfm.math;


struct Vertex
{
	vec3!float aVertex;
	vec3!float aColor;
	vec2!float aTexCoord0;
}


static Vertex[] createTriangle(float size)
{
	return [
		Vertex(
			vec3!float(-size, -size, 0.0f),
			vec3!float(1.0f, 0.0f, 0.0f),
			vec2!float(0.0f, 0.0f),
		),
		Vertex(
			   vec3!float( size, -size, 0.0f),
			   vec3!float(0.0f, 1.0f, 0.0f),
			   vec2!float(1.0f, 0.0f),
			   ),
		Vertex(
			   vec3!float( 0.0f,  size, 0.0f),
			   vec3!float(0.0f, 0.0f, 1.0f),
			   vec2!float(0.5f, 1.0f),
			   ),
	];
}


static Vertex[] createQuadrangle(float size)
{
	return [
		Vertex(
            vec3!float(-size, -size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(0.0f, 0.0f)
			),
		Vertex(
			vec3!float( size, -size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(1.0f, 0.0f)
			),
		Vertex(
            vec3!float( size,  size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(1.0f, 1.0f)
			),

		Vertex(
            vec3!float( size,  size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(1.0f, 1.0f)
			),
		Vertex(
			vec3!float(-size,  size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(0.0f, 1.0f)
			),
		Vertex(
			vec3!float(-size, -size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(0.0f, 0.0f)
			)
	];
}


class Rotator
{
    mat4!float Matrix=mat4!float.identity;

    float m_angle=0;
    float m_angleVelocity=radians!float(180);

    void update(float delta)
    {
        m_angle+=delta * m_angleVelocity;
        Matrix=mat4!float.rotateZ(m_angle);
    }
}
