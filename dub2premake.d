#!/usr/bin/rdmd
import std.stdio;
import std.process;
import std.experimental.logger;
import std.json;
import std.path;
import std.file;
import std.conv;
import std.algorithm;
import std.regex;
import std.array;


auto workspace_template="local build_dir='_build_premake'

-- premake5.lua
location(build_dir)

workspace '$[workspace_name]'
do
    configurations { 'Debug', 'Release' }
    platforms { 'x32', 'x64' }
end

filter 'configurations:Debug'
do
    defines { 'DEBUG', '_DEBUG' }
    symbols 'On'
end

filter 'configurations:Release'
do
    defines { 'NDEBUG' }
    optimize 'On'
end

filter { 'platforms:x32' }
   architecture 'x32'
filter {'platforms:x32', 'configurations:Debug' }
    targetdir(build_dir..'/msvc32_Debug')
filter {'platforms:x32', 'configurations:Release' }
    targetdir(build_dir..'/msvc32_Release')

filter { 'platforms:x64' }
   architecture 'x64'
filter {'platforms:x64', 'configurations:Debug' }
    targetdir(build_dir..'/msvc64_Debug')
filter {'platforms:x64', 'configurations:Release' }
    targetdir(build_dir..'/msvc64_Release')

filter {}

";

auto project_template="
------------------------------------------------------------------------------
project '$[project_name]'

--kind 'ConsoleApp'
--kind 'WindowedApp'
--kind 'StaticLib'
--kind 'SharedLib'
kind '$[project_kind]'
language 'D'

objdir '%{prj.name}'

flags{ }
files { 
$[project_files]
}
includedirs { 
$[project_includedirs]
}
defines { }
buildoptions { }
libdirs { '$(OutDir)' }
links {
$[project_links]
}
dependson {
$[project_links]
}
versionconstants {
$[project_versions]
}

";


enum TargetType
{
    autodetect,
    none,
    executable,
    library,
    sourceLibrary,
    staticLibrary,
    dynamicLibrary,
};


void printKeys(JSONValue json)
{
    writeln("## printKeys { ##");
    foreach(k, v; json.object)
    {
        writeln("  key: ", k);
    }
    writeln("## } ##");
}

auto getSubpackages()
{
    auto json=parseJSON(to!string(read("dub.json")));
    return json.object["subPackages"].array.map!((JSONValue v){ 
            return v.object["name"].str; 
            });
}

auto processPackage(string name="")
{
    auto commandline="dub describe";
    if(name.length>0){
        commandline~=" :"~name;
    }
    log("execute...", commandline);
    auto ret=executeShell(commandline);
    if(ret.status!=0){
        fatal("ret.output");
    }

    auto json=parseJSON(ret.output);
    return json.object["targets"].array;
}

string apply(string strtemplate, string[string] map)
{
    string from_map(Captures!(string) m)
    {
        try{
            return map[m.hit[2..$-1]];
        }
        catch
        {
            writeln(m.hit);
            return "";
        }
    }
    return replaceAll!(from_map)(strtemplate, regex(r"\$\[\w+\]"));
}

string getKind(TargetType type)
{
    if(type==TargetType.executable){
        return "ConsoleApp";
    }
    return "StaticLib";
}

auto fixPath(JSONValue v)
{
    return to!string(v.str.asRelativePath(getcwd()))
        .replace("\\", "/")
        ;
}
auto fileList(JSONValue v)
{
    return v.array
        .uniq
        .map!(a => "'"~ fixPath(a) ~"',")
        .join("\n")
        ;
}
auto libList(JSONValue v)
{
    return v.array
        .uniq
        .map!(a => "'"~ fixPath(a).baseName.replace(":", "_") ~"',")
        .join("\n")
        ;
}


void main()
{
    //if(!exists("dub.json"))
    {
        if(!exists("dub.sdl")){
            fatal("no dub settings");
        }

        // convert dub.sdl to dub.json
        copy("dub.sdl", "dub.sdl.bak");
        auto ret=executeShell("dub convert --format=json");
        if(ret.status!=0){
            fatal(ret.output);
        }
        std.file.rename("dub.sdl.bak", "dub.sdl");
    }

    JSONValue[string] package_map;

    string workspace_name;

    // rootPackage
    foreach(target; processPackage())
    {
        auto name=target.object["rootPackage"].str;
        name=name.split(":")[$-1];
        if(!workspace_name){
            workspace_name=name;
        }
        package_map[name]=target;
    }

    // subPackages from dub.json
    auto subPackages=getSubpackages();
    foreach(p; subPackages)
    {
        foreach(target; processPackage(p))
        {
            auto name=target.object["rootPackage"].str;
            name=name.split(":")[$-1];
            //name=name.replace(":", "_");
            package_map[name]=target;
        }
    }

    //auto scope f = File("premake5.lua", "w"); // open for writing

    // write premake5.lua
    write(workspace_template.apply([
                "workspace_name": workspace_name
    ]));

    foreach(k, v; package_map)
    {
        log(k);
        auto b=v.object["buildSettings"];
        auto targetType=cast(TargetType)b.object["targetType"].integer;
        //log(targetType);
        //log(b.object["sourceFiles"]);
        //log(b.object["linkerFiles"]);
        write(project_template.apply([
                    "project_name": k.replace(":", "_"),
                    "project_kind": getKind(targetType),
                    "project_files": fileList(b.object["sourceFiles"]),
                    "project_links": libList(v.object["linkDependencies"]),
                    "project_includedirs": fileList(b.object["importPaths"]),
                    "project_versions": fileList(b.object["versions"]),
                    ]));
    }

    std.file.remove("dub.json");
}

