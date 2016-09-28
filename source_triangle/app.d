import std.stdio;
import std.conv;
import std.exception;
import std.experimental.logger;
import std.string;
import std.array;
import std.typecons;
import std.algorithm;
import std.datetime;
import core.stdc.string;
import glfw;
import derelict.opengl3.gl3;
import gfm.math;
import core.thread;
static import simple_shader;
static import circle_shader;


int byteslen(T)(T[] array)
{
	return T.sizeof * array.length;
}

class OpenGL
{
	string m_renderer;
	string m_vendor;
	string m_version;
	string m_shaderVersion;
	GLint m_versionMajor;
	GLint m_versionMinor;

	string[] m_extensions;

	static this()
	{
		DerelictGL3.load();
	}

	this()
	{
		DerelictGL3.reload();

		m_renderer=glGetString(GL_RENDERER).to!string;
		m_vendor=glGetString(GL_VENDOR).to!string;
		m_version=glGetString(GL_VERSION).to!string;
		m_shaderVersion=glGetString(GL_SHADING_LANGUAGE_VERSION).to!string;
		glGetIntegerv(GL_MAJOR_VERSION, &m_versionMajor);
		glGetIntegerv(GL_MINOR_VERSION, &m_versionMinor);

		int extensions;
		glGetIntegerv(GL_NUM_EXTENSIONS, &extensions);
		m_extensions.length=extensions;
		for(int i=0; i<extensions; ++i){
			m_extensions[i]=glGetStringi(GL_EXTENSIONS, i).to!string;
		}
	}
}


class Shader
{
	immutable GLuint m_vertexShader;

	this(GLenum shaderType)
	{
		m_vertexShader=glCreateShader(shaderType);
		enforce(m_vertexShader!=0, "fail to glCreateShader");
	}

	~this()
	{
		glDeleteShader(m_vertexShader);
	}

	GLuint get()const{ return m_vertexShader; }

	bool compile(string src)
	{
		glShaderSource(m_vertexShader, 1, [src.ptr].ptr, [cast(int)src.length].ptr);
		glCompileShader(m_vertexShader);
		GLint result;
		glGetShaderiv(m_vertexShader, GL_COMPILE_STATUS, &result);
		if(result==GL_FALSE){
			GLint len;
			glGetShaderiv(m_vertexShader, GL_INFO_LOG_LENGTH, &len);
			if(len>0){
				char[] buf;
				buf.length=len;
				GLsizei written;
				glGetShaderInfoLog(m_vertexShader, len, &written, buf.ptr);

				error(buf.to!string);
			}
			return false;
		}
		return true;
	}
}


struct ShaderVariable
{
	string name;
	int location;
	int size;
	GLenum type;

	@property int elementCount()
	{
		switch(type)
		{
			case GL_FLOAT_VEC2:
				return 2;

			case GL_FLOAT_VEC3:
				return 3;

			default:
				throw new Exception("unknown type");
		}
	}

	@property GLenum elementType()
	{
		switch(type)
		{
			case GL_FLOAT_VEC3:
			case GL_FLOAT_VEC2:
				return GL_FLOAT;

			default:
				throw new Exception("unknown type");
		}
	}
}


class ShaderProgram
{
	immutable GLuint m_program;
	Shader[] m_shaders;

	ShaderVariable[string] Attribs;
	ShaderVariable[string] Uniforms;

	struct BlockVar
	{
	}
	struct Block
	{
		string name;
		byte[] buffer;
	}
	Block[string] Blocks;

	this()
	{
		m_program=glCreateProgram();
		enforce(m_program!=0, "fail to glCreateProgram");
	}

	~this()
	{
		glDeleteProgram(m_program);
	}

	void attach(Shader shader)
	{
		glAttachShader(m_program, shader.get());
		m_shaders~=shader;
	}

