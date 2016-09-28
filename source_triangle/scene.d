import gfm.math;


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

