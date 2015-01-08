using afIoc

class Main {
  Void main() {
    registry := RegistryBuilder().addModule(MyModule#).build().startup()

    test1 := (MyService1) registry.serviceById("myservice1")        // returns a singleton
    test2 := (MyService1) registry.dependencyByType(MyService1#)    // returns the same singleton
    test3 := (MyService1) registry.autobuild(MyService1#)           // build a new instance
    test4 := (MyService1) registry.injectIntoFields(MyService1())   // inject into existing Objs

    test1.service2.kick  // --> Ass!
    test2.service2.kick  // --> Ass!
    test3.service2.kick  // --> Ass!
    test4.service2.kick  // --> Ass!

    registry.shutdown()
  }
}

class MyModule {              // every application needs a module class
  static Void defineServices(ServiceDefinitions defs) {
    defs.add(MyService1#)  // define your services here
    defs.add(MyService2#)
  }
}

class MyService1 {
  @Inject               // you'll use @Inject all the time
  MyService2? service2  // inject services into services!
}

class MyService2 {
  Str kick() { return "Ass!" }
}