	bool link()
	{
		glLinkProgram(m_program);

		GLint status;
		glGetProgramiv(m_program, GL_LINK_STATUS, &status);
		if(status==GL_FALSE){
			GLint len;
			glGetProgramiv(m_program, GL_INFO_LOG_LENGTH, &len);
			if(len>0){
				char[] buf;
				buf.length=len;
				GLsizei written;
				glGetProgramInfoLog(m_program, len, &written, buf.ptr);
				error(buf.to!string);
			}
			return false;
		}

		// retreive attributes
		{
			GLint maxLength;
			GLint nAttribs;

			glGetProgramiv(m_program
						   , GL_ACTIVE_ATTRIBUTES, &nAttribs);
			glGetProgramiv(m_program
						   , GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxLength);
			auto buf=new char[maxLength];
			for(int i=0; i<nAttribs; i++)
			{
				GLint written;
				GLint size;
				GLenum type;
				glGetActiveAttrib(m_program, i, maxLength, &written
								  , &size, &type, buf.ptr);
				auto name=buf[0..written].to!string;
				auto location=glGetAttribLocation(m_program, name.toStringz);
				ShaderVariable attrib={
					name: name,
					location: location,
					size: size,
					type: type
				};
				Attribs[name]=attrib;
			}
		}

		{
			GLint nUniforms;
			GLint maxLength;
			glGetProgramiv(m_program
						   , GL_ACTIVE_UNIFORMS, &nUniforms);
			glGetProgramiv(m_program
						   , GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxLength);
			auto buf=new char[maxLength];
			for(int i=0; i<nUniforms; ++i)
			{
				GLint written;
				GLint size;
				GLenum type;
				glGetActiveUniform(m_program, i, maxLength, &written
								   , &size, &type, buf.ptr);
				auto name=buf[0..written].to!string;
				auto location = glGetUniformLocation(m_program, name.toStringz);
				ShaderVariable uniform={
					name: name,
					location: location,
					size: size,
					type: type
				};
				Uniforms[name]=uniform;
			}
			/*
			{
				auto name="BlobSettings";
				GLuint blockIndex=glGetUniformBlockIndex(m_program, name.toStringz);
				GLint blockSize;
				glGetActiveUniformBlockiv(m_program, blockIndex
					, GL_UNIFORM_BLOCK_DATA_SIZE, &blockSize);
				Block block={
					name: name,
					buffer: new byte[blockSize],
				};

				auto names=[
					"InnerColor", "OuterColor", "RadiusInner", "RadiusOuter",
				];

				GLuint[4] indices;
				glGetUniformIndices(m_program
					, indices.length, names.map!(a => a.toStringz).array.ptr, indices.ptr);

				GLint[4] offset;
				glGetActiveUniformsiv(m_program
					, offset.length, indices.ptr, GL_UNIFORM_OFFSET, offset.ptr);


				auto outerColor=[0.0f, 0.0f, 0.0f, 0.0f];
				auto innerColor=[1.0f, 1.0f, 0.75f, 1.0f];
				auto innerRadius = 0.25f;
				auto outerRadius = 0.45f;

				memcpy(buf.ptr + offset[0], innerColor.ptr, float.sizeof * innerColor.length);
				memcpy(buf.ptr + offset[1], outerColor.ptr, float.sizeof * outerColor.length);
				memcpy(buf.ptr + offset[2], &innerRadius, float.sizeof);
				memcpy(buf.ptr + offset[3], &outerRadius, float.sizeof);

				Blocks[name]=block;

				glGenBuffers(1, &m_ubo);
				glBindBuffer(GL_UNIFORM_BUFFER, m_ubo);
				glBufferData(GL_UNIFORM_BUFFER, blockSize, block.buffer.ptr, GL_DYNAMIC_DRAW);

				glBindBufferBase(GL_UNIFORM_BUFFER, blockIndex, m_ubo);
			}
			*/
		}

		auto m=mat4!float.identity;
		setUniform("RotationMatrix", m);

		return true;
	}
	GLuint m_ubo;

	void use()
	{
		glUseProgram(m_program);
	}

	GLuint getUniformLocation(string name)
	{
		return glGetUniformLocation(m_program, name.toStringz);
	}

	void setUniform(string name, const ref mat4!float value)
	{
		glUniformMatrix4fv(getUniformLocation(name), 1, GL_FALSE, 
						   value.ptr);
	}
}


class VertexBuffer
{
	GLuint m_vbo;

	GLuint get()const{ return m_vbo; }

	@property GLuint elementCount()const{ return 3; }

	@property GLenum elementType()const{ return GL_FLOAT; }

	this()
	{
		glGenBuffers(1, &m_vbo);
		enforce(m_vbo!=0, "");
	}

	~this()
	{
		glDeleteBuffers(1, &m_vbo);
	}

	void bind()
	{
		glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
	}

	void store(void* data, int len)
	{
		bind();
		glBufferData(GL_ARRAY_BUFFER
			, len, data, GL_STATIC_DRAW);
		unbind();
	}

	void unbind()
	{
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
}


class VertexArray
{
	GLuint m_vao;
	VertexBuffer[] m_buffers;

	this()
	{
		glGenVertexArrays(1, &m_vao);
		enforce(m_vao!=0, "fail to glGenVertexArrays");
	}

	~this()
	{
		glDeleteVertexArrays(1, &m_vao);
	}

	void bind()
	{
		glBindVertexArray(m_vao);
	}

	void unbind()
	{
		glBindVertexArray(0);
	}

	void attribPointer(ShaderVariable attrib, VertexBuffer buffer)
	{
		bind();
		buffer.bind();
		glVertexAttribPointer(attrib.location
			, attrib.elementCount, attrib.elementType
			, GL_FALSE, 0, null);
		buffer.unbind();
		unbind();

		m_buffers~=buffer;
	}

	void draw()
	{
		glEnable(GL_BLEND);
		glBlendEquation(GL_FUNC_ADD);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glDisable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_SCISSOR_TEST);

		bind();
		for(int i=0; i<m_buffers.length; ++i)glEnableVertexAttribArray(i);

