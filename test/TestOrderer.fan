
internal class TestOrderer : IocTest {
	
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
		verifyIocErrMsg(IocMessages.configRecursion(["1", "1"])) {
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
		verifyIocErrMsg(IocMessages.configRecursion(["1", "2", "1"])) {
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
		
		verifyIocErrMsg(IocMessages.configRecursion("10 3 9 8 3".split)) {
			orderer.order
		}		
	}

	Void testPlaceholder() {
		orderer := Orderer()
		orderer.addOrdered("s1", "s1", null, ["end"])
		orderer.addOrdered("s2", "s2", ["end"], null)
		orderer.addPlaceholder("end", null, null)
		
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

	Void testUnorderedOrder() {
		orderer := Orderer()
		orderer.addOrdered("Un2", 2, null, ["Un1"])
		orderer.addOrdered("Un6", 6, null, ["Un5"])
		orderer.addOrdered("Un3", 3, null, ["Un2"])
		orderer.addOrdered("Un7", 7, null, ["Un6"])
		orderer.addOrdered("Un4", 4, null, ["Un3"])
		orderer.addOrdered("Un1", 1, null, null)
		orderer.addOrdered("Un5", 5, null, ["Un4"])
		orderer.addOrdered("Un8", 8, null, ["Un7"])
		orderer.addOrdered("Un9", 9, null, ["Un8"])
		orderer.addOrdered("Un10", 10, null, ["Un9"])
		list := orderer.toOrderedList
		verifyEq(1, list[0])
		verifyEq(2, list[1])
		verifyEq(3, list[2])
		verifyEq(4, list[3])
		verifyEq(5, list[4])
		verifyEq(6, list[5])
		verifyEq(7, list[6])
		verifyEq(8, list[7])
		verifyEq(9, list[8])
		verifyEq(10, list[9])
	}

	internal Void verifyOrder(OrderedNode[] nodes) {
		nodes.each |n, i| {
			n.isBefore.each |depName| {
				dep := nodes.find { it.name == depName }
				verify(i < nodes.index(dep)) 
			}
		}
	}
	
	internal Void addNode(Orderer orderer, Str name, Str[] dependsOn := Str#.emptyList) {
		if (dependsOn.isEmpty)
			orderer.addOrdered(name, name, null, null)
		else
			orderer.addOrdered(name, name, null, dependsOn)
	}	
}
