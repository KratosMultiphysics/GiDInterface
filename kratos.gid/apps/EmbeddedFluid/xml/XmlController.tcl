namespace eval EmbeddedFluid::xml {
    # Namespace variables declaration
    variable lastImportMeshSize
    variable export_dir
}

proc EmbeddedFluid::xml::Init { } {
    # Namespace variables inicialization
    variable lastImportMeshSize
    set lastImportMeshSize 0

    Model::InitVariables dir $::EmbeddedFluid::dir

    Model::ForgetSolutionStrategies
    Model::getSolutionStrategies Strategies.xml
}

proc EmbeddedFluid::xml::MultiAppEvent {args} {
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames [::Fluid::GetAttribute prefix] [::EmbeddedFluid::GetAttribute prefix]
    }
}

proc EmbeddedFluid::xml::getUniqueName {name} {
    return [::EmbeddedFluid::GetAttribute prefix]${name}
}

proc EmbeddedFluid::xml::CustomTree { args } {
    # Hide Results Cut planes
    spdAux::SetValueOnTreeItem v time Results FileLabel
    spdAux::SetValueOnTreeItem v time Results OutputControlType

    set root [customlib::GetBaseRoot]
    if {[$root selectNodes "[spdAux::getRoute NodalResults]/value\[@n='DISTANCE'\]"] eq ""} {
        gid_groups_conds::addF [spdAux::getRoute NodalResults] value [list n DISTANCE pn Distance v Yes values {Yes,No} state normal]
    }
    if {[$root selectNodes "[spdAux::getRoute EMBFLSolutionParameters]/container\[@n='DistanceSettings'\]"] eq ""} {
        gid_groups_conds::addF [spdAux::getRoute EMBFLSolutionParameters] include [list n DistanceSettings active 1 path {apps/EmbeddedFluid/xml/DistanceSettings.spd}]
    }
    if {[$root selectNodes "[spdAux::getRoute EMBFLSolutionParameters]/container\[@n='AdaptivitySettings'\]"] eq ""} {
        gid_groups_conds::addF [spdAux::getRoute EMBFLSolutionParameters] include [list n AdaptivitySettings active 1 path {apps/EmbeddedFluid/xml/AdaptivitySettings.spd}]
    }
    
    set xpath "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]/condition\[@n='EmbeddedDrag'\]"
    if {[$root selectNodes $xpath] eq ""} {
        gid_groups_conds::addF "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]" include [list n EmbeddedDrag active 1 path {apps/EmbeddedFluid/xml/EmbeddedDrag.spd}]
    }
    customlib::ProcessIncludes $::Kratos::kratos_private(Path)
    spdAux::parseRoutes
    # Erase when Fractional step is available
    #spdAux::SetValueOnTreeItem v Monolithic EMBFLSolStrat
    #spdAux::SetValueOnTreeItem values Monolithic EMBFLSolStrat
    #spdAux::SetValueOnTreeItem dict "Monolithic,Navier Stokes - Monolithic" EMBFLSolStrat
    #spdAux::SetValueOnTreeItem v MN EMBFLScheme
    #spdAux::SetValueOnTreeItem values MN EMBFLScheme
    #spdAux::SetValueOnTreeItem dict "MN,Monolitic generic scheme" EMBFLScheme
}
