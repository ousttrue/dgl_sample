import irenderer;
import derelict.imgui.imgui;


ImGuiIO *io;
static this()
{
    DerelictImgui.load();
    io=igGetIO();
}

int vertexSize()
{
	return ImDrawVert.sizeof;
}
int uvOffset()
{
	return ImDrawVert.uv.offsetof;
}
int colorOffset()
{
	return ImDrawVert.col.offsetof;
}

void shutdown()
{
    ImFontAtlas_SetTexID(io.Fonts, cast(void*)0);
    igShutdown();
}

void getTexDataAsRGBA32(ubyte** pixels, int *width, int *height)
{
    ImFontAtlas_GetTexDataAsRGBA32(io.Fonts
            , pixels, width, height
            , null
            );
}

void setTextureID(void *id)
{
    ImFontAtlas_SetTexID(io.Fonts, id);
}

void newFrame(double delta
			  , ref WindowContext w
			  , ref MouseContext m
			  )
{
    // Setup display size (every frame to accommodate for window resizing)
    io.DisplaySize = ImVec2(w.frame_w, w.frame_h);

    // Setup time step
    io.DeltaTime = delta;

    // Setup inputs
    // (we already got mouse wheel, 
    // keyboard keys & characters from glfw callbacks polled in glfwPollEvents())
    if (w.hasFocus)
    {
        // Convert mouse coordinates to pixels
        auto mouse_x = m.x * cast(float)w.frame_w / w.window_w;
        auto mouse_y = m.y * cast(float)w.frame_h / w.window_h;
        // Mouse position, in pixels (set to -1,-1 if no mouse / on another screen, etc.)
        io.MousePos = ImVec2(mouse_x, mouse_y);
    }
    else
    {
        io.MousePos = ImVec2(-1,-1);
    }

    for(int i=0; i<m.pressed.length; ++i)
    {
        io.MouseDown[i] = m.pressed[i];
        m.pressed[i] = false;
    }
    io.MouseWheel = m.wheel;
    m.wheel = 0.0f;

    igNewFrame();
}

void renderDrawLists(IRenderer renderer)
{
    igRender();
    igGetDrawData();
    auto data=igGetDrawData();

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


    /+
            /*
               io.KeyMap[ImGuiKey_Tab] = GLFW_KEY_TAB; // Keyboard mapping. ImGui will use those indices to peek into the io.KeyDown[] array.
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

            //io.RenderDrawListsFn = &RenderDrawLists;

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
+/
