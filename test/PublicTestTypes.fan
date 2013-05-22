
** Bugger, I've got test classes that need to be public!
internal const class PublicTestTypes {
	static const PublicTestTypes instance := PublicTestTypes()
	static Type type(Str typeName) { instance.pod.type(typeName) }
	
	const Str fantomPodCode := 
Str<|
     using afIoc

     mixin T_MyService10 { }
     class T_MyService10Impl : T_MyService10 { }

     mixin T_MyService31 { }
     class T_MyService31Impl : T_MyService31 {
         new make(DependencyProvider[] config) { }
     }

     const mixin T_MyService32 {
          abstract Str wotcha()
     }
     const class T_MyService32Impl1 : T_MyService32 {
         override const Str wotcha := "Go1"
     }
     const class T_MyService32Impl2 : T_MyService32 {
         override const Str wotcha := "Go2"
     }

     const mixin T_MyService50 {
          abstract Str dude()
          abstract Int inc(Int i)
     }
     const class T_MyService50Impl : T_MyService50 {
          override Str dude() { "dude"; }
          override Int inc(Int i) { i + 1 }
     }
     
     const mixin T_MyService51 {
          Str dude() { "Don't override me!" }
          virtual Int inc(Int i) { i + 3 }
     }
     const class T_MyService51Impl : T_MyService51 { }
     
     const mixin T_MyService52 {
          virtual Str dude() { "Virtual Reality" }
          abstract Int inc(Int i)
     }
     const class T_MyService52Impl : T_MyService52 {
          override Int inc(Int i) { i - 1 }
     }     

     const mixin T_MyService54 {
          protected abstract Str dude()
     }
     const class T_MyService54Impl : T_MyService54 {
          override Str dude() { "dude"; }
     }   

     internal const mixin T_MyService55 {
          abstract Str dude()
     }
     internal const class T_MyService55Impl : T_MyService55 {
          override Str dude() { "dude"; }
     }   

     mixin T_MyService56 { }
     class T_MyService56Impl : T_MyService56 { }

     class T_MyService57 { }

	|>
	
	private const Pod pod := PlasticPodCompiler().compile(OpTracker(), fantomPodCode)
}
