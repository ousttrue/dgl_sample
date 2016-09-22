import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;


extern(C) nothrow void error_callback(int error, const(char)* description)
{
	import std.stdio;
    import std.conv;
	try writefln("glfw err: %s ('%s')",error, to!string(description));
	catch{}
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
		DerelictGL3.load();
		DerelictGLFW3.load();
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
		DerelictGL3.reload();
		return true;
	}

	void getWindowSize(ref int w, ref int h)
	{
		glfwGetWindowSize(m_window, &w, &h);
	}

	bool loop()
	{
		if(glfwWindowShouldClose(m_window)){
			return false;
		}
		glfwPollEvents();
		return true;
	}

	void clearRenderTarget(float[] clear_color)
	{
		int w, h;
		glfwGetWindowSize(m_window, &w, &h);
		glViewport(0, 0, w, h);
		if(clear_color.length>=3){
			glClearColor(clear_color[0], clear_color[1], clear_color[2], 0);
		}
		glClear(GL_COLOR_BUFFER_BIT);
	}

	void flush()
	{
		glfwSwapBuffers(m_window);
	}
}



