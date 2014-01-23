
internal class TestTypeCoercer : IocTest {
	
	Void testCoerce() {
		tc := TypeCoercer()

		// same obj
		verifyEq(tc.coerce(69, Num#), 69)
		verifyEq(tc.coerce(69f, Num#), 69f)

		// toXXX()
		verifyEq(tc.coerce(69, Str#), "69")
		verifyEq(tc.coerce(69f, Str#), "69.0")
		verifyEq(tc.coerce("69", Int#), 69)
		verifyEq(tc.coerce(`69`, File#), `69`.toFile)

		// fromXXX()
		verifyEq(tc.coerce("2000-01-01T00:00:00Z UTC", DateTime#), DateTime.defVal)
		
		// no coersion
		verifyErrMsg(IocMessages.typeCoercionNotFound(TestTypeCoercer#, Int#)) {
			tc.coerce(this, Int#)
		}
		
		// test cache doesn't fail conversion
		verifyEq(tc.coerce(69, Str#), "69")
		verifyEq(tc.coerce("2000-01-01T00:00:00Z UTC", DateTime#), DateTime.defVal)		
	}
	
	Void testCanCoerce() {
		tc := TypeCoercer()
		
		verify     (tc.canCoerce(Str#, Int#))
		verifyFalse(tc.canCoerce(IocTest#, Int#))
		
		// test cache 
		verify     (tc.canCoerce(Str#, Int#))
		verifyFalse(tc.canCoerce(IocTest#, Int#))
	}

	Void testCanCoerceLists() {
		tc := TypeCoercer()
		
		verify     (tc.canCoerce(Str[]#, Int[]#))
		verifyFalse(tc.canCoerce(IocTest[]#, Int[]#))
		
		// test cache 
		verify     (tc.canCoerce(Str[]#, Int[]#))
		verifyFalse(tc.canCoerce(IocTest[]#, Int[]#))
	}

	Void testCoerceLists() {
		tc := TypeCoercer()

		// same obj
		verifyEq(tc.coerce([69], Int[]#), [69])
		verifyEq(tc.coerce([69f], Float[]#), [69f])

		// toXXX()
		verifyEq(tc.coerce([69, 42], Str[]#), ["69", "42"])
		verifyEq(tc.coerce([69f, 42f], Str[]#), ["69.0", "42.0"])
		verifyEq(tc.coerce(["69", "42"], Int[]#), [69, 42])
		verifyEq(tc.coerce([`69`, `42`], File[]#), [`69`.toFile, `42`.toFile])

		// no coersion
		verifyErrMsg(IocMessages.typeCoercionNotFound(TestTypeCoercer#, Int#)) {
			tc.coerce([this], Int[]#)
		}
		
		// test cache doesn't fail conversion
		verifyEq(tc.coerce([69, 42], Str[]#), ["69", "42"])
		verifyEq(tc.coerce(["69", "42"], Int[]#), [69, 42])
	}
	
	Void testCoerceEmptyLists() {
		tc := TypeCoercer()

		verifyEq(tc.coerce(Int[,], Str[]#), Str[,])
		verifyEq(tc.coerce(Obj[,], Str[]#), Str[,])
		verifyEq(tc.coerce(Int[,], Obj[]#), Obj[,])
	}

}
