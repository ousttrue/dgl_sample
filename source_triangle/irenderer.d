

struct WindowContext
{
	int frame_w;
	int frame_h;
	int window_w;
	int window_h;
	bool hasFocus;
}

struct MouseContext
{
	double x;
	double y;
	bool enableCursor;
    bool[3] pressed;
    float wheel = 0.0f;
}

interface IRenderer
{
	void CreateDeviceObjects(uint vertexSize, uint uvOffset, uint colorOffset);
	void* CreateFonts(ubyte* pixels, int width, int height);
	nothrow void begin(float width, float height);
	nothrow void setVertices(void *vertices, int len);
	nothrow void setIndices(void *indices, int len);
	nothrow void draw(void* textureId
					  , int x, int y, int w, int h
					  , uint count, ushort* offset);
	nothrow void end();
}
