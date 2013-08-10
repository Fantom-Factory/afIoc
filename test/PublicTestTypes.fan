
** Bugger, I've got test classes that need to be public!
internal const class PublicTestTypes {
	static const PublicTestTypes instance := PublicTestTypes()
	static Type type(Str typeName) { instance.pod.type(typeName) }
	
	const Str fantomPodCode := 
Str<|
     using afIoc
     using concurrent

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

     mixin T_MyService58 { 
         abstract Str dude
         abstract Int judge()
     }
     class T_MyService58Impl : T_MyService58 { 
         override Str dude := "Stella!"
         override Int judge := 69
     }

     const mixin T_MyService61 {
         abstract Void kickIn(Str k)
         abstract Str kickOut()
     }
     internal const class T_MyService61Impl : T_MyService61 {
         const concurrent::AtomicRef kick := concurrent::AtomicRef("dredd") 
         override Void kickIn(Str k) { kick.val = k}
         override Str kickOut() { kick.val } 
     }
     internal const class T_MyService62 {
         const T_MyService61 s61
         new make(T_MyService61 s61) { this.s61 = s61 }
     }

     mixin T_MyService65Aspect {
         abstract Str meth1()
     }
     class T_MyService65AspectImpl : T_MyService65Aspect {
         override Str meth1() { "dredd" }
     }
     mixin T_MyService66Aspect {
         abstract Str meth2()
     }
     class T_MyService66AspectImpl : T_MyService66Aspect {
         override Str meth2() { "anderson" }
     }
     mixin T_MyService67NoMatch {
         abstract Str meth3()
     }
     class T_MyService67NoMatchImpl : T_MyService67NoMatch {
         override Str meth3() { "death" }
     }

     // for pipeline builder test
     const mixin T_MyService75 {
     	abstract Bool service() 
     }     
     const mixin T_MyService76 {
     	abstract Bool service(T_MyService75 handler) 
     }
     const class T_MyService75Term : T_MyService75 {
     	const Str char
     	new make(Str char) { this.char = char }
     	override Bool service() {
     		Actor.locals["test"] = Actor.locals["test"].toStr + char
     		return true
     	}
     }
     const class T_MyService76Num : T_MyService76 {
     	const Str char
     	new make(Str char) { this.char = char }
     	override Bool service(T_MyService75 handler) {
     		Actor.locals["test"] = Actor.locals["test"].toStr + char
     		return handler.service()
     	}
     }

     const mixin T_MyService83 {
          abstract Str dude
          abstract Int inc(Int i)
     }
     const class T_MyService83Impl : T_MyService83 {
          override Str dude { get {"dude"} set { } }
          override Int inc(Int i) { i + 1 }
     }
          |>
	
	private const Pod pod := PlasticPodCompiler().compile(fantomPodCode)
}
