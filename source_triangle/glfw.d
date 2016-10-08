import irenderer;
import derelict.glfw3.glfw3;
import derelict.util.exception;
import std.experimental.logger;
import std.stdio;
import std.conv;


struct User
{
	GLFW that;
}

extern(C) nothrow void error_callback(int error, const(char)* description)
{
	try {
		errorf("glfw err: %s ('%s')",error, description.to!string);
	}
	catch{}
}

extern(C) nothrow static void cursor_position_callback(GLFWwindow* window
													   , double xpos, double ypos)
{
	try{
		auto p=cast(User*)glfwGetWindowUserPointer(window);
		p.that.onMousePosition(xpos, ypos);
	}
	catch{}
}

extern(C) nothrow void mouse_button_callback(GLFWwindow* window
											 , int button, int action, int mods)
{
	try{
		auto p=cast(User*)glfwGetWindowUserPointer(window);
		p.that.onMouseButton(button, action, mods);
	}
	catch{}
}

extern(C) nothrow void scroll_callback(GLFWwindow* window
									   , double xoffset, double yoffset)
{
	try{
		auto p=cast(User*)glfwGetWindowUserPointer(window);
		p.that.onScroll(xoffset, yoffset);
	}
	catch{}
}

class GLFW
{
	GLFWwindow *m_window;
	@property public GLFWwindow* window()
	{
		return m_window;
	}

	User m_user;

	static this()
	{
		DerelictGLFW3.missingSymbolCallback = name => ShouldThrow.No;
		try{
			DerelictGLFW3.load();
		}
		catch( SharedLibLoadException slle ) {
			DerelictGLFW3.load("_build_premake/linux64_Debug/libglfw3.so");
		}
	}

	this()
	{
		m_user.that=this;
	}

	~this()
	{
		glfwTerminate();
	}

	void onMousePosition(double xpos, double ypos)
	{
		logf("%s x %s", xpos, ypos);
	}

	void onMouseButton(int button, int action, int mods)
	{
		logf("%s, %s, %s", button, action, mods);
	}

	void onScroll(double xoffset, double yoffset)
	{
		logf("%s, %s", xoffset, yoffset);
	}

    void updateContext(ref WindowContext w, ref MouseContext m)
    {
		glfwGetWindowSize(m_window, &w.window_w, &w.window_h);
		glfwGetFramebufferSize(m_window, &w.frame_w, &w.frame_h);
		w.hasFocus=glfwGetWindowAttrib(m_window, GLFW_FOCUSED)!=0;

		glfwGetCursorPos(m_window, &m.x, &m.y);
		for(int i=0; i<3; ++i)
		{
			m.pressed[i]=glfwGetMouseButton(m_window, i) != 0;
		}
    }

	bool createWindow(int major, int minor)
	{
		// Setup window
		glfwSetErrorCallback(&error_callback);
		if (!glfwInit()){
			return false;
		}

		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, major);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, minor);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
		glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, true);

		m_window = glfwCreateWindow(1280, 720, "ImGui OpenGL3 example", null, null);
		if(!m_window){
			return false;
		}
		glfwMakeContextCurrent(m_window);
		glfwInit();

		glfwSetWindowUserPointer(m_window, &m_user);

		// mouse callback
		glfwSetCursorPosCallback(m_window, &cursor_position_callback);
		glfwSetMouseButtonCallback(m_window, &mouse_button_callback);
		glfwSetScrollCallback(m_window, &scroll_callback);

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

	double time()
	{
		return glfwGetTime();
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
