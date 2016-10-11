import glfw;
import gfm.math;
import fpsclock;

static import glutil;
static import scene;
import scenerenderer;

static import shader.simple;
static import shader.circle;
import teapot;

static import gui;
static import guidefine;
import guirenderer;


void Setup(SceneRenderer sceneRenderer)
{
	auto teapot=loadTeapot(0.2f);
    auto indices=new ushort[teapot.Vertices.length];
	foreach(i, v; teapot.Vertices)
	{
		indices[i]=cast(ushort)i;
	}
    sceneRenderer.addModel(teapot.Vertices, indices);
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

	// reload context
	glutil.Initialize();

    ////////////////////
    // scene
    ////////////////////
    auto scope sceneRenderer=SceneRenderer.create!(shader.simple);
    if(!sceneRenderer)
    {
        return;
    }
    sceneRenderer.Setup();

    ////////////////////
	// gui
    ////////////////////
    guidefine.show_test_window=true;
    guidefine.show_another_window=false;
    guidefine.clear_color=[0.3f, 0.4f, 0.8f];
    auto scope guiRenderer=GuiRenderer.Create();
	if(!guiRenderer){
		return;
	}

	// main loop
	auto clock=new FpsClock!30;
	auto rotator=new scene.Rotator();
	gui.WindowContext windowContext;
	gui.MouseContext mouseContext;
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
		guidefine.build();
		// update scene
		rotator.update(delta);

		// clear
		glutil.setViewport(0, 0, windowContext.frame_w, windowContext.frame_h);
		glutil.clear(guidefine.clear_color[0], guidefine.clear_color[1], guidefine.clear_color[2], 1.0f);

		// draw triangle
        sceneRenderer.draw();
		// draw gui
		gui.renderDrawLists(guiRenderer);

		// update cursor
		glfw.setMouseCursor(mouseContext.enableCursor);
		// present
		glfw.flush();
		// wait
		clock.waitNextFrame();
	}
}

