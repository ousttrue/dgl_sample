import derelict.util.exception;
import derelict.glfw3.glfw3;
import std.stdio;


extern(C) nothrow void error_callback(int error, const(char)* description)
{
	import std.stdio;
    import std.conv;
	try writefln("glfw err: %s ('%s')",error, to!string(description));
	catch{}
}


ShouldThrow missingSymFunc( string symName )
{
    if( symName == "glfwSetWindowIcon") {
        return ShouldThrow.No;
    }

    writeln("no such symbol: ", symName);
    return ShouldThrow.No;
    //return ShouldThrow.Yes;
}


class GLFW
{
	GLFWwindow *m_window;
	@property public GLFWwindow* window()
	{
		return m_window;
	}

	static this()
	{
		DerelictGLFW3.missingSymbolCallback = &missingSymFunc;
		try{
			DerelictGLFW3.load();
		}
		catch( SharedLibLoadException slle ) {
			DerelictGLFW3.load("_build_premake/linux64_Debug/libglfw3.so");
		}
	}

	~this()
	{
		glfwTerminate();
	}

	bool createWindow()
	{
		// Setup window
		glfwSetErrorCallback(&error_callback);
		if (!glfwInit()){
			return false;
		}
		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
		glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, true);

		m_window = glfwCreateWindow(1280, 720, "ImGui OpenGL3 example", null, null);
		if(!m_window){
			return false;
		}
		glfwMakeContextCurrent(m_window);
		glfwInit();
		return true;
	}

	int[2] getWindowSize()
	{
		int[2] size;
		glfwGetWindowSize(m_window, &size[0], &size[1]);
		return size;
	}

	int[2] getSize()
	{
		int[2] size;
		glfwGetFramebufferSize(m_window, &size[0], &size[1]);
		return size;
	}

	public bool hasFocus()
	{
		return glfwGetWindowAttrib(m_window, GLFW_FOCUSED)!=0;
	}

	double[2] getCursorPos()
	{
		double[2] pos;
		glfwGetCursorPos(m_window, &pos[0], &pos[1]);
		return pos;
	}

	bool loop()
	{
		if(glfwWindowShouldClose(m_window)){
			return false;
		}
		glfwPollEvents();
		return true;
	}

	bool mouseDown(int i)
	{
		return glfwGetMouseButton(m_window, i) != 0;
	}

	void setMouseCursor(bool mouseCursor)
	{
		glfwSetInputMode(m_window, GLFW_CURSOR
						 , mouseCursor ? GLFW_CURSOR_HIDDEN : GLFW_CURSOR_NORMAL);
	}

	void flush()
	{
		glfwSwapBuffers(m_window);
	}
}
