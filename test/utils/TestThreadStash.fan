
class TestThreadStash : Test {
	
	Void testDocumentation() {
		stash1 := ThreadStash("def")
		stash1["wot"] = "ever"
	 
		stash2 := ThreadStash("def")
		stash2["wot"] = "banana"

		verifyEq(stash1["wot"], "ever")
		
		stash1["ever"] = "apple"

		verifyEq(stash1.keys.sort, Str["wot", "ever"].sort)
		verifyEq(stash2.keys, Str["wot"])
	}
	
}
