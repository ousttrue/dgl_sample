@rem call build_submodules_Win32_Release.bat
rdmd dub2premake.d > premake5.lua
submodules\premake5.exe vs2015

