project "cimgui"

--kind "ConsoleApp"
--kind "WindowedApp"
--kind "StaticLib"
kind "SharedLib"
--language "C"
language "C++"

objdir "%{prj.name}"

flags{
    --"WinMain"
    --"Unicode",
    --"StaticRuntime",
}
files {
    "cimgui/cimgui/cimgui.h",
    "cimgui/cimgui/cimgui.cpp",
    "cimgui/cimgui/drawList.cpp",
    "cimgui/cimgui/fontAtlas.cpp",
    "cimgui/imgui/imgui.cpp",
    "cimgui/imgui/imgui_demo.cpp",
    "cimgui/imgui/imgui_draw.cpp",
    "cimgui/imgui/imgui_internal.h",
}
includedirs {
    "cimgui/cimgui",
}
defines {
    "WIN32",
    "_WINDOWS",
    "_USRDLL",
    "CIMGUI_EXPORTS",
}
buildoptions { }
libdirs { }
links { }

postbuildcommands{
    "copy $(TargetDir)$(TargetName).dll ..\\..",
}
filter { "configurations:Debug" }
    postbuildcommands{
        "copy $(TargetDir)$(TargetName).pdb ..\\..",
    }

