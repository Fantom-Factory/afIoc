
class TestOrderer : IocTest {
	
	** See http://en.wikipedia.org/wiki/Directed_acyclic_graph
	Void testDag() {
		orderer := Orderer()
		
		// there is no 1, 4, 6
		addNode(orderer, "5")
		addNode(orderer, "7")
		addNode(orderer,"11", [ "5", "7"])
		addNode(orderer, "2", ["11"])
		addNode(orderer, "3")
		addNode(orderer,"10", ["11", "3"])
		addNode(orderer, "8", [ "7", "3"])
		addNode(orderer, "9", ["11", "8"])
		
		verifyOrder(orderer.order)
	}
	
	Void testOneOkay() {
		orderer := Orderer()
		addNode(orderer,"1")
		verifyOrder(orderer.order)		
	}

	Void testOneErr() {
		orderer := Orderer()
		addNode(orderer,"1", ["1"])
		verifyErrMsg(IocMessages.configRecursion(["1", "1"])) {
			orderer.order
		}
	}

	Void testTwoOkay() {
		orderer := Orderer()
		addNode(orderer,"1")
		addNode(orderer,"2", ["1"])
		verifyOrder(orderer.order)		
	}

	Void testTwoErr() {
		orderer := Orderer()
		addNode(orderer,"1", ["2"])
		addNode(orderer,"2", ["1"])
		verifyErrMsg(IocMessages.configRecursion(["2", "1", "2"])) {
			orderer.order
		}
	}
	
	Void testNoDag() {
		orderer := Orderer()
		addNode(orderer, "5")
		addNode(orderer, "7")
		addNode(orderer,"11", [ "5", "7"])
		addNode(orderer, "2", ["11"])
//		addNode(orderer, "3")
		addNode(orderer,"10", ["11", "3"])
		addNode(orderer, "8", [ "7", "3"])
		addNode(orderer, "9", ["11", "8"])
		// the cyclic dependency
		addNode(orderer, "3", ["9"])
		
		verifyErrMsg(IocMessages.configRecursion(["3", "9", "8", "3"])) {
			orderer.order
		}		
	}

	Void testPlaceholder() {
		orderer := Orderer()
		orderer.addOrdered("s1", "s1", ["after end"])
		orderer.addOrdered("s2", "s2", ["before end"])
		orderer.addPlaceholder("end")
		
		verifyEq(2, orderer.toOrderedList.size)
		verifyOrder(orderer.order)
	}

	Void testMapDup() {
		map := Str:Str[:] { caseInsensitive=true }
		map["DEE"] = "sigh"
		verifyEq(map["dee"], "sigh")
		
		// test caseInsensitivity is dup'ed
		map2 := map.dup
		verifyEq(map2["dee"], "sigh")
	}
	
	internal Void verifyOrder(OrderedNode[] nodes) {
		nodes.each |n, i| {
			n.dependsOn.each |depName| {
				dep := nodes.find { it.name == depName }
				verify(i < nodes.index(dep)) 
			}
		}
	}
	
	internal Void addNode(Orderer orderer, Str name, Str[] dependsOn := Str#.emptyList) {
		if (dependsOn.isEmpty)
			orderer.addOrdered(name, name)
		else
			orderer.addOrdered(name, name, ["after "+dependsOn.join(", ")])
	}	
}
