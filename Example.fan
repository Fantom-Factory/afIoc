using afIoc

// ---- Services are plain Fantom classes -------------------------------------

** A reusable piece of code
class PokerService {
    Void poke() { echo("Poking ${this.toStr}") }
}

** PokerService is reused here
class MyService {
    ** Inject services into services!
    @Inject PokerService? poker
}



// ---- Modules - every IoC application / library needs one -------------------

** This is the central place where services are defined and configured
class MyModule {
    static Void defineServices(ServiceDefinitions defs) {
        defs.add(MyService#)
        defs.add(PokerService#)
    }
}



// ---- Use the IoC Registry to access the services ---------------------------

class Main {
    Void main() {
		// create the registry, passing in our module 
        registry := RegistryBuilder().addModule(MyModule#).build().startup()

		// different ways to access services
        test1 := (MyService) registry.serviceById("myService")       // returns a service instance
        test2 := (MyService) registry.dependencyByType(MyService#)   // returns the same instance
        test3 := (MyService) registry.autobuild(MyService#)          // build a new instance
        test4 := (MyService) registry.injectIntoFields(MyService())  // inject into existing objects

        // all test classes poke the same instance of Service2
        test1.poker.poke()
        test2.poker.poke()
        test3.poker.poke()
        test4.poker.poke()

		// clean up
        registry.shutdown()
    }
}
