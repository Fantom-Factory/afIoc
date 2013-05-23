
** Use in a module class to denote a service advisor method.
** 
** Advisor methods let you *intercept* method calls to a mixin fronted service, allowing you to
**  - perform pre & post method logic
**  - change the method arguments
**  - change the return value
**  - catch and process any thrown 'Errs'
**  - ignore the method call
**  - do something else entirely!
** 
** The [serviceId]`#serviceId` argument is a [glob pattern]`sys::Regex.glob` and is matched against 
** all service ids in the registry. This allows a single advisor method to match and advise 
** multiple services. e.g. to advise all DAOs you might define:
** 
**     @Advise { serviceId="*DAO" } 
** 
** The advisor method may be called anything you like. The first argument needs to be a list of 
** `MethodAdvisor`, any other arguments are taken to be dependent services and are injected as 
** such.
** 
** e.g. the following module method adds transaction commit / rollback code to all 'saveXXX()' 
** methods on *all* DAO services. 
** 
** @Advise { serviceId="*DAO" }
** static Void addTransations(MethodAdvisor[] methodAdvisors, MyTransactionManager transManager) {        
**     methodAdvisors
**         .findAll { it.method.name.startsWith("save") }
**         .each |advisor| { 
**             advisor.addAdvice |target, args| { 
**                 
**                 // my advice code
**                 transManager.startTransaction()
**                 try {
**                     advisor.method.callOn(target, args) 
**                     transManager.commit()
**                 } catch (Err e) {
**                     transManager.rollback()
**                     throw e
**                 }
**             } 
**         }
** }
** 
** Note you can only advise services that are defined by a mixin, as the advice mechanism makes use 
** of proxies.
** 
** @since 1.3.0
facet class Advise {
	
	** The glob pattern to match against all service ids.
	** 
	** Default value is '"*"', that is, match ALL services.
	const Str serviceId := "*"
	
}