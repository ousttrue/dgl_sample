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
    int m_vertexCount;

    this(int vertexCount)
    {
        glGenVertexArrays(1, &m_vao);
        enforce(m_vao!=0, "fail to glGenVertexArrays");
        m_vertexCount=vertexCount;
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

        glDrawArrays(GL_TRIANGLES, 0, m_vertexCount);

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

    void draw(VertexArray vertexArray)
    {
        glViewport(0, 0, m_frameSize.x, m_frameSize.y);

        // clear
        glClearColor(m_clearColor.x, m_clearColor.y, m_clearColor.z, m_clearColor.w);
        glClear(GL_COLOR_BUFFER_BIT);

        m_program.use();
        vertexArray.draw();
    }

    VertexArray mesh2vertexArray(T)(T[] mesh)
    {
        auto vertexArray=new VertexArray(mesh.length);

        auto vertices=new VertexBuffer();
        vertices.store(mesh.ptr, mesh.byteslen);


        vertexArray.attribPointer!(Vertex, "aVertex")( m_program, vertices);
        vertexArray.attribPointer!(Vertex, "aColor")( m_program, vertices);
        vertexArray.attribPointer!(Vertex, "aTexCoord0")( m_program, vertices);

        return vertexArray;	
    }
}
