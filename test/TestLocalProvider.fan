using concurrent
using afConcurrent

internal class TestLocalProvider : IocTest {

	Void testInjection() {
		reg := RegistryBuilder().build.startup
		s96 := (T_MyService96) reg.autobuild(T_MyService96#)
		
		s96.localRef.val = 6
		s96.localList.add(6)
		s96.localMap[6] = 9
		
		verifyEq(s96.localRef.val, 6)
		verifyEq(s96.localList[0], 6)
		verifyEq(s96.localMap [6], 9)

		verify(s96          .localRef.qname.endsWith(".afIoc.T_MyService96.localRef" ))
		verify(s96.localList.localRef.qname.endsWith(".afIoc.T_MyService96.localList"))
		verify(s96.localMap .localRef.qname.endsWith(".afIoc.T_MyService96.localMap" ))

		verify(Actor.locals.containsKey(s96			 .localRef.qname))
		verify(Actor.locals.containsKey(s96.localList.localRef.qname))
		verify(Actor.locals.containsKey(s96.localMap .localRef.qname))

		// ensure the stash was created by the manager so it gets cleaned up
		(reg.dependencyByType(ThreadLocalManager#) as ThreadLocalManager).cleanUpThread
		verifyFalse(Actor.locals.containsKey(s96		  .localRef.qname))
		verifyFalse(Actor.locals.containsKey(s96.localList.localRef.qname))
		verifyFalse(Actor.locals.containsKey(s96.localMap .localRef.qname))
		
		// test list / map types
		verifyEq(s96.paramList.list.typeof.params["V"], Int?#)

		verifyEq(s96.caseInsenMap.map.typeof.params["K"], Str#)
		verifyEq(s96.caseInsenMap.map.typeof.params["V"], Int#)
		verifyEq(s96.caseInsenMap.map.caseInsensitive, true)
		verifyEq(s96.caseInsenMap.map.ordered, false)
		
		verifyEq(s96.orderedMap.map.typeof.params["K"], Int#)
		verifyEq(s96.orderedMap.map.typeof.params["V"], Str#)
		verifyEq(s96.orderedMap.map.caseInsensitive, false)
		verifyEq(s96.orderedMap.map.ordered, true)
	}
	
	Void testErrMsgs() {
		reg := RegistryBuilder().build.startup
		
		verifyIocErrMsg(IocMessages.localProvider_typeNotList(T_MyService103#oopsList, Str#)) {
			reg.autobuild(T_MyService103#)			
		}

		verifyIocErrMsg(IocMessages.localProvider_typeNotMap(T_MyService104#oopsMap, Str#)) {
			reg.autobuild(T_MyService104#)			
		}
	}
}

internal class T_MyService96 {
	@Inject LocalRef? 	localRef
	@Inject LocalList?	localList
	@Inject LocalMap? 	localMap

	@Inject { type=Int?[]# }
	LocalList?	paramList

	@Inject { type=[Str:Int]# }
	LocalMap? 	caseInsenMap

	@Inject { type=[Int:Str]# }
	LocalMap? 	orderedMap
}

internal class T_MyService103 {
	@Inject { type=Str# }
	LocalList?	oopsList
}

internal class T_MyService104 {
	@Inject { type=Str# }
	LocalMap? 	oopsMap
}
