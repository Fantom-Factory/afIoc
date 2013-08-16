
internal class TestIocErr : IocTest {
	
	Void testOperationTrace() {
		err := IocErr("Emma", Err(), "I\nSee\nBoobies")
		toStr := "sys::Err: Emma\nOperations trace:\n  [ 1] I\n  [ 2] See\n  [ 3] Boobies\nStack trace:"

		verifyEq(err.toStr, toStr)
		verify  (err.traceToStr.startsWith(toStr + "\n  afIoc::TestIocErr"))
		verifyEq(err.operationTrace, "I\nSee\nBoobies")
		
//		Env.cur.err.printLine(err.traceToStr)
	}
}
