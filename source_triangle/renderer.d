import derelict.opengl3.gl3;
public import irenderer;
import glutil;
static import shader.imgui;


class Renderer: IRenderer
{
	ShaderProgram m_program;

	uint         g_VboHandle, g_VaoHandle, g_ElementsHandle;

	uint m_vertexSize;
	GLint last_program, last_texture;

	~this()
	{
		if (g_VaoHandle) glDeleteVertexArrays(1, &g_VaoHandle);
		if (g_VboHandle) glDeleteBuffers(1, &g_VboHandle);
		if (g_ElementsHandle) glDeleteBuffers(1, &g_ElementsHandle);
		g_VaoHandle = 0;
		g_VboHandle = 0;
		g_ElementsHandle = 0;
	}

	bool CreateDeviceObjects(uint vertexSize, uint uvOffset, uint colorOffset)
	{
		m_vertexSize=vertexSize;

		m_program=new ShaderProgram();
        auto vertShader=new Shader(GL_VERTEX_SHADER);
        if(!vertShader.compile(shader.imgui.vert))
        {
            return false;
        }
        auto fragShader=new Shader(GL_FRAGMENT_SHADER);
        if(!fragShader.compile(shader.imgui.frag))
        {
            return false;
        }

        m_program=new ShaderProgram();
        m_program.attach(vertShader);
        m_program.attach(fragShader);
        if(!m_program.link()){
            return false;
        }

		glGenBuffers(1, &g_VboHandle);
		glGenBuffers(1, &g_ElementsHandle);

		glGenVertexArrays(1, &g_VaoHandle);
		glBindVertexArray(g_VaoHandle);
		glBindBuffer(GL_ARRAY_BUFFER, g_VboHandle);
		glEnableVertexAttribArray(m_program.Attributes["Position"].location);
		glEnableVertexAttribArray(m_program.Attributes["UV"].location);
		glEnableVertexAttribArray(m_program.Attributes["Color"].location);

		glVertexAttribPointer(m_program.Attributes["Position"].location, 2, GL_FLOAT, GL_FALSE, vertexSize, cast(void*)0);
		glVertexAttribPointer(m_program.Attributes["UV"].location, 2, GL_FLOAT, GL_FALSE, vertexSize, cast(void*)uvOffset);
		glVertexAttribPointer(m_program.Attributes["Color"].location, 4, GL_UNSIGNED_BYTE, GL_TRUE, vertexSize, cast(void*)colorOffset);

		glBindVertexArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);

		return true;
	}

	nothrow void begin(float width, float height)
	{
		// Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled
		glGetIntegerv(GL_CURRENT_PROGRAM, &last_program);
		glGetIntegerv(GL_TEXTURE_BINDING_2D, &last_texture);
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
		try{
		glUniform1i(m_program.Uniforms["Texture"].location, 0);
		glUniformMatrix4fv(m_program.Uniforms["ProjMtx"].location, 1, GL_FALSE, &ortho_projection[0][0]);
		}
		catch{}

		glBindVertexArray(g_VaoHandle);
		glBindBuffer(GL_ARRAY_BUFFER, g_VboHandle);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_ElementsHandle);
	}

	nothrow void setVertices(void *vertices, int len)
	{
        glBufferData(GL_ARRAY_BUFFER, len, cast(GLvoid*)vertices, GL_STREAM_DRAW);
	}

	nothrow void setIndices(void *indices, int len)
	{
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, len, indices, GL_STREAM_DRAW);
	}

	nothrow void draw(void* textureId
					  , int x, int y, int w, int h
					  , uint count, ushort* offset)
	{
		glBindTexture(GL_TEXTURE_2D, cast(uint)textureId);
		glScissor(x, y, w, h);
		glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_SHORT, offset);
	}

	nothrow void end()
	{
		// Restore modified state
		glBindVertexArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
		glUseProgram(last_program);
		glDisable(GL_SCISSOR_TEST);
		glBindTexture(GL_TEXTURE_2D, last_texture);
	}
}
