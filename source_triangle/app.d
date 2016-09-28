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


class ShaderProgram
{
	immutable GLuint m_program;
	Shader[] m_shaders;

	struct Variable
	{
		string name;
		int location;
		int size;
		GLenum type;

		@property int elementCount()
		{
			switch(type)
			{
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
					return GL_FLOAT;

				default:
					throw new Exception("unknown type");
			}
		}
	}
	Variable[string] Attribs;
	Variable[string] Uniforms;

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
				Variable attrib={
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
				Variable uniform={
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

	void store(float[] data)
	{
		bind();
		glBufferData(GL_ARRAY_BUFFER
			, float.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
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

	void attribPointer(ShaderProgram.Variable attrib, VertexBuffer buffer)
	{
		bind();
		buffer.bind();
		glVertexAttribPointer(attrib.location
			, attrib.elementCount, attrib.elementType
			, GL_FALSE, 0, null);
		buffer.unbind();
		unbind();
	}

	void draw(int triangles, int elementCount)
	{
		glEnable(GL_BLEND);
		glBlendEquation(GL_FUNC_ADD);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glDisable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_SCISSOR_TEST);

		bind();
		for(int i=0; i<elementCount; ++i)glEnableVertexAttribArray(i);

		glDrawArrays(GL_TRIANGLES, 0, triangles);

		for(int i=0; i<elementCount; ++i)glDisableVertexAttribArray(i);
		unbind();
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

	auto vertShader=new Shader(GL_VERTEX_SHADER);
	if(!vertShader.compile(simple_shader.vert))
	{
		return;
	}
	auto fragShader=new Shader(GL_FRAGMENT_SHADER);
	if(!fragShader.compile(simple_shader.frag))
	{
		return;
	}
	auto program=new ShaderProgram();
	program.attach(vertShader);
	program.attach(fragShader);
	if(!program.link()){
		return;
	}

	auto positions=new VertexBuffer();
	auto colors=new VertexBuffer();
	auto texcoords=new VertexBuffer();
	auto vertexArray=new VertexArray();

	positions.store([
		-0.8f, -0.8f, 0.0f,
		 0.8f, -0.8f, 0.0f,
		 0.0f,  0.8f, 0.0f,
	]);
	colors.store([
		1.0f, 0.0f, 0.0f,
		0.0f, 1.0f, 0.0f,
		0.0f, 0.0f, 1.0f,
	]);
	vertexArray.attribPointer(program.Attribs["VertexPosition"], positions);
	vertexArray.attribPointer(program.Attribs["VertexColor"], colors);

	/*
	positions.store([
		-1.0f, -1.0f, 0.0f,
		 1.0f, -1.0f, 0.0f,
		 1.0f,  1.0f, 0.0f,

		 1.0f,  1.0f, 0.0f,
		-1.0f,  1.0f, 0.0f,
		-1.0f, -1.0f, 0.0f,
	]);
	texcoords.store([
		0.0f, 0.0f,
		1.0f, 0.0f,
		1.0f,  1.0f,

		1.0f,  1.0f,
		0.0f,  1.0f,
		0.0f, 0.0f,
	]);
	vertexArray.attribPointer(program.Attribs["VertexPosition"], positions);
	vertexArray.attribPointer(program.Attribs["VertexTexCoord"], texcoords);
	*/

	float[] clearColor=[
		0.5f, 0.4f, 0.3f, 0,
	];

	// main loop
	auto last_time=MonoTime.currTime;

	float angle=0;
	auto rotSpeed=radians!float(180);
	while (glfw.loop())
	{	
		// update
		auto current_time =  MonoTime.currTime;
		auto size=glfw.getSize();
		auto windowSize=glfw.getWindowSize();
		auto pos=glfw.getCursorPos();
		glViewport(0, 0, size[0], size[1]);

		auto delta=(current_time-last_time).total!"msecs" * 0.001;
		last_time=current_time;

		angle+=delta * rotSpeed;

		auto m=mat4!float.rotateZ(angle);
		writeln(m);
		program.setUniform("RotationMatrix", m);

		// clear
		glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
		glClear(GL_COLOR_BUFFER_BIT);

		// draw
		program.use();
		vertexArray.draw(3, 2);
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
