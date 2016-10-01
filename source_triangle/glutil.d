import derelict.opengl3.gl3;
import gfm.math;
import scene;
import std.conv;
import std.exception;
import std.experimental.logger;
import std.algorithm;
import std.array;
import std.string;
import core.stdc.string;
import irenderer;


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

            case GL_FLOAT_VEC4:
                return 4;

            default:
                throw new Exception("unknown type");
        }
    }

    @property GLenum elementType()
    {
        switch(type)
        {
            case GL_FLOAT_VEC4:
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
    //Block[string] Blocks;

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
		}

        {
            auto name="BlobSettings";
            m_blockIndex=glGetUniformBlockIndex(m_program
					, name.toStringz);
            GLint blockSize;
            glGetActiveUniformBlockiv(m_program, m_blockIndex
                    , GL_UNIFORM_BLOCK_DATA_SIZE, &blockSize);
			if(blockSize){
				Block block={
                name: name,
                buffer: new byte[blockSize],
				};

				auto names=[
					"uInnerColor", "uOuterColor", "uRadiusInner", "uRadiusOuter",
				];

				GLuint[4] indices;
				glGetUniformIndices(m_program
									, indices.length
									, names.map!(a => a.toStringz).array.ptr, indices.ptr);

				GLint[4] offset;
				glGetActiveUniformsiv(m_program
									  , offset.length, indices.ptr, GL_UNIFORM_OFFSET, offset.ptr);

				auto outerColor=[0.0f, 0.0f, 0.0f, 0.0f];
				auto innerColor=[1.0f, 1.0f, 0.75f, 1.0f];
				auto innerRadius = 0.25f;
				auto outerRadius = 0.45f;

				memcpy(block.buffer.ptr + offset[0]
					   , innerColor.ptr, innerColor.byteslen);
				memcpy(block.buffer.ptr + offset[1]
					   , outerColor.ptr, outerColor.byteslen);
				memcpy(block.buffer.ptr + offset[2]
					   , &innerRadius, float.sizeof);
				memcpy(block.buffer.ptr + offset[3]
					   , &outerRadius, float.sizeof);

				//Blocks[name]=block;

				glGenBuffers(1, &m_ubo);
				glBindBuffer(GL_UNIFORM_BUFFER, m_ubo);
				glBufferData(GL_UNIFORM_BUFFER
							 , block.buffer.byteslen, block.buffer.ptr, GL_DYNAMIC_DRAW);
			}
        }

        auto m=mat4!float.identity;
        setUniform("RotationMatrix", m);

        return true;
    }
    GLuint m_ubo;
	int m_blockIndex;

    void use()
    {
        glUseProgram(m_program);
		glBindBufferBase(GL_UNIFORM_BUFFER, m_blockIndex, m_ubo);
    }

    GLuint getUniformLocation(string name)
    {
        return glGetUniformLocation(m_program, name.toStringz);
    }

    void setUniform(string name, const mat4!float value)
    {
		use();
        glUniformMatrix4fv(getUniformLocation(name), 1, GL_FALSE, 
                value.ptr);
    }

    void setUniform(string name, const float[4][4] value)
    {
        glUniformMatrix4fv(getUniformLocation(name), 1, GL_FALSE, 
						   &value[0][0]);

    }
}


class VertexBuffer
{
    GLuint m_vbo;

    GLuint get()const{ return m_vbo; }

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

    void unbind()
    {
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    void store(void* data, int len)
    {
        bind();
        glBufferData(GL_ARRAY_BUFFER
					 , len, data, GL_STATIC_DRAW);
        unbind();
    }
}


class IndexBuffer
{
    GLuint m_ibo;

    GLuint get()const{ return m_ibo; }

	this()
	{
        glGenBuffers(1, &m_ibo);
        enforce(m_ibo!=0, "");
	}

	~this()
	{
        glDeleteBuffers(1, &m_ibo);
	}

	void bind()
	{
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ibo);
	}

	void unbind()
	{
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	}

    void store(void* data, int len)
    {
        bind();
        glBufferData(GL_ELEMENT_ARRAY_BUFFER
					 , len, data, GL_STATIC_DRAW);
        unbind();
    }
}


class VertexArray
{
    GLuint m_vao;
    VertexBuffer[] m_buffers;

	IndexBuffer m_indices;

    this(IndexBuffer indices=null)
    {
        glGenVertexArrays(1, &m_vao);
        enforce(m_vao!=0, "fail to glGenVertexArrays");
        m_indices=indices;
    }

    ~this()
    {
        glDeleteVertexArrays(1, &m_vao);
    }

    void bind()
    {
        glBindVertexArray(m_vao);
		foreach(b; m_buffers)
		{
			b.bind();
		}
		if(m_indices)m_indices.bind();
    }

    void unbind()
    {
		if(m_indices)m_indices.unbind();
		foreach(b; m_buffers)
		{
			b.unbind();
		}
        glBindVertexArray(0);
    }

    void attribPointer(T, alias name)(ShaderProgram program, VertexBuffer buffer)
	{
		attribPointer(program.Attribs[name], buffer, T.sizeof, mixin("T."~name~".offsetof"));
	}

