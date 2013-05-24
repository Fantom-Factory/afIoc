# afIoc

An Inversion of Control (IoC) container for the [Fantom](http://fantom.org/) language, based on the most excellent [Tapestry 5 IoC](http://tapestry.apache.org/ioc.html). 

## Usage

    registry := IocService([MyModule#]).start.registry

    test1 := (MyService1) registry.serviceById("myservice1")
    test2 := (MyService1) registry.dependencyByType(MyService1#)
    test3 := (MyService1) registry.autobuild(MyService1#)
    test4 := (MyService1) registry.injectIntoFields(MyService1())

    test1.service2.kick	// --> Ass!
    test2.service2.kick	// --> Ass!
    test3.service2.kick	// --> Ass!
    test4.service2.kick	// --> Ass!
    
    Service.find(IocService#).uninstall

## Documentation

Full API & fandocs are available on the [status302 repository](http://repo.status302.com/doc/afIoc/).

A usage overview is available on the [wiki](https://bitbucket.org/SlimerDude/afioc/wiki/Home).. 

## Install

    fanr install -r http://repo.status302.com/fanr/ afIoc
