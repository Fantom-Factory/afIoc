using afIoc

// ---- Services are plain Fantom classes -------------------------------------

class MyService1 {
    ** Inject services into services!
    @Inject MyService2? service2
}

class MyService2 {
    Void poke() { echo("Poking ${this.toStr}") }
}



// ---- Modules are where services are defined and configured -----------------

** Every application needs a module class
class MyModule {
    static Void defineServices(ServiceDefinitions defs) {
        defs.add(MyService1#)
        defs.add(MyService2#)
    }
}



// ---- Build and start the IoC Registry --------------------------------------

class Main {
    Void main() {
        registry := RegistryBuilder().addModule(MyModule#).build().startup()

        test1 := (MyService1) registry.serviceById("myservice1")       // returns a singleton
        test2 := (MyService1) registry.dependencyByType(MyService1#)   // returns the same singleton
        test3 := (MyService1) registry.autobuild(MyService1#)          // build a new instance
        test4 := (MyService1) registry.injectIntoFields(MyService1())  // inject into existing Objs

        // all test classes poke the same instantce of Service2
        test1.service2.poke
        test2.service2.poke
        test3.service2.poke
        test4.service2.poke

        registry.shutdown()
    }
}