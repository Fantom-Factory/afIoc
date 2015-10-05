
** Use on 'AppModule' classes to define other modules to be loaded. Example
** 
** pre>
**   syntax: fantom
**   @SubModule { modules=[AnotherModule#] }
**   class MainModule {
**     ...
**   }
** <pre
@Js
facet class SubModule {
	
	** A list of additional modules to be loaded.
	const Type[] modules
}
