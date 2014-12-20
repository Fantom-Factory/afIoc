
internal class TestIocErr : IocTest {
	
	Void testOperationTrace() {
		err := IocErr("Emma", Err(), "I\nSee\nBoobies")
		toStr := "sys::Err: Emma\nIoc Operation Trace:\n  [ 1] I\n  [ 2] See\n  [ 3] Boobies\nStack Trace:"

		verifyEq(err.toStr, toStr)
		verify  (err.traceToStr.startsWith(toStr + "\n  afIoc::TestIocErr"))
		verifyEq(err.operationTrace, "I\nSee\nBoobies")
		
//		Env.cur.err.printLine(err.traceToStr)
	}
}