    void attribPointer(ShaderVariable attrib, VertexBuffer buffer, int stride, int offset=0)
    {
        bind();
        buffer.bind();
        glVertexAttribPointer(attrib.location
                , attrib.elementCount, attrib.elementType
                , GL_FALSE, stride, cast(void*)offset);
        buffer.unbind();
        unbind();

        m_buffers~=buffer;
    }

    void draw(int count, ushort* offset)
    {
		/*
        glEnable(GL_BLEND);
        glBlendEquation(GL_FUNC_ADD);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDisable(GL_CULL_FACE);
        glDisable(GL_DEPTH_TEST);
        glDisable(GL_SCISSOR_TEST);
		*/

        for(int i=0; i<m_buffers.length; ++i)glEnableVertexAttribArray(i);

		if(m_indices){
			glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_SHORT
						   , offset);
		}
		else{
			bind();
			glDrawArrays(GL_TRIANGLES, cast(int)offset, count);
			unbind();
		}

        for(int i=0; i<m_buffers.length; ++i)glDisableVertexAttribArray(i);
    }
}


class Texture
{
    GLuint m_texture;
	GLuint get()
	{
		return m_texture;
	}

    this()
    {
        glGenTextures(1, &m_texture);
    }

    ~this()
    {
        glDeleteTextures(1, &m_texture);
    }

    void bind()
    {
        glBindTexture(GL_TEXTURE_2D, m_texture);
    }

    void unbind()
    {
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    void loadImageRGBA(ubyte *pixels, int width, int height)
    {
        bind();
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height
					 , 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
        unbind();
    }
}


class RenderPass: IRenderer
{
    ShaderProgram m_program;
    vec4!float m_clearColor;
    vec2!int m_frameSize;
	VertexArray m_mesh;
	Texture m_texture;

	bool createShader(alias m)()
	{
		return createShader(m.vert, m.frag);
	}

    bool createShader(string vert, string frag)
    {
        auto vertShader=new Shader(GL_VERTEX_SHADER);
        if(!vertShader.compile(vert))
        {
            return false;
        }
        auto fragShader=new Shader(GL_FRAGMENT_SHADER);
        if(!fragShader.compile(frag))
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

	void clear()
	{
        glViewport(0, 0, m_frameSize.x, m_frameSize.y);

        // clear
        glClearColor(m_clearColor.x, m_clearColor.y, m_clearColor.z, m_clearColor.w);
        glClear(GL_COLOR_BUFFER_BIT);
	}

    void mesh2vertexArray(T...)(Vertices!T mesh, ushort[] indices=[])
    {
        m_mesh=new VertexArray;

        auto buffer=new VertexBuffer();
		if(mesh.bytesLength>0){
			buffer.store(mesh.ptr, mesh.bytesLength);
		}

		foreach(a; mesh.Vertex.fieldNames)
		{
			m_mesh.attribPointer(m_program.Attribs[a]
				, buffer, mesh.vertexSize, mesh.offsetof!a);
		}

		if(mesh.m_useIndices || indices.length>0)
		{
			m_mesh.m_indices=new IndexBuffer();
			m_mesh.m_indices.store(indices.ptr, indices.byteslen);
		}
    }

	GLint m_last_program;
	GLint m_last_texture;
	nothrow void begin(float width, float height)
	{
		try{
		// Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled
		glGetIntegerv(GL_CURRENT_PROGRAM, &m_last_program);
		glGetIntegerv(GL_TEXTURE_BINDING_2D, &m_last_texture);
		glEnable(GL_BLEND);
		glBlendEquation(GL_FUNC_ADD);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glDisable(GL_CULL_FACE);
		glDisable(GL_DEPTH_TEST);
		glEnable(GL_SCISSOR_TEST);
		glActiveTexture(GL_TEXTURE0);

		const float[4][4] ortho_projection =
		[
			[ 2.0f/width,	0.0f,			0.0f,		0.0f ],
			[ 0.0f,			2.0f/-height,	0.0f,		0.0f ],
			[ 0.0f,			0.0f,			-1.0f,		0.0f ],
			[ -1.0f,		1.0f,			0.0f,		1.0f ],
		];

		m_program.use();
		m_program.setUniform("ProjMtx", ortho_projection);

		m_mesh.bind();
		}
		catch{}
	}

	nothrow void setVertices(void *vertices, int len)
	{
        glBufferData(GL_ARRAY_BUFFER, len, cast(GLvoid*)vertices, GL_STREAM_DRAW);
	}

	nothrow void setIndices(void *indices, int len)
	{
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, len, indices, GL_STREAM_DRAW);
	}

	void draw(uint count, ushort *offset)
	{
		m_program.use();
		m_mesh.bind();
		draw(null, 0, 0, m_frameSize.x, m_frameSize.y, count, offset);
	}

	nothrow void draw(void* textureId
					  , int x, int y, int w, int h
					  , uint count, ushort* offset)
	{
		try{


		glScissor(x, y, w, h);
		if(m_texture)m_texture.bind();
		if(m_mesh)m_mesh.draw(count, offset);
		}
		catch{}
	}

	nothrow void end()
	{
		try{
		// Restore modified state
		glBindVertexArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
		glUseProgram(m_last_program);
		glDisable(GL_SCISSOR_TEST);
		glBindTexture(GL_TEXTURE_2D, m_last_texture);
		}
		catch{}
	}
}
