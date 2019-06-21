namespace eval MPMStructure::xml {
    # Namespace variables declaration
    variable dir
}

proc MPMStructure::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $MPMStructure::dir
    
    Model::getSolutionStrategies Strategies.xml
}

proc MPMStructure::xml::getUniqueName {name} {
    return ${::MPMStructure::prefix}${name}
}

proc ::MPMStructure::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
        ::Structural::xml::MultiAppEvent init
   }
}


proc MPMStructure::xml::CustomTree { args } {
    apps::setActiveAppSoft Structural
    Structural::xml::CustomTree

    apps::setActiveAppSoft MPMStructure

}

# # Overwriting some procs
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

MPMStructure::xml::Init