		glDrawArrays(GL_TRIANGLES, 0, 3);

		for(int i=0; i<m_buffers.length; ++i)glDisableVertexAttribArray(i);
		unbind();
	}
}


class RenderPass
{
	ShaderProgram m_program;
	vec4!float m_clearColor;
	vec2!int m_frameSize;

	bool createShader(string vert, string frag)
	{
		auto vertShader=new Shader(GL_VERTEX_SHADER);
		if(!vertShader.compile(simple_shader.vert))
		{
			return false;
		}
		auto fragShader=new Shader(GL_FRAGMENT_SHADER);
		if(!fragShader.compile(simple_shader.frag))
		{
			return false;
		}

		m_program=new ShaderProgram();
		m_program.attach(vertShader);
		m_program.attach(fragShader);
		if(!m_program.link()){
			return false;
		}

		return true;
	}

	void setClearColor(float r, float g, float b, float a)
	{
		m_clearColor.x=r;
		m_clearColor.y=g;
		m_clearColor.z=b;
		m_clearColor.w=a;
	}

	void setFrameSize(int w, int h)
	{
		m_frameSize.x=w;
		m_frameSize.y=h;
	}

	void draw(VertexArray vertexArray)
	{
		glViewport(0, 0, m_frameSize.x, m_frameSize.y);

		// clear
		glClearColor(m_clearColor.x, m_clearColor.y, m_clearColor.z, m_clearColor.w);
		glClear(GL_COLOR_BUFFER_BIT);

		m_program.use();
		vertexArray.draw();
	}

	VertexArray mesh2vertexArray(Mesh mesh)
	{
		auto vertexArray=new VertexArray();

		auto positions=new VertexBuffer();
		positions.store(mesh.positions.ptr, mesh.positions.byteslen);
		vertexArray.attribPointer(m_program.Attribs["VertexPosition"], positions);

		auto colors=new VertexBuffer();
		colors.store(mesh.colors.ptr, mesh.colors.byteslen);
		vertexArray.attribPointer(m_program.Attribs["VertexColor"], colors);

		auto texcoords=new VertexBuffer();
		texcoords.store(mesh.texcoords.ptr, mesh.texcoords.byteslen);
		vertexArray.attribPointer(m_program.Attribs["VertexTexCoord"], texcoords);

		return vertexArray;	
	}
}


class Mesh
{
	vec3!float[] positions;
	vec3!float[] colors;
	vec2!float[] texcoords;

	static Mesh createTriangle(float size)
	{
		auto mesh=new Mesh();
		mesh.positions=[
			vec3!float(-size, -size, 0.0f),
			vec3!float( size, -size, 0.0f),
			vec3!float( 0.0f,  size, 0.0f),
		];
		mesh.colors=[
			vec3!float(1.0f, 0.0f, 0.0f),
			vec3!float(0.0f, 1.0f, 0.0f),
			vec3!float(0.0f, 0.0f, 1.0f),
		];
		mesh.texcoords=[
			vec2!float(0.0f, 0.0f),
			vec2!float(1.0f, 0.0f),
			vec2!float(0.5f, 1.0f),
		];
		return mesh;
	}
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


void main()
{
    // window
    auto glfw=new GLFW();
    if(!glfw.createWindow(4, 5)){
        return;
    }

	auto gl=new OpenGL();

	auto renderPass=new RenderPass();
	if(!renderPass.createShader(simple_shader.vert, simple_shader.frag))
	{
		return;
	}
	renderPass.setClearColor(0.5f, 0.4f, 0.3f, 0);

	auto triangle=Mesh.createTriangle(0.8f);
	auto vertexArray=renderPass.mesh2vertexArray(triangle);

	// main loop
	auto last_time=MonoTime.currTime;
	auto rotator=new Rotator();
	while (glfw.loop())
	{	
		// update
		auto current_time =  MonoTime.currTime;
		auto size=glfw.getSize();
		auto windowSize=glfw.getWindowSize();
		auto pos=glfw.getCursorPos();
		auto delta=(current_time-last_time).total!"msecs" * 0.001;
		last_time=current_time;
		rotator.update(delta);
		renderPass.setFrameSize(size[0], size[1]);
		renderPass.m_program.setUniform("RotationMatrix", rotator.Matrix);

		// draw
		renderPass.draw(vertexArray);

		/*
		// rendering 3D scene
		renderer.clearRenderTarget(context.clear_color);
		renderer.setViewport(size[0], size[1]);

		// gui
		io.updateGui(context
					 , current_time, size, windowSize
					 , pos, glfw.mouseDown(0), glfw.mouseDown(1), glfw.mouseDown(2)
					 , glfw.hasFocus());
		glfw.setMouseCursor(io.MouseDrawCursor
							);
		igGetDrawData();
		io.RenderDrawLists(renderer);
		*/

		// present
		glfw.flush();

		Thread.sleep( dur!("msecs")( 16 ) );
	}
}
