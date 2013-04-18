# afIoc

An Inversion of Control (IoC) container for the [Fantom](http://fantom.org/) language, based on the most excellent [Tapestry 5 IoC](http://tapestry.apache.org/ioc.html). 

## Usage

    registry := IocService([MyModule#]).start.registry

    MyService1 test1 := registry.serviceById("myservice1")
    MyService1 test2 := registry.dependencyByType(MyService1#)
    MyService1 test3 := registry.autobuild(MyService1#)
    MyService1 test4 := registry.injectIntoFields(MyService1())

    Service.find(IocService#).uninstall    

## Documentation

Full API & fandocs are available on the [status302 repository](http://repo.status302.com/doc/afIoc/).

A usage overview is available on the [wiki](https://bitbucket.org/SlimerDude/afioc/wiki/Home).. 

## Install

    fanr install -r http://repo.status302.com/fanr/ afIoc
