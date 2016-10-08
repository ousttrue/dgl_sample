pushd submodules
premake5.exe vs2015
popd

set MSBUILD=C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe
"%MSBUILD%" _build_premake\SubModules.sln /p:Platform=x64 /p:Configuration=Debug

