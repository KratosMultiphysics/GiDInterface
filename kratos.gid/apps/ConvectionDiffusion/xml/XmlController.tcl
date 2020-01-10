namespace eval ConvectionDiffusion::xml {
    # Namespace variables declaration
    variable dir
}

proc ConvectionDiffusion::xml::Init { } {
    # Namespace variables inicialization
    variable dir
    Model::InitVariables dir $ConvectionDiffusion::dir
    
    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getMaterials Materials.xml
    Model::getNodalConditions NodalConditions.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getConditions Conditions.xml
    Model::getSolvers "../../Common/xml/Solvers.xml"
}

proc ConvectionDiffusion::xml::getUniqueName {name} {
    return ${::ConvectionDiffusion::prefix}${name}
}

proc ConvectionDiffusion::xml::CustomTree { args } {
    set root [customlib::GetBaseRoot]

    # Output control in output settings
    spdAux::SetValueOnTreeItem v time Results FileLabel
    spdAux::SetValueOnTreeItem v time Results OutputControlType
    
    customlib::ProcessIncludes $::Kratos::kratos_private(Path)
    spdAux::parseRoutes

    # Nodal reactions in output settings
    set xpath "[spdAux::getRoute Results]/container\[@n='GiDOutput'\]/container\[@n='OnNodes'\]"
    if {[$root selectNodes $xpath] ne ""} {
        gid_groups_conds::addF $xpath value [list n REACTION_FLUX pn "Reaction flux" v No values "Yes,No"]
    }

    # Make line_search appear only with non-linear strategy
    [$root selectNodes "[spdAux::getRoute CNVDFFStratParams]/value\[@n='line_search'\]"] setAttribute state "\[checkStateByUniqueName CNVDFFAnalysisType non_linear\]"
}

ConvectionDiffusion::xml::Init
