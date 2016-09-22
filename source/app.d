module main;

import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import derelict.imgui.imgui;
import imgui_glfw: igGlfwGL3;


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

	void flush()
	{
		glfwSwapBuffers(m_window);
	}
}


void gui(
		 ref bool show_test_window
		 , ref bool show_another_window
		 , ref float[3] clear_color
		 )
{
	// 1. Show a simple window
	// Tip: if we don't call ImGui::Begin()/ImGui::End() the widgets appears in a window automatically called "Debug"
	{
		static float f = 0.0f;
		igText("Hello, world!");
		igSliderFloat("float", &f, 0.0f, 1.0f);
		igColorEdit3("clear color", clear_color);
		if (igButton("Test Window")) show_test_window ^= 1;
		if (igButton("Another Window")) show_another_window ^= 1;
		igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / igGetIO().Framerate, igGetIO().Framerate);
	}

	// 2. Show another simple window, this time using an explicit Begin/End pair
	if (show_another_window)
	{
		igSetNextWindowSize(ImVec2(200,100), ImGuiSetCond_FirstUseEver);
		igBegin("Another Window", &show_another_window);
		igText("Hello");
		if (igTreeNode("Tree"))
		{
			for (size_t i = 0; i < 5; i++)
			{
				if (igTreeNodePtr(cast(void*)i, "Child %d", i))
				{
					igText("blah blah");
					igSameLine();
					igSmallButton("print");
					igTreePop();
				}
			}
			igTreePop();
		}
		igEnd();
	}

	// 3. Show the ImGui test window. Most of the sample code is in ImGui::ShowTestWindow()
	if (show_test_window)
	{
		igSetNextWindowPos(ImVec2(650, 20), ImGuiSetCond_FirstUseEver);
		igShowTestWindow(&show_test_window);
	}
}


void main()
{
	auto scope glfw=new GLFW();
	if(!glfw.createWindow()){
		return;
	}

	auto scope imgui=new igGlfwGL3();
	if(!imgui.initialize(glfw.window)){
		return;
	}

	bool show_test_window = true;
	bool show_another_window = false;
    float[3] clear_color = [0.3f, 0.4f, 0.8f];

	// Main loop
	while (glfw.loop())
	{
		// Rendering
		int w, h;
		glfw.getWindowSize(w, h);
		glViewport(0, 0, w, h);
        glClearColor(clear_color[0], clear_color[1], clear_color[2], 0);
		glClear(GL_COLOR_BUFFER_BIT);

		// gui
		imgui.newFrame();
		gui(show_test_window, show_another_window, clear_color);
		igRender();

		// present
		glfw.flush();
	}
}
