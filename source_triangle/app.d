import std.stdio;
import std.conv;
import glfw;
import derelict.opengl3.gl3;


class OpenGL
{
	string m_renderer;
	string m_vendor;
	string m_version;
	string m_shaderVersion;
	int m_versionMajor;
	int m_versionMinor;

	string[] m_extensions;

	static this()
	{
		DerelictGL3.load();
	}

	this()
	{
		DerelictGL3.reload();

		m_renderer=glGetString(GL_RENDERER).to!string;
		m_vendor=glGetString(GL_VENDOR).to!string;
		m_version=glGetString(GL_VERSION).to!string;
		m_shaderVersion=glGetString(GL_SHADING_LANGUAGE_VERSION).to!string;
		glGetIntegerv(GL_MAJOR_VERSION, &m_versionMajor);
		glGetIntegerv(GL_MINOR_VERSION, &m_versionMinor);

		int extensions;
		glGetIntegerv(GL_NUM_EXTENSIONS, &extensions);
		m_extensions.length=extensions;
		for(int i=0; i<extensions; ++i){
			m_extensions[i]=glGetStringi(GL_EXTENSIONS, i).to!string;
		}
	}
}


void main()
{
    // window
    auto scope glfw=new GLFW();
    if(!glfw.createWindow(4, 0)){
        return;
    }

	auto gl=new OpenGL();

	// main loop
	while (glfw.loop())
	{	
		/*
		double current_time =  glfw.time();
		auto size=glfw.getSize();
		auto windowSize=glfw.getWindowSize();
		auto pos=glfw.getCursorPos();

		// rendering 3D scene
		renderer.clearRenderTarget(context.clear_color);
		renderer.setViewport(size[0], size[1]);

		// gui
		io.updateGui(context
					 , current_time, size, windowSize
					 , pos, glfw.mouseDown(0), glfw.mouseDown(1), glfw.mouseDown(2)
					 , glfw.hasFocus());
		glfw.setMouseCursor(io.MouseDrawCursor
							);
		igGetDrawData();
		io.RenderDrawLists(renderer);
		*/

		// present
		glfw.flush();
	}
}
