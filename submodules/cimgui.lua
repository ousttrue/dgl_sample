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
    "DerelictImgui/cimgui/cimgui/cimgui.h",
    "DerelictImgui/cimgui/cimgui/cimgui.cpp",
    "DerelictImgui/cimgui/cimgui/drawList.cpp",
    "DerelictImgui/cimgui/cimgui/fontAtlas.cpp",
    "DerelictImgui/cimgui/imgui/imgui.cpp",
    "DerelictImgui/cimgui/imgui/imgui_demo.cpp",
    "DerelictImgui/cimgui/imgui/imgui_draw.cpp",
    "DerelictImgui/cimgui/imgui/imgui_internal.h",
}
includedirs {
    "DerelictImgui/cimgui/cimgui",
}
defines {
    "CIMGUI_EXPORTS",
}
buildoptions { }
libdirs { }
links { }

