import gfm.math;
import std.typecons;
import core.stdc.string;
import std.traits;
import semantics;


struct Vertex
{
	vec3!float Position;
	vec3!float Color;
	vec2!float TexCoord0;
};


class Vertices
{
	Vertex[] vertices;
	bool m_useIndices;
	ushort[] indices;

	@property static int vertexSize()
	{
		return Vertex.sizeof;
	}

	@property int vertexCount()
	{
		return vertices.length;
	}

	@property int bytesLength()
	{
		return Vertex.sizeof * vertices.length;
	}

	@property void* ptr()
	{
		return vertices.ptr;
	}

	this(bool useIndices=false)
	{
		m_useIndices=useIndices;
	}

	this(int length)
	{
		vertices.length=length;
	}

	void set(int index, Vertex v)
	{
		vertices[index]=v;
	}

	void push(Vertex v)
	{
		vertices~=v;
	}

	void store(Vertex[] vertices)
	{
		foreach(v; vertices)
		{
			push(v);
		}
	}
}

static Vertex[] createTriangle(float size)
{
	return [
		Vertex(
		   vec3!float(-size, -size, 0.0f),
		   vec3!float(1.0f, 0.0f, 0.0f),
		   vec2!float(0.0f, 0.0f)
		   ),
		Vertex(
			vec3!float( size, -size, 0.0f),
			vec3!float(0.0f, 1.0f, 0.0f),
			vec2!float(1.0f, 0.0f)
			),
		Vertex(
			vec3!float( 0.0f,  size, 0.0f),
			vec3!float(0.0f, 0.0f, 1.0f),
			vec2!float(0.5f, 1.0f),
			)
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
