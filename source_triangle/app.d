import glfw;
import gfm.math;
import core.thread;
static import glutil;
static import scene;
static import simple_shader;
static import circle_shader;


void main()
{
    // window
    auto glfw=new GLFW();
    if(!glfw.createWindow(4, 5)){
        return;
    }

	auto gl=new glutil.OpenGL();

	auto renderPass=new glutil.RenderPass();
	if(!renderPass.createShader!(simple_shader)())
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

	auto vertexArray=renderPass.mesh2vertexArray(vertices);

	// main loop
	auto last_time=MonoTime.currTime;
	auto rotator=new scene.Rotator();
	while (glfw.loop())
	{	
		// update
		auto current_time =  MonoTime.currTime;
		auto size=glfw.getSize();
		auto windowSize=glfw.getWindowSize();
		auto pos=glfw.getCursorPos();
		auto delta=(current_time-last_time).total!"msecs" * 0.001;
		last_time=current_time;
		rotator.update(delta);
		renderPass.setFrameSize(size[0], size[1]);
		renderPass.m_program.setUniform("uRotationMatrix", mat4!float.identity);

		// draw
		renderPass.draw(vertexArray);

		/*
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
		*/

		// present
		glfw.flush();

		Thread.sleep( dur!("msecs")( 16 ) );
	}
}
