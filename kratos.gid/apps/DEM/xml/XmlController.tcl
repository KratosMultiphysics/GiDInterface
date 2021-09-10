namespace eval ::DEM::xml {
    namespace path ::DEM
    variable dir
}

proc ::DEM::xml::Init { } {
    variable dir
    Model::InitVariables dir $::DEM::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getMaterials Materials.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getConditions Conditions.xml
    Model::getMaterialRelations "material_relations/MaterialRelations.xml"
}

proc ::DEM::xml::getUniqueName {name} {
    return [::DEM::GetAttribute prefix]$name
}

proc ::DEM::xml::CustomTree { args } {
    set root [customlib::GetBaseRoot]
    spdAux::SetValueOnTreeItem values OpenMP ParallelType
    spdAux::SetValueOnTreeItem state hidden DEMTimeParameters StartTime

    # 3D gravity
    if {$Model::SpatialDimension eq "3D"} {
        catch {
            spdAux::SetValueOnTreeItem v 0.0 DEMGravity Cy
            spdAux::SetValueOnTreeItem v -1.0 DEMGravity Cz
        }
    }

    set custom_smp_xpath "[spdAux::getRoute DEMConditions]/condition\[@n='DEM-CustomSmp'\]/value\[@n='Element'\]"
    gid_groups_conds::setAttributes $custom_smp_xpath [list state hidden dict {[GetElements ElementType DEM]} ]
    set custom_smp_xpath "[spdAux::getRoute DEMConditions]/condition\[@n='DEM-CustomSmp'\]/value\[@n='AdvancedMeshingFeatures'\]"
    gid_groups_conds::setAttributes $custom_smp_xpath [list state hidden ]

    # Inlet 2D or 3D special parameters
    set 3dinlet_xpath "[spdAux::getRoute DEMConditions]/condition\[@n='Inlet'\]/value\[@n='InletElementType'\]"
    gid_groups_conds::setAttributes $3dinlet_xpath [list values "SphericParticle3D,Cluster3D,SingleSphereCluster" ]
    set 2dinlet_xpath "[spdAux::getRoute DEMConditions]/condition\[@n='Inlet2D'\]/value\[@n='InletElementType'\]"
    gid_groups_conds::setAttributes $2dinlet_xpath [list values "CylinderParticle2D" ]
    

    # spdAux::parseRoutes
    spdAux::processDynamicNodes [customlib::GetBaseRoot]
}

proc ::DEM::xml::ProcGetElements { domNode args } {
    set elems [Model::GetElements]
    set names [list ]
    set pnames [list ]
    foreach elem $elems {
        if {[$elem cumple {*}$args]} {
            lappend names [$elem getName]
            lappend pnames [$elem getName]
            lappend pnames [$elem getPublicName]
        }
    }
    set diction [join $pnames ","]
    set values [join $names ","]
    #W "[get_domnode_attribute $domNode v] $names"
    $domNode setAttribute values $values
    if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
    if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}
    #spdAux::RequestRefresh
    return $diction
}

proc ::DEM::xml::ProcGetStateBoundingBoxParams { domNode args } {

    set bounding_box_active [write::getValue Boundingbox UseBB ]
    set bounding_box_automatic [write::getValue Boundingbox AutomaticBB ]

    set ret hidden
    if {[write::isBooleanTrue $bounding_box_active] && [write::isBooleanFalse $bounding_box_automatic]} {
        set ret normal
    }
    return $ret
}

proc ::DEM::xml::ProcGetDEMPartsOvWhat { domNode args } {
    if {$::Model::SpatialDimension eq "2D"} {
        return "point,line,surface"
    } else {
        return "point,line,surface,volume"
    }
}


proc ::DEM::xml::InertiaType { args } {
    set ret inline_vector
    if {$::Model::SpatialDimension eq "2D"} {
        set ret double
    }

    return $ret
}

proc ::DEM::xml::injectMaterialRelations { basenode args } {
    
    set base [$basenode parent]
    set materials_relations [Model::GetMaterialRelations {*}$args]
    foreach mat $materials_relations {
        set matname [$mat getName]
        set mathelp [$mat getAttribute help]
        set icon [$mat getAttribute icon]
        if {$icon eq ""} {set icon material-relation-16}
        set inputs [$mat getInputs]
        set matnode "<blockdata n='material_relation' name='$matname' sequence='1' editable_name='unique' icon='$icon' help='Material definition'  morebutton='0'  open_window='0'>"
        foreach {inName in} $inputs {
            set node [spdAux::GetParameterValueString $in [list base $mat state [$in getAttribute state]] $mat]
            append matnode $node
        }
        append matnode "</blockdata> \n"
        $base appendXML $matnode
    }
    $basenode delete

}

proc ::DEM::xml::MaterialRelationsValidation { } {
    set err ""
    # Get Used Materials

    # At least all materials must be related

    return $err
}
