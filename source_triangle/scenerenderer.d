import glutil;
import gfm.math;
import std.signals;
import core.time;
import guidefine;


struct UniformVariables
{
	mat4!float uModelMatrix = mat4!float.identity;
}


struct SceneData
{
	RGB BackgroundColor = RGB(0.5f, 0.3f, 0.2f);
};


class Model
{
	VertexArray Mesh;
	UniformVariables Uniform;
	int IndexLength;

	mixin Signal!(Model, Duration);

	this(VertexArray mesh, int indexLength)
	{
		Mesh=mesh;
		IndexLength=indexLength;
	}

	void draw(ShaderProgram program)
	{
		program.setUniform(Uniform);
        Mesh.bind();
        Mesh.draw(IndexLength, null);
	}
}


class SceneRenderer
{
private:
    ShaderProgram m_program;
    Model[] m_models;

    this(ShaderProgram program)
    {
        m_program=program;
    }

 public:
	SceneData Settings;

    static SceneRenderer create(alias Module)()
    {
        // 3D renderer
        auto program=glutil.ShaderProgram.createShader!(Module)();
        if(!program){
            return null;
        }

        return new SceneRenderer(program);
    }

    Model addModel(Vertex)(Vertex[] vertices, ushort[] indices)
    {
        auto mesh=m_program.mesh2vertexArray(vertices, indices);
        if(!mesh){
            return null;
        }
		auto model=new Model(mesh, indices.length);
        m_models~=model;
        return model;
    }

	void update(Duration delta)
	{
		foreach(m; m_models)
		{
			m.emit(m, delta);
		}
	}

    void draw()
    {
		glutil.clear3v(&Settings.BackgroundColor.R);

        m_program.use();
		foreach(m; m_models)
		{
			m.draw(m_program);
		}
    }
}
