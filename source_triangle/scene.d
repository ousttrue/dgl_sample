import gfm.math;
import std.typecons;
import core.stdc.string;
import std.traits;


class Vertices(T...)
{
	alias Vertex=Tuple!(T);
	Vertex[] vertices;

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

	@property int offsetof(string attribute)()
	{
		return mixin("Vertex."~attribute~".offsetof");
	}

	this()
	{
	}

	this(int length)
	{
		vertices.length=length;
	}

	void set(V...)(int index, V args)
	{
		vertices[index]=tuple(args);
	}

	void push(V...)(V args)
	{
		vertices~=tuple(args);
	}
}


static auto createTriangle(float size)
{
	auto vs=new Vertices!(
						  vec3!float, "aPosition"
						  , vec3!float, "aColor"
						  , vec2!float, "aTexCoord0"
						  )(3);
	vs.set(0,
		   vec3!float(-size, -size, 0.0f),
		   vec3!float(1.0f, 0.0f, 0.0f),
		   vec2!float(0.0f, 0.0f),
		   );
	vs.set(1,
			vec3!float( size, -size, 0.0f),
			vec3!float(0.0f, 1.0f, 0.0f),
			vec2!float(1.0f, 0.0f),
			);
	vs.set(2,
			vec3!float( 0.0f,  size, 0.0f),
			vec3!float(0.0f, 0.0f, 1.0f),
			vec2!float(0.5f, 1.0f),
			);
	return vs;
}


static auto createQuadrangle(float size)
{
	auto vs=new Vertices!(
		vec3!float, "aPosition"
		, vec3!float, "aColor"
		, vec2!float, "aTexCoord0"
		)(6);
	vs.set(0, 
            vec3!float(-size, -size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(0.0f, 0.0f)
			);
	vs.set(1,
			vec3!float( size, -size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(1.0f, 0.0f)
			);
	vs.set(2,
            vec3!float( size,  size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(1.0f, 1.0f)
			);

	vs.set(3,
            vec3!float( size,  size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(1.0f, 1.0f)
			);
	vs.set(4,
			vec3!float(-size,  size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(0.0f, 1.0f)
			);
	vs.set(5,
			vec3!float(-size, -size, 0.0f),
            vec3!float(1.0f, 1.0f, 1.0f),
            vec2!float(0.0f, 0.0f)
			);
	return vs;
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
