
** Use on 'AppModule' classes to define other modules to be loaded. 
** 
** pre>
**   syntax: fantom
**   @SubModule { modules=[AnotherModule#] }
**   const class MainModule {
**     ...
**   }
** <pre
** 
** Note all class modules need to be const.
@Js
facet class SubModule {
	
	** A list of additional modules to be loaded.
	const Type[] modules
}
