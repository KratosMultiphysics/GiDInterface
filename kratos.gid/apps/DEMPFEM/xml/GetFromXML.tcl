namespace eval DEMPFEM::xml {
    # Namespace variables declaration
    variable dir
}

proc DEMPFEM::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $DEMPFEM::dir

    Model::ForgetElement SphericPartDEMElement3D
    Model::getElements Elements.xml
}

proc DEMPFEM::xml::getUniqueName {name} {
    return ${::DEMPFEM::prefix}${name}
}

proc DEMPFEM::xml::CustomTree { args } {
    # spdAux::parseRoutes

    # apps::setActiveAppSoft Fluid
    # Fluid::xml::CustomTree

    # apps::setActiveAppSoft ConvectionDiffusion
    # ConvectionDiffusion::xml::CustomTree

    # apps::setActiveAppSoft Buoyancy

    # # Modify the tree: field newValue UniqueName OptionalChild
    # spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat
    # spdAux::SetValueOnTreeItem v "Yes" FLStratParams compute_reactions
    
    # # Hide Fluid gravity -> Boussinesq
    # spdAux::SetValueOnTreeItem state hidden FLGravity
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

DEMPFEM::xml::Init
