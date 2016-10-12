import std.file;
import std.stdio;
import std.string;
import std.exception;
import std.conv;
import std.algorithm;
import std.array;
import std.range;
import gfm.math;

static import scene;


struct Vec3
{
    float x;
    float y;
    float z;
};

struct Vertex
{
    Vec3 Position;
    Vec3 Normal;
};

class Obj
{
    string Name;
    Vec3[] Positions;
    Vec3[] Normals;

    Vertex[] Vertices;

    this(string name)
    {
        Name=name;
    }

    void pushPosition(T)(T p)
    {
        enforce(p.length==3);
        Positions~=Vec3(p[0], p[1], p[2]);
    }

    void pushNormal(T)(T p)
    {
        enforce(p.length==3);
        Normals~=Vec3(p[0], p[1], p[2]);
    }

    void push(int p, int n)
    {
        Vertices~=Vertex(Positions[p], Normals[n]);
    }
}


Obj[] parseObj(string path, float scale=1.0f)
{
    auto f=File(path);

    Obj[] objs;
    void push(T)(T l)
    {
        if(l.length==0){
            return;
        }
        if(l[0]=='#'){
            return;
        }
        switch(l.split[0])
        {
            case "o":
                objs~=new Obj(l[2 .. $].to!string);
                break;

            case "v":
                // vertex position
                objs[$-1].pushPosition(l[2 .. $].split.map!(a => a.to!float * scale));
                break;

            case "vn":
                // vertex normal
                objs[$-1].pushNormal(l[2 .. $].split.map!(a => a.to!float));
                break;

            case "s":
                // surface
                break;

            case "f":
                // face
                {
                    auto face=l[2 .. $].split;
                    foreach(fv; face)
                    {
                        auto p_n=fv.split("/");
                        //writeln(p_n);
                        objs[$-1].push(p_n[0].to!int-1, p_n[2].to!int-1);
                    }
                }
                break;

            default:
                writeln(l);
                assert("unknown line. "~l);
                break;
        }
    }

    foreach(l; f.byLine)
    {
        push(l);
    }

    return objs;
}


scene.Builder!Vertex loadObj(string path, float scale=1.0f)
{
    auto objs=parseObj(path, scale);
    if(objs.empty()){
        return null;
    }

    // todo
    auto obj=objs[0];

    auto builder=new scene.Builder!Vertex;
    builder.Vertices=obj.Vertices;
    builder.Indices = iota(0, obj.Vertices.length, 1).map!(a => cast(ushort)a).array;

    return builder;
}

