import derelict.opengl3.gl3;
import gfm.math;
import glutil;
import std.conv;
static import shader.imgui;
static import scene;
public import irenderer;


class Renderer: IRenderer
{
	ShaderProgram m_program;
	VertexArray m_mesh;
	bool CreateDeviceObjects(uint vertexSize, uint uvOffset, uint colorOffset)
	{
        m_program=ShaderProgram.createShader!(shader.imgui);
		if(!m_program){
			return false;
		}

		import derelict.imgui.imgui: ImDrawVert;
		m_mesh=m_program.mesh2vertexArray!ImDrawVert([]);

		return true;
	}

	GLint last_program;
	GLint last_texture;
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
		}
		catch{}
		try{
		glUniformMatrix4fv(m_program.Uniforms["ProjMtx"].location, 1, GL_FALSE, &ortho_projection[0][0]);
		}
		catch{}

		m_mesh.bind();
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
		glBindVertexArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
		glUseProgram(last_program);
		glDisable(GL_SCISSOR_TEST);
		glBindTexture(GL_TEXTURE_2D, last_texture);
	}
}
