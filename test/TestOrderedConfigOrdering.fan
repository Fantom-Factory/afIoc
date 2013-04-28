
class TestOrderedConfigOrdering : IocTest {
	
	Void testIdMustBeUnique() {
		orderer := Orderer()
		orderer.addOrdered("unique", 69)
		verifyErrMsg(IocMessages.configKeyAlreadyAdded("UniquE")) {
			orderer.addOrdered("UniquE", 69)
		}
	}

	Void testBadPrefix() {
		orderer := Orderer()
		verifyErrMsg(IocMessages.configBadPrefix("BAD: id")) {
			orderer.addOrdered("wotever", 69, ["BAD: id"])			
		}
	}
	
	Void testPrefixes() {
		verifyEq(Str#.emptyList, Str[,])
		
		assertList("b4", "after", Str[,])
		assertList("b4", "b4", Str[,])
		assertList("b4", "b4 dude", Str["dude"])
		assertList("b4", "b4: dude", Str["dude"])
		assertList("b4", "b4: dude1, dude2", Str["dude1", "dude2"])
		assertList("b4", "b4- dude1, dude2", Str["dude1", "dude2"])
		assertList("b4", "b5- dude1, dude2", Str[,])
	}
	
	Void testBeforeAndAfter() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", ["after 1"])
		orderer.addOrdered("1", "1", ["before 2"])
		nodes := orderer.order
		verifyEq(nodes.map { it.name }, Obj?["1", "2"])
		assertOrder(nodes)
	}
	
	Void testPlaceholdersNotAllowed1() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", ["after 1"])
		orderer.addOrdered("1", "1", ["before 2, 3"])
		verifyErrMsg(IocMessages.configIsPlaceholder("3")) {
			orderer.toOrderedList
		}
	}

	Void testPlaceholdersNotAllowed2() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", ["after 1, 3"])
		orderer.addOrdered("1", "1", ["before 2"])
		verifyErrMsg(IocMessages.configIsPlaceholder("3")) {
			orderer.toOrderedList
		}
	}
	
	Void assertList(Str prefix, Str constraint, Str[] ids) {
		orderer := Orderer()
		list := Str[,]
		orderer.eachId(prefix, constraint) |id| {
			list.add(id)
		}
		verifyEq(list, ids)
	}
	
	internal Void assertOrder(OrderedNode[] nodes) {
		nodes.each |n, i| {
			n.dependsOn.each |depName| {
				dep := nodes.find { it.name == depName }
				verify(i < nodes.index(dep)) 
			}
		}
	}
}
