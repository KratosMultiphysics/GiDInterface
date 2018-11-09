namespace eval ConjugateHeatTransfer::xml {
    # Namespace variables declaration
    variable dir
}

proc ConjugateHeatTransfer::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $ConjugateHeatTransfer::dir


    Model::getMaterials "../../ConvectionDiffusion/xml/Materials.xml"
    
    Model::getConstitutiveLaws "../../ConvectionDiffusion/xml/ConstitutiveLaws.xml" 
}

proc ConjugateHeatTransfer::xml::getUniqueName {name} {
    return ${::ConjugateHeatTransfer::prefix}${name}
}

proc ::ConjugateHeatTransfer::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
        #::Structural::xml::MultiAppEvent init
   }
}


proc ConjugateHeatTransfer::xml::CustomTree { args } {
    # Calling to the Buoyancy custom tree event
    apps::setActiveAppSoft Buoyancy
    Buoyancy::xml::CustomTree
    
    # It seems that we do not need to call the custom tree for the Convection diffusion because
    # Buoyancy calls it, and it only modifies something in the result section, wich is moved into coupling.

    # Time intervals only in coupling 

}

# Overwriting some procs
# proc spdAux::injectNodalConditionsOutputs {basenode args} {
#     set base [$basenode parent]
#     set args {*}$args
#     if {$args eq ""} {
#         set app [apps::getAppById [spdAux::GetAppIdFromNode $base]]
#         set args [list ImplementedInApplication [join [$app getKratosApplicationName] ","]]
#     }
#     return [spdAux::injectNodalConditionsOutputs_do $basenode $args]
# }

# proc spdAux::injectElementOutputs {basenode args} {
#     set base [$basenode parent]
#     set args {*}$args
#     if {$args eq ""} {
#         set app [apps::getAppById [spdAux::GetAppIdFromNode $base]]
#         set args [list ImplementedInApplication [join [$app getKratosApplicationName] ","]]
#     }
#     return [spdAux::injectElementOutputs_do $basenode $args]
# }

ConjugateHeatTransfer::xml::Init
