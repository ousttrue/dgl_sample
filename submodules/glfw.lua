project "glfw3"

local f=io.open("glfw/src/glfw_config.h", "w")
if _OS=="linux" then
    f:write [[
#define _GLFW_X11
#define _GLFW_HAS_XF86VM
    ]]

else
    f:write [[
#define _GLFW_WIN32
#define _GLFW_BUILD_DLL
    ]]
end
f:close()

--kind "ConsoleApp"
--kind "WindowedApp"
--kind "StaticLib"
kind "SharedLib"
language "C"
--language "C++"

objdir "%{prj.name}"

flags{
    --"WinMain"
    --"Unicode",
    --"StaticRuntime",
}
files {
    "glfw/src/internal.h",
    "glfw/src/glfw_config.h",
    "glfw/include/GLFW/glfw3.h",
    "glfw/include/GLFW/glfw3native.h",
    "glfw/src/win32_platform.h",
    "glfw/src/win32_joystick.h",
    "glfw/src/wgl_context.h",
    "glfw/src/egl_context.h",
    "glfw/src/context.c",
    "glfw/src/init.c",
    "glfw/src/input.c",
    "glfw/src/monitor.c",
    "glfw/src/vulkan.c",
    "glfw/src/window.c",
    "glfw/src/egl_context.c",
}
includedirs { 
    "glfw/src",
}
defines { 
    "_GLFW_USE_CONFIG_H",
    "glfw_EXPORTS",
}
buildoptions { }
libdirs { }
links { }

filter { "system:windows" }
do
    files {
        "glfw/src/win32_init.c",
        "glfw/src/win32_joystick.c",
        "glfw/src/win32_monitor.c",
        "glfw/src/win32_time.c",
        "glfw/src/win32_tls.c",
        "glfw/src/win32_window.c",
        "glfw/src/wgl_context.c",
    }
end
filter { "system:not windows" }
do
    files {
        "glfw/src/glx_context.c",
        "glfw/src/x11_init.c",
        "glfw/src/x11_monitor.c",
        "glfw/src/x11_platform.h",
        "glfw/src/x11_window.c",
        "glfw/src/linux_joystick.c",
        "glfw/src/xkb_unicode.c",
        "glfw/src/posix_tls.c",
        "glfw/src/posix_time.c",
    }
    links {
        "m",
        "X11",
        "pthread",
        "Xrandr",
        "Xinerama",
        "Xi",
        "Xxf86vm",
        "Xcursor",
        "xcb",
        "Xext",
        "Xrender",
        "Xfixes",
        "Xau",
        "Xdmcp",

    }
end

