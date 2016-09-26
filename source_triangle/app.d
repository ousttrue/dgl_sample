import std.stdio;
import std.conv;
import std.exception;
import std.experimental.logger;
import std.string;
import std.array;
import std.typecons;
import std.algorithm;
import glfw;
import derelict.opengl3.gl3;


auto vert="
#version 400

in vec3 VertexPosition;
in vec3 VertexColor;

out vec3 Color;

void main()
{
	Color=VertexColor;
	gl_Position = vec4(VertexPosition, 1.0);
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

	struct Attrib
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
	Attrib[] Attribs;
	Attrib getAttrib(string name)
	{
		foreach(ref a; Attribs)
		{
			if(a.name==name){
				return a;
			}
		}
		throw new Exception("attrib not found");
	}

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
			Attrib attrib={
				name: name,
				location: location,
				size: size,
				type: type
			};
			Attribs~=attrib;
		}

		return true;
	}

	void use()
	{
		glUseProgram(m_program);
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

	void attribPointer(ShaderProgram.Attrib attrib, VertexBuffer buffer)
	{
		bind();
		buffer.bind();
		glVertexAttribPointer(attrib.location
			, attrib.elementCount, attrib.elementType
			, GL_FALSE, 0, null);
		buffer.unbind();
		unbind();
	}

	void draw(int count, int elementCount)
	{
		glEnable(GL_BLEND);
		glBlendEquation(GL_FUNC_ADD);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glDisable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_SCISSOR_TEST);

		bind();
		for(int i=0; i<elementCount; ++i)glEnableVertexAttribArray(i);

		glDrawArrays(GL_TRIANGLES, 0, 4);

		for(int i=0; i<elementCount; ++i)glDisableVertexAttribArray(i);
		unbind();
	}
}


void main()
{
    // window
    auto glfw=new GLFW();
    if(!glfw.createWindow(4, 1)){
        return;
    }

	auto gl=new OpenGL();

	auto vertShader=new Shader(GL_VERTEX_SHADER);
	if(!vertShader.compile(vert))
	{
		return;
	}
	auto fragShader=new Shader(GL_FRAGMENT_SHADER);
	if(!fragShader.compile(frag))
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
	positions.store([
		-0.8f, -0.8f, 0.0f,
		 0.8f, -0.8f, 0.0f,
		 0.0f,  0.8f, 0.0f,
	]);
	auto colors=new VertexBuffer();
	colors.store([
		1.0f, 0.0f, 0.0f,
		0.0f, 1.0f, 0.0f,
		0.0f, 0.0f, 1.0f,
	]);

	auto vertexArray=new VertexArray();
	vertexArray.attribPointer(program.getAttrib("VertexPosition"), positions);
	vertexArray.attribPointer(program.getAttrib("VertexColor"), colors);

	float[] clearColor=[
		0.5f, 0.4f, 0.3f, 0,
	];

	// main loop
	while (glfw.loop())
	{	
		auto size=glfw.getSize();
		glViewport(0, 0, size[0], size[1]);

		glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
		glClear(GL_COLOR_BUFFER_BIT);

		program.use();
		vertexArray.draw(3, 2);
		/*
		double current_time =  glfw.time();
		auto size=glfw.getSize();
		auto windowSize=glfw.getWindowSize();
		auto pos=glfw.getCursorPos();

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
	}
}
