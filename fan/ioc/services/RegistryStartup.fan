
** @Inject - 
** Executes a series of (user defined) operations when the `Registry` starts up. Operations are 
** defined by contributing listeners to the 'RegistryStartup' service. For example, add the 
** following to your module:
** 
**   @Contribute
**   static Void contributeRegistryStartup(OrderedConfig conf, MyService myService) {
**     conf.add |->| {
**       myService.startup()
**     }
**   }
** 
** @uses OrderedConfig of |->|
const mixin RegistryStartup {

}
