
** Use on 'AppModule' classes to define other modules to be loaded. Example
** 
** pre>
**   @SubModule { modules=[AnotherModule#] }
**   class MainModule {
**     ...
**   }
** <pre
facet class SubModule {
	
	** A list of additional modules to be loaded.
	const Type[] modules
}
