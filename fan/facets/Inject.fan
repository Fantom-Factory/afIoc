
// Facet Inheritance not applicable with fields - see http://fantom.org/sidewalk/topic/2186
// see TestInjectFacetInheritance
// @FacetMeta { inherited = true } 

** Use in services to inject dependencies.
**  - Place on a field to mark it for field injection
**  - Place on a ctor to mark it for use by autobuilding / service creation
facet class Inject { }
