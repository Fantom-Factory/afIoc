
internal class TestOrderedConfigOrdering : IocTest {
	
	Void testIdMustBeUnique() {
		orderer := Orderer()
		orderer.addOrdered("unique", 69)
		verifyErrMsg(IocMessages.configKeyAlreadyAdded("unique")) {
			orderer.addOrdered("unique", 69)
		}
	}

	Void testBadPrefix() {
		orderer := Orderer()
		verifyErrMsg(IocMessages.configBadPrefix("BAD: id")) {
			orderer.addOrdered("wotever", 69, "BAD: id")			
		}
	}
	
	Void testPrefixes() {
		verifyEq(Str#.emptyList, Str[,])
		
		assertList("b4", "after", Str[,])
		assertList("b4", "b4", Str[,])
		assertList("b4", "b4dude", Str["dude"])
		assertList("b4", "b4 dude", Str["dude"])
		assertList("b4", "b4: dude", Str["dude"])
		assertList("b4", "b4- dude", Str["dude"])
		assertList("b4", "b5- dude1, dude2", Str[,])
	}
	
	Void testBeforeAndAfter() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", "after 1")
		orderer.addOrdered("1", "1", "before 2")
		nodes := orderer.order
		verifyEq(nodes.map { it.name }, Obj?["1", "2"])
		assertOrder(nodes)
	}
	
	Void testBeforeAndAfterAreCaseInsensitive() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", "aFtEr 1")
		orderer.addOrdered("1", "1", "BeFoRe: 2")
		nodes := orderer.order
		verifyEq(nodes.map { it.name }, Obj?["1", "2"])
		assertOrder(nodes)
	}
	
	Void testPlaceholdersNotAllowed1() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", "after 1")
		orderer.addOrdered("1", "1", "before 2, before 3")
		verifyErrMsg(IocMessages.configIsPlaceholder("3")) {
			orderer.toOrderedList
		}
	}

	Void testPlaceholdersNotAllowed2() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", "after 1, after 3")
		orderer.addOrdered("1", "1", "before 2")
		verifyErrMsg(IocMessages.configIsPlaceholder("3")) {
			orderer.toOrderedList
		}
	}

	Void testPlaceholdersAllowed() {
		orderer := Orderer()
		orderer.addPlaceholder("filters")
		orderer.addOrdered("69", 69, "before: filters")
		list := orderer.toOrderedList
		verifyEq(list, Obj?[69])
	}

	Void testFilterBug() {
		orderer := Orderer()
		orderer.addOrdered("IeAjaxCacheBustingFilter", 	"IeAjaxCacheBustingFilter", "after: BedSheetFilters")
		orderer.addOrdered("HttpCleanupFilter", 		"HttpCleanupFilter", 		"before: BedSheetFilters, before: HttpErrFilter")
		orderer.addOrdered("HttpErrFilter", 			"HttpErrFilter", 			"before: BedSheetFilters")
		orderer.addPlaceholder("BedSheetFilters")
		list := orderer.toOrderedList
		verifyEq(list, Obj?[,].addAll("HttpCleanupFilter HttpErrFilter IeAjaxCacheBustingFilter".split))
	}
	
	Void assertList(Str prefix, Str constraint, Str[] ids) {
		orderer := Orderer()
		list := Str[,]
		orderer.eachConstraint(prefix, constraint) |id| {
			list.add(id)
		}
		verifyEq(list, ids)
	}
	
	internal Void assertOrder(OrderedNode[] nodes) {
		nodes.each |n, i| {
			n.isBefore.each |depName| {
				dep := nodes.find { it.name == depName }
				verify(i < nodes.index(dep)) 
			}
		}
	}
}
