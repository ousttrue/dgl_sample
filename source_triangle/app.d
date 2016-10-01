import glfw;
import gfm.math;
import irenderer;
import renderer;
import fpsclock;
static import gui;
static import glutil;
static import scene;
static import shader.simple;
static import shader.circle;
static import shader.imgui;

import std.typecons;

alias GuiData=Tuple!(
					 bool, "show_test_window"
					 , bool, "show_another_window"
						 , float[3], "clear_color"
							 );


void build(T...)(ref Tuple!T data)
{
	import derelict.imgui.imgui;

    // 1. Show a simple window
    // Tip: if we don't call ImGui::Begin()/ImGui::End() the widgets appears in a window automatically called "Debug"
    {
        static float f = 0.0f;
        igText("Hello, world!");
        igSliderFloat("float", &f, 0.0f, 1.0f);
        igColorEdit3("clear color", data.clear_color);
        if (igButton("Test Window")) data.show_test_window ^= 1;
        if (igButton("Another Window")) data.show_another_window ^= 1;
        igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / igGetIO().Framerate, igGetIO().Framerate);
    }

    // 2. Show another simple window, this time using an explicit Begin/End pair
    if (data.show_another_window)
    {
        igSetNextWindowSize(ImVec2(200,100), ImGuiSetCond_FirstUseEver);
        igBegin("Another Window", &data.show_another_window);
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
    if (data.show_test_window)
    {
        igSetNextWindowPos(ImVec2(650, 20), ImGuiSetCond_FirstUseEver);
        igShowTestWindow(&data.show_test_window);
    }
}


void main()
{
    // window
    auto glfw=new GLFW();
    if(!glfw.createWindow(4, 5)){
        return;
    }

	// gl
	auto gl=new glutil.OpenGL();

	// 3D renderer
	auto renderPass=new glutil.RenderPass();
	if(!renderPass.createShader!(shader.simple))
	{
		return;
	}
	renderPass.setClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	auto vertices=new scene.Vertices!(
		vec3!float, "aPosition"
		, vec3!float, "aColor"
		, vec2!float, "aTexCoord0"
		)();
	vertices.store(scene.createTriangle(0.5f));
	ushort[] indices=[0, 1, 2];
	renderPass.mesh2vertexArray(vertices, indices);

	// gui
	WindowContext windowContext;
	MouseContext mouseContext;

    // guiの変数
    GuiData data;
    data.show_test_window=true;
    data.show_another_window=false;
    data.clear_color=[0.3f, 0.4f, 0.8f];

	/+
    // GUI renderer
    auto scope guiRenderer=new glutil.RenderPass();
	{
	if(!guiRenderer.createShader!(shader.imgui))
	{
	return;
	}
	auto guiVertices=new scene.Vertices!(
	vec2!float, "Position"
	, vec2!float, "UV"
	, vec4!float, "Color"
	)(true);
	guiRenderer.mesh2vertexArray(guiVertices);
	}
    //renderer.CreateDeviceObjects(gui.vertexSize, gui.uvOffset, gui.colorOffset);
    // setup font
    {
	ubyte* pixels;
	int width, height;
	gui.getTexDataAsRGBA32(&pixels, &width, &height);

	guiRenderer.m_texture=new glutil.Texture();
	guiRenderer.m_texture.loadImageRGBA(width, height, pixels);
	gui.setTextureID(cast(void*)guiRenderer.m_texture.m_texture);
    }
	+/

    // opengl
    auto scope renderer=new Renderer();
    renderer.CreateDeviceObjects(gui.vertexSize, gui.uvOffset, gui.colorOffset);
    // setup font
	auto texture=new glutil.Texture();
   

    ubyte* pixels;
    int width, height;
    gui.getTexDataAsRGBA32(&pixels, &width, &height);
    //auto textureId=renderer.CreateFonts(pixels, width, height);
	texture.loadImageRGBA(pixels, width, height);
    gui.setTextureID(cast(void*)texture.get());
    

	// main loop
	auto clock=new FpsClock!30;
	auto rotator=new scene.Rotator();
	while (true)
	{	
		// update
		auto duration=clock.newFrame();
		auto delta=duration.total!"msecs" * 0.001;

		if(!glfw.loop()){
			break;
		}
        // update WindowContext
        glfw.updateContext(windowContext, mouseContext);

		// gui
		gui.newFrame(delta, windowContext, mouseContext);
		glfw.setMouseCursor(mouseContext.enableCursor);
		build(data);

		rotator.update(delta);
		renderPass.setFrameSize(windowContext.frame_w, windowContext.frame_h);
		renderPass.m_program.setUniform("uRotationMatrix", mat4!float.identity);

		// draw
		renderPass.clear();
		renderPass.draw(vertices.vertexCount, null);
		gui.renderDrawLists(renderer);

		// present
		glfw.flush();

		// wait
		clock.waitNextFrame();
	}
}
