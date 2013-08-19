
internal class TestSrcErrLocation : PlasticTest {
	
	Void testSimple() {
		src := """l 1
		          l 2
		          l 3
		          l 4
		          l 5"""
		info := SrcErrLocation(``, src, 3, "")

		srcy := info.srcCodeSnippetMap(0)
		verifyEq(srcy.size, 1)
		verifyEq(srcy[3], "l 3")

		srcy = info.srcCodeSnippetMap(1)
		verifyEq(srcy.size, 3)
		verifyEq(srcy[2], "l 2")
		verifyEq(srcy[3], "l 3")
		verifyEq(srcy[4], "l 4")

		srcy = info.srcCodeSnippetMap(2)
		verifyEq(srcy.size, 5)
		verifyEq(srcy[1], "l 1")
		verifyEq(srcy[2], "l 2")
		verifyEq(srcy[3], "l 3")
		verifyEq(srcy[4], "l 4")
		verifyEq(srcy[5], "l 5")

		// test min / max limits
		srcy = info.srcCodeSnippetMap(20)
		verifyEq(srcy.size, 5)
		verifyEq(srcy[1], "l 1")
		verifyEq(srcy[2], "l 2")
		verifyEq(srcy[3], "l 3")
		verifyEq(srcy[4], "l 4")
		verifyEq(srcy[5], "l 5")
	}
	
	Void testTrim() {
		src := """ \t l 1
		           \t  l 2
		           \t   l 3
		           \t  l 4
		           \t l 5"""
		info := SrcErrLocation(``, src, 3, "")
		
		srcy := info.srcCodeSnippetMap(2)
		verifyEq(srcy.size, 5)
		verifyEq(srcy[1], "l 1")
		verifyEq(srcy[2], " l 2")
		verifyEq(srcy[3], "  l 3")
		verifyEq(srcy[4], " l 4")
		verifyEq(srcy[5], "l 5")
	}
}
