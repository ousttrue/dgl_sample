import glfw;
import gfm.math;
import guirenderer;
import fpsclock;
static import gui;
static import glutil;
static import scene;
static import shader.simple;
static import shader.circle;
static import shader.imgui;
import teapot;


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
    version(Windows){
		if(!glfw.createWindow(4, 5)){
			return;
		}
    }
	else{
		if(!glfw.createWindow(3, 3)){
			return;
		}
	}

	// gl
	auto gl=new glutil.OpenGL();

	// 3D renderer
	auto program=glutil.ShaderProgram.createShader!(shader.simple)();
	if(!program){
		return;
	}
	auto teapot=loadTeapot(0.2f);
    auto indices=new ushort[teapot.Vertices.length];
	foreach(i, v; teapot.Vertices)
	{
		indices[i]=cast(ushort)i;
	}

	auto mesh=program.mesh2vertexArray(teapot.Vertices, indices);

	// gui
	gui.WindowContext windowContext;
	gui.MouseContext mouseContext;

    // guiの変数
    GuiData data;
    data.show_test_window=true;
    data.show_another_window=false;
    data.clear_color=[0.3f, 0.4f, 0.8f];

    // opengl
    auto scope renderer=GuiRenderer.Create();
	if(!renderer){
		return;
	}

    // setup font
	auto texture=new glutil.Texture();
    ubyte* pixels;
    int width, height;
    gui.getTexDataAsRGBA32(&pixels, &width, &height);
	texture.loadImageRGBA(pixels, width, height);
    gui.setTextureID(cast(void*)texture.get());   

	// main loop
	auto clock=new FpsClock!30;
	auto rotator=new scene.Rotator();
	while (true)
	{	
		// new frame
		auto duration=clock.newFrame();
		auto delta=duration.total!"msecs" * 0.001;

        // update WindowContext
		if(!glfw.loop()){
			break;
		}
        glfw.updateContext(windowContext, mouseContext);

		// update gui
		gui.newFrame(delta, windowContext, mouseContext);
		build(data);
		// update scene
		rotator.update(delta);

		// clear
		glutil.setViewport(0, 0, windowContext.frame_w, windowContext.frame_h);
		glutil.clear(data.clear_color[0], data.clear_color[1], data.clear_color[2], 1.0f);
		// draw triangle
		program.use();
		program.setUniform("uRotationMatrix", mat4!float.identity);
		mesh.bind();
		mesh.draw(cast(int)teapot.Vertices.length, null);
		// draw gui
		gui.renderDrawLists(renderer);

		// update cursor
		glfw.setMouseCursor(mouseContext.enableCursor);
		// present
		glfw.flush();
		// wait
		clock.waitNextFrame();
	}
}
