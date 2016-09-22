import derelict.imgui.imgui;
import irenderer;


extern(C) nothrow void RenderDrawLists(ImDrawData* data)
{
	auto io = igGetIO();

	auto renderer=(cast(ImGui*)io.UserData).m_renderer;

	renderer.begin(io.DisplaySize.x, io.DisplaySize.y);
    foreach (n; 0..data.CmdListsCount)
    {
        ImDrawList* cmd_list = data.CmdLists[n];

        auto countVertices = ImDrawList_GetVertexBufferSize(cmd_list);
		renderer.setVertices(ImDrawList_GetVertexPtr(cmd_list,0), countVertices * ImDrawVert.sizeof);

        auto countIndices = ImDrawList_GetIndexBufferSize(cmd_list);
		renderer.setIndices(ImDrawList_GetIndexPtr(cmd_list,0), countIndices * ImDrawIdx.sizeof);

        ImDrawIdx* idx_buffer_offset;
        auto cmdCnt = ImDrawList_GetCmdSize(cmd_list);       
        foreach(i; 0..cmdCnt)
        {
            auto pcmd = ImDrawList_GetCmdPtr(cmd_list, i);

            if (pcmd.UserCallback)
            {
                pcmd.UserCallback(cmd_list, pcmd);
            }
            else
            {
				renderer.draw(pcmd.TextureId
					, cast(int)pcmd.ClipRect.x, cast(int)(io.DisplaySize.y - pcmd.ClipRect.w)
					, cast(int)(pcmd.ClipRect.z - pcmd.ClipRect.x), cast(int)(pcmd.ClipRect.w - pcmd.ClipRect.y)
					, pcmd.ElemCount, idx_buffer_offset
				);
            }

            idx_buffer_offset += pcmd.ElemCount;
        }
    }

	renderer.end();
}


/+
extern(C) nothrow const(char)* igImplGlfwGL3_GetClipboardText()
{
    return glfwGetClipboardString(g_window);
}

extern(C) nothrow void igImplGlfwGL3_SetClipboardText(const(char)* text)
{
    glfwSetClipboardString(g_window, text);
}

extern(C) nothrow void igImplGlfwGL3_MouseButtonCallback(GLFWwindow*, int button, int action, int /*mods*/)
{
    if (action == GLFW_PRESS && button >= 0 && button < 3)
        m_mousePressed[button] = true;
}

extern(C) nothrow void igImplGlfwGL3_ScrollCallback(GLFWwindow*, double /*xoffset*/, double yoffset)
{
    m_mouseWheel += cast(float)yoffset; // Use fractional mouse wheel, 1.0 unit 5 lines.
}

extern(C) nothrow void igImplGlfwGL3_KeyCallback(GLFWwindow*, int key, int, int action, int mods)
{
	if(key==-1)return;

    auto io = igGetIO();
    if (action == GLFW_PRESS)
        io.KeysDown[key] = true;
    if (action == GLFW_RELEASE)
        io.KeysDown[key] = false;
    io.KeyCtrl = (mods & GLFW_MOD_CONTROL) != 0;
    io.KeyShift = (mods & GLFW_MOD_SHIFT) != 0;
    io.KeyAlt = (mods & GLFW_MOD_ALT) != 0;
}

extern(C) nothrow void igImplGlfwGL3_CharCallback(GLFWwindow*, uint c)
{
    if (c > 0 && c < 0x10000)
    {
        ImGuiIO_AddInputCharacter(cast(ushort)c);
    }
}
+/


struct ImGui
{
	IRenderer m_renderer;
	double       m_time = 0.0f;
	bool[3]      m_mousePressed;
	float        m_mouseWheel = 0.0f;

	static this()
	{
		DerelictImgui.load();
	}

	~this()
	{
		ImFontAtlas_SetTexID(igGetIO().Fonts, cast(void*)0);
		igShutdown();
	}

