module main;

import glfw;
import derelict.imgui.imgui;
import imgui;
import renderer;


void RenderDrawLists(ImGuiIO *io, IRenderer renderer)
{
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


struct GuiContext
{
	double       m_time = 0.0f;
	bool[3]      m_mousePressed;
	float        m_mouseWheel = 0.0f;
	bool show_test_window;
	bool show_another_window;
	float[3] clear_color;
}


void updateGui(ImGuiIO *io
			   , ref GuiContext context
			   , double current_time
			   , int[2] size, int[2] windowSize
			   , double[2] pos, bool mouseDown0, bool mouseDown1, bool mouseDown2
			   , bool hasFocus
			   )
{
	// Setup display size (every frame to accommodate for window resizing)
	io.DisplaySize = ImVec2(cast(float)size[0], cast(float)size[1]);

	// Setup time step
	io.DeltaTime = context.m_time > 0.0 ? cast(float)(current_time - context.m_time) : cast(float)(1.0f/60.0f);
	context.m_time = current_time;

	// Setup inputs
	// (we already got mouse wheel, keyboard keys & characters from glfw callbacks polled in glfwPollEvents())
	if (hasFocus)
	{
		// Convert mouse coordinates to pixels
		auto mouse_x = pos[0] * cast(float)size[0] / windowSize[0];
		auto mouse_y = pos[1] * cast(float)size[1] / windowSize[1];
		// Mouse position, in pixels (set to -1,-1 if no mouse / on another screen, etc.)
		io.MousePos = ImVec2(mouse_x, mouse_y);
	}
	else
	{
		io.MousePos = ImVec2(-1,-1);
	}

	{
		io.MouseDown[0] = context.m_mousePressed[0] || mouseDown0;
		context.m_mousePressed[0] = false;
	}
	{
		io.MouseDown[1] = context.m_mousePressed[1] || mouseDown1;
		context.m_mousePressed[1] = false;
	}
	{
		io.MouseDown[2] = context.m_mousePressed[2] || mouseDown2;
		context.m_mousePressed[2] = false;
	}

	io.MouseWheel = context.m_mouseWheel;
	context.m_mouseWheel = 0.0f;

	//
	igNewFrame();
	//

	// 1. Show a simple window
	// Tip: if we don't call ImGui::Begin()/ImGui::End() the widgets appears in a window automatically called "Debug"
	{
		static float f = 0.0f;
		igText("Hello, world!");
		igSliderFloat("float", &f, 0.0f, 1.0f);
		igColorEdit3("clear color", context.clear_color);
		if (igButton("Test Window")) context.show_test_window ^= 1;
		if (igButton("Another Window")) context.show_another_window ^= 1;
		igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / igGetIO().Framerate, igGetIO().Framerate);
	}

	// 2. Show another simple window, this time using an explicit Begin/End pair
	if (context.show_another_window)
	{
		igSetNextWindowSize(ImVec2(200,100), ImGuiSetCond_FirstUseEver);
		igBegin("Another Window", &context.show_another_window);
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
	if (context.show_test_window)
	{
		igSetNextWindowPos(ImVec2(650, 20), ImGuiSetCond_FirstUseEver);
		igShowTestWindow(&context.show_test_window);
	}

	igRender();
}


void main()
{
	// window
	auto scope glfw=new GLFW();
	if(!glfw.createWindow()){
		return;
	}

    // opengl
    auto scope renderer=new Renderer();
	renderer.CreateDeviceObjects(ImDrawVert.sizeof, ImDrawVert.uv.offsetof, ImDrawVert.col.offsetof);

	// gui
	DerelictImgui.load();
	auto io = igGetIO();
	GuiContext context={
		m_time: 0.0f,
		m_mouseWheel: 0.0f,

		show_test_window: true,
		show_another_window: false,
		clear_color: [0.3f, 0.4f, 0.8f],
	};

	// setup font
	ubyte* pixels;
	int width, height;
	ImFontAtlas_GetTexDataAsRGBA32(io.Fonts,&pixels,&width,&height,null);
	ImFontAtlas_SetTexID(io.Fonts
						 , renderer.CreateFonts(pixels, width, height));

	// main loop
	while (glfw.loop())
	{	
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

		// present
		glfw.flush();
	}

	ImFontAtlas_SetTexID(igGetIO().Fonts, cast(void*)0);
	igShutdown();
}
