
@Js
internal class TestOrderer : IocTest {
	
	Void testIdMustBeUnique() {
		orderer := Orderer()
		orderer.addOrdered("unique", 69, null, null)
		verifyIocErrMsg(ErrMsgs.orderer_configKeyAlreadyAdded("unique")) {
			orderer.addOrdered("  UniQUe  ", 69, null, null)
		}
	}
	
	Void testBeforeAndAfter() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", null, ["1"])
		orderer.addOrdered("1", "1", ["2"], null)
		nodes := orderer.order
		verifyEq(nodes.map { it.name }, Obj?["1", "2"])
		assertOrder(nodes)
	}
	
	Void testBeforeAndAfterAreCaseInsensitive() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", null, ["1"])
		orderer.addOrdered("1", "1", ["2"], null)
		nodes := orderer.order
		verifyEq(nodes.map { it.name }, Obj?["1", "2"])
		assertOrder(nodes)
	}
	
	Void testPlaceholdersNotAllowed1() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", null, ["1"])
		orderer.addOrdered("1", "1", ["2", "3"], null)
		verifyIocErrMsg(ErrMsgs.orderer_configIsPlaceholder("3")) {
			orderer.toOrderedList
		}
	}

	Void testPlaceholdersNotAllowed2() {
		orderer := Orderer()
		orderer.addOrdered("2", "2", null, ["1", "3"])
		orderer.addOrdered("1", "1", ["2"], null)
		verifyIocErrMsg(ErrMsgs.orderer_configIsPlaceholder("3")) {
			orderer.toOrderedList
		}
	}

	Void testPlaceholdersAllowed() {
		orderer := Orderer()
		orderer.addPlaceholder("filters", null, null)
		orderer.addOrdered("69", 69, ["filters"], null)
		list := orderer.toOrderedList
		verifyEq(list, Obj?[69])
	}

	Void testFilterBug() {
		orderer := Orderer()
		orderer.addOrdered("IeAjaxCacheBustingFilter", 	"IeAjaxCacheBustingFilter", null, ["BedSheetFilters"])
		orderer.addOrdered("HttpCleanupFilter", 		"HttpCleanupFilter", 		["BedSheetFilters", "HttpErrFilter"], null)
		orderer.addOrdered("HttpErrFilter", 			"HttpErrFilter", 			["BedSheetFilters"], null)
		orderer.addPlaceholder("BedSheetFilters", null, null)
		list := orderer.toOrderedList
		verifyEq(list, Obj?[,].addAll("HttpCleanupFilter HttpErrFilter IeAjaxCacheBustingFilter".split))
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
