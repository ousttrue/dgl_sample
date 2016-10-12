import gfm.math;
import std.typecons;
import core.stdc.string;
import std.traits;
import semantics;
import std.exception;


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

	@property auto vertexCount()
	{
		return vertices.length;
	}

	@property auto bytesLength()
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


class Builder(T)
{
	alias Vertex=T;

	Vertex[] Vertices;
	ushort[] Indices;

	void pushTriangle(ushort[3] i)
	{
		Indices~=[i[0], i[1], i[2]];
	}

	void pushQuadrangle(ushort[4] i)
	{
		pushTriangle([i[0], i[1], i[2]]);
		pushTriangle([i[2], i[3], i[0]]);
	}

	void pushQuadrangles(ushort[] quads)
	{
		enforce(quads.length % 4 == 0);
		for(int i=0; i<quads.length; i+=4)
		{
			pushQuadrangle([quads[i], quads[i+1], quads[i+2], quads[i+3]]);
		}
	}
}
