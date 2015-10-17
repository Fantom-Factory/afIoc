    using afIoc
    
    // ---- Services are plain Fantom classes -------------------------------------
    
    const class DinnerMenu {
        
        @Inject
        const ChefsSpecials chefsSpecials
        
        const Str[] dishes
        
        new make(Str[] dishes, |This| in) {
            in(this)  // this it-block performs the actual injection
            this.dishes = dishes
        }
        
        Void printMenu() {
            echo("\nDinner Menu:")
            dishes.rw.addAll(chefsSpecials.dishes).each { echo(it) }
        }
    }
    
    const class ChefsSpecials {
        const Str[] dishes := ["Lobster Thermadore"]
    }
    
    
    
    // ---- Every IoC application / library should have an AppModule --------------
    
    ** This is the central place where services are defined and configured
    const class AppModule {
        Void defineServices(RegistryBuilder bob) {
            bob.addService(DinnerMenu#).withRootScope
            bob.addService(ChefsSpecials#).withRootScope
        }
        
        @Contribute { serviceType=DinnerMenu# }
        Void contributeDinnerMenu(Configuration config) {
            config.add("Fish'n'Chips")
            config.add("Pie'n'Mash")
        }
    }
    
    
    
    // ---- Use the IoC Registry to access the services ---------------------------
    
    class Main {
        Void main() {
            // create the registry, passing in our module 
            registry := RegistryBuilder().addModule(AppModule#).build()
            scope    := registry.rootScope
    
            // different ways to access services
            menu1 := (DinnerMenu) scope.serviceById("Example_0::DinnerMenu")  // returns a service instance
            menu2 := (DinnerMenu) scope.serviceByType(DinnerMenu#)            // returns the same instance
            menu3 := (DinnerMenu) scope.build(DinnerMenu#, [["Beef Stew"]])   // build a new instance
    
            // print menus
            menu1.printMenu()
            menu2.printMenu()
            menu3.printMenu()
    
            // clean up
            registry.shutdown()
        }
    }
    