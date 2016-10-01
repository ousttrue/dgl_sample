class FpsClock(int Target, int MarginMsecs = 5)
{
	import std.datetime;
	SysTime m_lastTime;

	static immutable Duration frameDuration=dur!"msecs"(1000/Target - MarginMsecs);

	this()
	{
		m_lastTime=Clock.currTime;
	}

	Duration newFrame()
	{
		auto now=Clock.currTime;
		auto duration=now-m_lastTime;
		m_lastTime=now;
		return duration;
	}

	void waitNextFrame()
	{
		import core.thread;

		auto now=Clock.currTime;
		auto delta=now-m_lastTime;
		if(delta < frameDuration)
		{
			auto wait=frameDuration-delta;
			Thread.sleep(wait);
		}
	}
}

