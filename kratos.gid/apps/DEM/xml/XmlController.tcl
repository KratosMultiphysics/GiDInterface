namespace eval DEM::xml {
    variable dir
}

proc DEM::xml::Init { } {
    variable dir
    Model::InitVariables dir $DEM::dir

    Model::getSolutionStrategies Strategies.xml
    Model::getElements Elements.xml
    Model::getConstitutiveLaws ConstitutiveLaws.xml
    Model::getMaterials Materials.xml
    Model::getProcesses "../../Common/xml/Processes.xml"
    Model::getProcesses Processes.xml
    Model::getConditions Conditions.xml
    Model::getMaterialRelations "material_relations/MaterialRelations.xml"
}

proc DEM::xml::getUniqueName {name} {
    return DEM$name
}

proc DEM::xml::MultiAppEvent {args} {

}

proc DEM::xml::CustomTree { args } {
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

    # customlib::ProcessIncludes $::Kratos::kratos_private(Path)
    # spdAux::parseRoutes
}


proc DEM::xml::InsertConstitutiveLawForParameters {input arguments} {
    return {<value n='ConstitutiveLaw' pn='Constitutive law' v='' actualize_tree='1' values='[GetConstitutiveLaws]' dict='[GetAllConstitutiveLaws]'  help='Select a constitutive law'>
        <dependencies node="../value[@n = 'Material']" actualize='1'/>
        </value>
        <value n='Material' pn='Material' editable='0' help='Choose a material from the database' values='[get_materials_list_simple]' v='DEM-DefaultMaterial' state='normal' />
    }
}

proc DEM::xml::ProcGetElements { domNode args } {
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

proc DEM::xml::ProcGetStateBoundingBoxParams { domNode args } {

    set bounding_box_active [write::getValue Boundingbox UseBB ]
    set bounding_box_automatic [write::getValue Boundingbox AutomaticBB ]

    set ret hidden
    if {[write::isBooleanTrue $bounding_box_active] && [write::isBooleanFalse $bounding_box_automatic]} {
        set ret normal
    }
    return $ret
}

proc DEM::xml::ProcGetDEMPartsOvWhat { domNode args } {
    if {$::Model::SpatialDimension eq "2D"} {
        return "point,line,surface"
    } else {
        return "point,line,surface,volume"
    }
}


proc DEM::xml::InertiaType { args } {
    set ret inline_vector
    if {$::Model::SpatialDimension eq "2D"} {
        set ret double
    }

    return $ret
}

proc DEM::xml::injectMaterialRelations { domNode args } {
    W $domNode
}

proc DEM::xml::ShowMaterialRelationWindow { } {
    
}


DEM::xml::Init
