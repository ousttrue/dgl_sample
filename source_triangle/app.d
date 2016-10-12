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


class Rotator
{
	import core.time;

    float m_angle=0;
    float m_angleVelocity=radians!float(180);

    mat4!float update(Duration delta)
    {
        m_angle+=delta.total!"msecs" * 0.001f * m_angleVelocity;
        return mat4!float.rotateZ(m_angle);
    }

	void update(Model m, Duration d)
	{
		m.Uniform.uModelMatrix=update(d);	
	}
}


void Setup(SceneRenderer sceneRenderer)
{
	auto teapot=loadTeapot(0.2f);
    auto indices=new ushort[teapot.Vertices.length];
	foreach(i, v; teapot.Vertices)
	{
		indices[i]=cast(ushort)i;
	}
    auto model=sceneRenderer.addModel(teapot.Vertices, indices);

	auto r=new Rotator();
	/*
	model.connect((m, d){
		m.Uniform.uModelMatrix=r.update(d);	
	});
	*/
	model.connect(&r.update);
}


void main()
{
    ////////////////////
    // window
    ////////////////////
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


    ////////////////////
	// main loop
    ////////////////////
	auto clock=new FpsClock!30;
	gui.WindowContext windowContext;
	gui.MouseContext mouseContext;
	while (true)
	{	
		// new frame
		auto delta=clock.newFrame();

        // update WindowContext
		if(!glfw.loop()){
			break;
		}
        glfw.updateContext(windowContext, mouseContext);

		// update gui
		gui.newFrame(delta, windowContext, mouseContext);
		guidefine.build(sceneRenderer.Settings);
		// update scene
		sceneRenderer.update(delta);

		// clear
		glutil.setViewport(0, 0, windowContext.frame_w, windowContext.frame_h);

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
