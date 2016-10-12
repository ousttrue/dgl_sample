import std.typecons;
import std.traits;
import derelict.imgui.imgui;



struct RGB
{
	float R=0;
	float G=0;
	float B=0;
};


// inspector...
bool show_test_window;
bool show_another_window;
float[3] clear_color;


void build(string name, ref RGB value)
{
	float[3] vec;
	vec[0]=value.R;
	vec[1]=value.G;
	vec[2]=value.B;
	igColorEditMode(ImGuiColorEditMode_RGB);
	igColorEdit3(name.ptr, vec);
	value.R=vec[0];
	value.G=vec[1];
	value.B=vec[2];
}


void build(T)(ref T t)
{
	alias names=FieldNameTuple!T;
	foreach(i, name; names)
	{
		build(name, t.tupleof[i]);
	}
}


void build()
{
	import derelict.imgui.imgui;

    // 1. Show a simple window
    // Tip: if we don't call ImGui::Begin()/ImGui::End() the widgets appears in a window automatically called "Debug"
    {
        static float f = 0.0f;
        igText("Hello, world!");
        igSliderFloat("float", &f, 0.0f, 1.0f);
        igColorEdit3("clear color", clear_color);
        if (igButton("Test Window")){
			show_test_window ^= 1;
		}
        if (igButton("Another Window")){
			show_another_window ^= 1;
		}
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


