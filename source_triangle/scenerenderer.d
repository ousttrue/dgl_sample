import glutil;
import gfm.math;


struct UniformVariables
{
	mat4!float uModelMatrix = mat4!float.identity;
}


class Model
{
	VertexArray Model;
	UniformVariables Uniform;
	int IndexLength;

	this(VertexArray model, int indexLength)
	{
		Model=model;
		IndexLength=indexLength;
	}

	void draw(ShaderProgram program)
	{
		program.setUniform(Uniform);
        Model.bind();
        Model.draw(IndexLength, null);
	}
}


class SceneRenderer
{
    ShaderProgram m_program;
    Model[] m_models;

 private:
    this(ShaderProgram program)
    {
        m_program=program;
    }

 public:
    static SceneRenderer create(alias Module)()
    {
        // 3D renderer
        auto program=glutil.ShaderProgram.createShader!(Module)();
        if(!program){
            return null;
        }

        return new SceneRenderer(program);
    }

    VertexArray addModel(Vertex)(Vertex[] vertices, ushort[] indices)
    {
        auto mesh=m_program.mesh2vertexArray(vertices, indices);
        if(!mesh){
            return null;
        }
        m_models~=new Model(mesh, indices.length);
        return mesh;
    }

    void draw()
    {
        m_program.use();
		foreach(m; m_models)
		{
			m.draw(m_program);
		}
    }
}

