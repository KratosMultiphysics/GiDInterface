namespace eval CompressibleFluid::xml {
    namespace path ::CompressibleFluid
    Kratos::AddNamespace [namespace current]
}

proc ::CompressibleFluid::xml::Init { } {
    # Namespace variables inicialization
    Model::InitVariables dir $::CompressibleFluid::dir

    set FluidXML  "$::Fluid::dir/xml"
    set CommonXML "../../Common/xml"

    Model::getSolutionStrategies Strategies.xml
    Model::getElements           Elements.xml
    Model::getMaterials          Materials.xml

    Model::ForgetNodalConditions
    Model::getNodalConditions    "$FluidXML/NodalConditions.xml"
    Model::getNodalConditions    NodalConditions.xml

    Model::ForgetConstitutiveLaws
    Model::getConstitutiveLaws   ConstitutiveLaws.xml

    Model::getProcesses          "$CommonXML/Processes.xml"
    Model::getProcesses          "$FluidXML/Processes.xml"

    Model::getConditions         Conditions.xml
    Model::getSolvers            "$CommonXML/Solvers.xml"
}

proc ::CompressibleFluid::xml::getUniqueName {name} {
    return [::CompressibleFluid::GetAttribute prefix]${name}
}

proc ::CompressibleFluid::xml::CustomTree { args } {
    set root [customlib::GetBaseRoot]

    set results_un [::CompressibleFluid::GetUniqueName "results"]

    # Output control in output settings
    spdAux::SetValueOnTreeItem v time $results_un FileLabel
    spdAux::SetValueOnTreeItem v time $results_un OutputControlType

    # Drag in output settings
    set xpath "[spdAux::getRoute $results_un]/container\[@n='GiDOutput'\]"
    if {[$root selectNodes "$xpath/condition\[@n='Drag'\]"] eq ""} {
        gid_groups_conds::addF $xpath include [list n Drag active 1 path {apps/Fluid/xml/Drag.spd}]
    }

    customlib::ProcessIncludes $::Kratos::kratos_private(Path)
    spdAux::parseRoutes

    # Nodal reactions in output settings
    if {[$root selectNodes "$xpath/container\[@n='OnNodes'\]"] ne ""} {
        gid_groups_conds::addF "$xpath/container\[@n='OnNodes'\]" value [list n REACTION pn "Reaction" v No values "Yes,No"]
    }

    # If case is 2D, set Z variables to Not
    set nDim $::Model::SpatialDimension
    if {$nDim ne "3D"} {
        set xpath "[spdAux::getRoute FLBC]/condition\[@n='MomentumConstraints2D'\]"
        if {[$root selectNodes "$xpath"] ne ""} {
            [$root selectNodes "$xpath/value\[@n = 'selector_component_Z'\]"] setAttribute v "Not"
        }
        set xpath "[spdAux::getRoute FLNodalConditions]/condition\[@n='MOMENTUM'\]"
        if {[$root selectNodes "$xpath"] ne ""} {
            [$root selectNodes "$xpath/value\[@n = 'selector_component_Z'\]"] setAttribute v "Not"
        }
    }

    # foreach non_historical [Model::GetNodalConditions {is_historical False}] {
    #     set xpath [spdAux::getRoute NodalResults]
    #     # <value n="VELOCITY" pn="Velocity" v="Yes" values="Yes,No" state="[CheckNodalConditionState VELOCITY]" tree_state="close"/>
    #     set name [$non_historical getName]
    #     if {[$root selectNodes "$xpath/value\[@n='$name'\]"] eq ""} {
    #         gid_groups_conds::addF $xpath include [list n Drag active 1 path {apps/Fluid/xml/Drag.spd}]
    #     }
    # }

}

proc ::CompressibleFluid::xml::ProcHideIfElement { domNode list_elements } {
    set element [lindex [CompressibleFluid::write::GetUsedElements] 0]
    if {$element in $list_elements} {return hidden} {return normal}
}