	bool initialize(IRenderer renderer)
	{
		m_renderer=renderer;

		ImGuiIO* io = igGetIO(); 

		//ImFont* my_font0 = io.Fonts->AddFontDefault();
		//ImFont* my_font1 = io.Fonts->AddFontFromFileTTF("../../extra_fonts/DroidSans.ttf", 16.0f);
		//ImFont* my_font2 = io.Fonts->AddFontFromFileTTF("../../extra_fonts/Karla-Regular.ttf", 16.0f);
		//ImFont* my_font3 = io.Fonts->AddFontFromFileTTF("../../extra_fonts/ProggyClean.ttf", 13.0f); my_font3->DisplayOffset.y += 1;
		//ImFont* my_font4 = io.Fonts->AddFontFromFileTTF("../../extra_fonts/ProggyTiny.ttf", 10.0f); my_font4->DisplayOffset.y += 1;
		//ImFont* my_font5 = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, io.Fonts->GetGlyphRangesJapanese());

		/*
		io.KeyMap[ImGuiKey_Tab] = GLFW_KEY_TAB;                 // Keyboard mapping. ImGui will use those indices to peek into the io.KeyDown[] array.
		io.KeyMap[ImGuiKey_LeftArrow] = GLFW_KEY_LEFT;
		io.KeyMap[ImGuiKey_RightArrow] = GLFW_KEY_RIGHT;
		io.KeyMap[ImGuiKey_UpArrow] = GLFW_KEY_UP;
		io.KeyMap[ImGuiKey_DownArrow] = GLFW_KEY_DOWN;
		io.KeyMap[ImGuiKey_Home] = GLFW_KEY_HOME;
		io.KeyMap[ImGuiKey_End] = GLFW_KEY_END;
		io.KeyMap[ImGuiKey_Delete] = GLFW_KEY_DELETE;
		io.KeyMap[ImGuiKey_Backspace] = GLFW_KEY_BACKSPACE;
		io.KeyMap[ImGuiKey_Enter] = GLFW_KEY_ENTER;
		io.KeyMap[ImGuiKey_Escape] = GLFW_KEY_ESCAPE;
		io.KeyMap[ImGuiKey_A] = GLFW_KEY_A;
		io.KeyMap[ImGuiKey_C] = GLFW_KEY_C;
		io.KeyMap[ImGuiKey_V] = GLFW_KEY_V;
		io.KeyMap[ImGuiKey_X] = GLFW_KEY_X;
		io.KeyMap[ImGuiKey_Y] = GLFW_KEY_Y;
		io.KeyMap[ImGuiKey_Z] = GLFW_KEY_Z;
		*/

		io.RenderDrawListsFn = &RenderDrawLists;

		/*
		io.SetClipboardTextFn = &igImplGlfwGL3_SetClipboardText;
		io.GetClipboardTextFn = &igImplGlfwGL3_GetClipboardText;
		/+#ifdef _MSC_VER
		io.ImeWindowHandle = glfwGetWin32Window(g_Window);
		#endif+/

		{
			glfwSetMouseButtonCallback(window, &igImplGlfwGL3_MouseButtonCallback);
			glfwSetScrollCallback(window, &igImplGlfwGL3_ScrollCallback);
			glfwSetKeyCallback(window, &igImplGlfwGL3_KeyCallback);
			glfwSetCharCallback(window, &igImplGlfwGL3_CharCallback);
		}
		*/

		return true;
	}

	bool newFrame(double current_time
				  , int display_w, int display_h
				  ,int w, int h
				  , bool hasFocus
				  , double mouse_x, double mouse_y
				  , bool mouse0, bool mouse1, bool mouse2
				  )
	{
		auto io = igGetIO();

		if (!io.UserData){
			m_renderer.CreateDeviceObjects(ImDrawVert.sizeof, ImDrawVert.uv.offsetof, ImDrawVert.col.offsetof);

			ubyte* pixels;
			int width, height;
			ImFontAtlas_GetTexDataAsRGBA32(io.Fonts,&pixels,&width,&height,null);

			// Store our identifier
			ImFontAtlas_SetTexID(io.Fonts
								 , m_renderer.CreateFonts(pixels, width, height));

			io.UserData = &this;
		}

		// Setup display size (every frame to accommodate for window resizing)
		io.DisplaySize = ImVec2(cast(float)display_w, cast(float)display_h);

		// Setup time step
		io.DeltaTime = m_time > 0.0 ? cast(float)(current_time - m_time) : cast(float)(1.0f/60.0f);
		m_time = current_time;

		// Setup inputs
		// (we already got mouse wheel, keyboard keys & characters from glfw callbacks polled in glfwPollEvents())
		if (hasFocus)
		{
			mouse_x *= cast(float)display_w / w;                        // Convert mouse coordinates to pixels
			mouse_y *= cast(float)display_h / h;
			io.MousePos = ImVec2(mouse_x, mouse_y);   // Mouse position, in pixels (set to -1,-1 if no mouse / on another screen, etc.)
		}
		else
		{
			io.MousePos = ImVec2(-1,-1);
		}

		{
			io.MouseDown[0] = m_mousePressed[0] || mouse0;
			m_mousePressed[0] = false;
		}
		{
			io.MouseDown[1] = m_mousePressed[1] || mouse0;
			m_mousePressed[1] = false;
		}
		{
			io.MouseDown[2] = m_mousePressed[2] || mouse0;
			m_mousePressed[2] = false;
		}

		io.MouseWheel = m_mouseWheel;
		m_mouseWheel = 0.0f;

		igNewFrame();

		return io.MouseDrawCursor;
	}
}
