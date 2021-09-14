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
    Model::getNodalConditions    NodalConditions.xml
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
    spdAux::SetValueOnTreeItem v time CFResults FileLabel
    spdAux::SetValueOnTreeItem v time CFResults OutputControlType

    # Drag in output settings
    set xpath "[spdAux::getRoute CFResults]/container\[@n='GiDOutput'\]"
    if {[$root selectNodes "$xpath/condition\[@n='Drag'\]"] eq ""} {
        gid_groups_conds::addF $xpath include [list n Drag active 1 path {apps/Fluid/xml/Drag.spd}]
    }
    
    customlib::ProcessIncludes $::Kratos::kratos_private(Path)
    spdAux::parseRoutes

    # Nodal reactions in output settings
    if {[$root selectNodes "$xpath/container\[@n='OnNodes'\]"] ne ""} {
        gid_groups_conds::addF "$xpath/container\[@n='OnNodes'\]" value [list n REACTION pn "Reaction" v No values "Yes,No"]
    }
}

proc ::CompressibleFluid::xml::ProcHideIfElement { domNode list_elements } {
    set element [lindex [CompressibleFluid::write::GetUsedElements] 0]
    if {$element in $list_elements} {return hidden} {return normal}
}
