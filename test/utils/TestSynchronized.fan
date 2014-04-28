
internal class TestSynchronized : IocTest {
	
	Void testNestedSync() {
		verifyErrMsg(IocMessages.synchronized_nestedNotAllowed) {
			T_Sync().sync			
		}
	}

	Void testNestedSyncAndForget() {
		verifyErrMsg(IocMessages.synchronized_nestedNotAllowed) {
			T_Sync().syncForget			
		}
	}
}

internal const class T_Sync : Synchronized {
	new make() : super() { }
	
	Void sync() {
		synchronized |->| { nested }
	}

	Void syncForget() {
		syncAndForget |->| { nested }
	}

	Void nested() {
		synchronized |->| { null?.toStr }		
	}
}