#!/usr/bin/env rdmd
import std.file;
import std.stdio;
import std.string;
import std.exception;
import std.conv;
import std.algorithm;
import std.array;


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


void main()
{
    auto f=File("wt_teapot.obj");

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
                objs[$-1].pushPosition(l[2 .. $].split.map!(a => a.to!float));
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

    //writeln(objs);

    // write to file

    auto w=File("source_triangle/teapot.d", "w");
    w.write("
import gfm.math;
import scene;
import std.range;
import std.algorithm;
import std.array;

struct Vertex
{
	vec3!float Position;
    vec3!float Normal;
}

Builder!Vertex loadTeapot(float scale=1.0f)
{
	auto teapot=new Builder!Vertex;
    teapot.Vertices=[
");

    foreach(v; objs[$-1].Vertices)
    {
        w.writefln("Vertex(vec3!float(%s, %s, %s), vec3!float(%s, %s, %s)),"
                , v.Position.x
                , v.Position.y
                , v.Position.z
                , v.Normal.x
                , v.Normal.y
                , v.Normal.z
                );
    }

    w.write("
    ];

    teapot.Indices = iota(0, teapot.Vertices.length, 1).map!(a => cast(ushort)a).array;

	return teapot;
}
");
}

