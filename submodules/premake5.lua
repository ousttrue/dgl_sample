local build_dir="../_build_premake"

-- premake5.lua
location(build_dir)

solution "SubModules"
configurations { "Debug", "Release" }
platforms { "x32", "x64" }


filter "configurations:Debug"
do
    defines { "DEBUG", "_DEBUG" }
    flags { "Symbols" }
end

filter "configurations:Release"
do
    defines { "NDEBUG" }
    optimize "On"
end

filter { "platforms:x32" }
   architecture "x32"

filter { "system:windows", "platforms:x32", "configurations:Debug" }
    targetdir(build_dir.."/msvc32_Debug")
filter { "system:windows", "platforms:x32", "configurations:Release" }
    targetdir(build_dir.."/msvc32_Release")

filter { "system:linux", "platforms:x32", "configurations:Debug" }
    targetdir(build_dir.."/linux32_Debug")
filter { "system:linux", "platforms:x32", "configurations:Release" }
    targetdir(build_dir.."/linux32_Release")


filter { "platforms:x64" }
   architecture "x64"

filter { "system:windows", "platforms:x64", "configurations:Debug" }
    targetdir(build_dir.."/msvc64_Debug")
filter { "system:windows", "platforms:x64", "configurations:Release" }
    targetdir(build_dir.."/msvc64_Release")

filter { "system:linux", "platforms:x64", "configurations:Debug" }
    targetdir(build_dir.."/linux64_Debug")
filter { "system:linux", "platforms:x64", "configurations:Release" }
    targetdir(build_dir.."/linux64_Release")

filter { "action:vs*" }
    buildoptions {
        "/wd4996",
    }
    defines {
        "_CRT_SECURE_NO_DEPRECATE",
        "WIN32",
        "_WINDOWS",
        "_USRDLL",
    }
    characterset ("MBCS")

filter {}

dofile "glfw.lua"
dofile "cimgui.lua"

