
** An optional facet to use in conjunction with [@Inject]`Inject`. Signifies a new instance of the service should be injected
** 
** pre>
** @Inject @Autobuild
** MyService myService
** <pre
** 
** May not be used with '@ServiceId' or other [Dependency Providers]`DependencyProvider`.
** 
** @since 1.1.0
facet class Autobuild {
}
