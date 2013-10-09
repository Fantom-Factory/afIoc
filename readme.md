# afIoc

An Inversion of Control (IoC) container and Dependency Injection (DI) framework for the [Fantom](http://fantom.org/) language, based on the most excellent [Tapestry 5 IoC](http://tapestry.apache.org/ioc.html). 

Like [Guice](http://code.google.com/p/google-guice/)? Know [Spring](http://www.springsource.org/spring-framework)? Then you'll love afIoc!

## Usage

    registry := IocService([MyModule#]).start.registry

    test1 := (MyService1) registry.serviceById("myservice1")
    test2 := (MyService1) registry.dependencyByType(MyService1#)
    test3 := (MyService1) registry.autobuild(MyService1#)
    test4 := (MyService1) registry.injectIntoFields(MyService1())

    Service.find(IocService#).uninstall

## Documentation

Full API & fandocs are available on the [status302 repository](http://repo.status302.com/doc/afIoc/#overview).

A usage overview is available on the [wiki](https://bitbucket.org/SlimerDude/afioc/wiki/Home).. 

## Install

Download from [status302](http://repo.status302.com/browse/afIoc).

Install via fanr:

    fanr install -r http://repo.status302.com/fanr/ afIoc

To use in a project, add a dependency in your `build.fan`:

    depends = ["sys 1.0", ..., "afIoc 1.4.6+"]
