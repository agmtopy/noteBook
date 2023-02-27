classDiagram
direction BT
class AspectJWeavingEnabler
class Aware {
<<Interface>>

}
class DefaultPersistenceUnitManager
class LoadTimeWeaverAware {
<<Interface>>

}
class LocalContainerEntityManagerFactoryBean

AspectJWeavingEnabler  ..>  LoadTimeWeaverAware 
DefaultPersistenceUnitManager  ..>  LoadTimeWeaverAware 
LoadTimeWeaverAware  -->  Aware 
LocalContainerEntityManagerFactoryBean  ..>  LoadTimeWeaverAware 
