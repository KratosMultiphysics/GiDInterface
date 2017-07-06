namespace eval DEM::write {
    variable writeAttributes
}

proc DEM::write::Init { } {    
    variable writeAttributes
    set writeAttributes [dict create]
    SetAttribute validApps [list "DEM"]
    SetAttribute writeCoordinatesByGroups 1
    SetAttribute properties_location py 
    SetAttribute parts_un DEMParts
    SetAttribute materials_un DEMMaterials
    SetAttribute conditions_un DEMLoads
    SetAttribute nodal_conditions_un DEMNodalConditions
    SetAttribute materials_file "DEMMaterials.json"
    SetAttribute main_script_file "KratosDEM.py"
}

proc DEM::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc DEM::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc DEM::write::AddAttribute {att val} {
    variable writeAttributes
    dict append writeAttributes $att $val]
}

proc DEM::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc DEM::write::AddValidApps {appList} {
    AddAttribute validApps $appList
}

proc DEM::write::writeCustomFilesEvent { } {
    WriteMaterialsFile
    
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    set paralleltype [write::getValue ParallelType]
    
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc DEM::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

proc DEM::write::ApplyConfiguration { } {
    variable writeAttributes
    write::SetConfigurationAttributes $writeAttributes
}

# MDPA Blocks
proc DEM::write::writeModelPartEvent { } {
    variable ConditionsDictGroupIterators
    variable writeAttributes
    write::initWriteConfiguration $writeAttributes
    
    # Headers
    write::writeModelPartData

    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    # write::writeMaterials $validApps

    # Nodal coordinates (1: only for DEM <inefficient> | 0: the whole mesh <efficient>)
    if {[GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}
    
    # Element connectivities (Groups on STParts)
    write::writeElementConnectivities

    # Nodal conditions and conditions
    writeConditions

    # SubmodelParts
    writeMeshes

    # Custom SubmodelParts
    set basicConds [write::writeBasicSubmodelParts [getLastConditionId]]
    set ConditionsDictGroupIterators [dict merge $ConditionsDictGroupIterators $basicConds]

}


proc DEM::write::writeConditions { } {
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [write::writeConditions [GetAttribute conditions_un] ]
}

proc DEM::write::writeMeshes { } {
    
    write::writePartMeshes
    
    # Solo Malla , no en conditions
    write::writeNodalConditions [GetAttribute nodal_conditions_un]
    
    # A Condition y a meshes-> salvo lo que no tenga topologia
    writeLoads
}

proc DEM::write::writeLoads { } {
    variable ConditionsDictGroupIterators
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        #W "Writing mesh of Load $groupid"
        if {$groupid in [dict keys $ConditionsDictGroupIterators]} {
            ::write::writeGroupMesh [[$group parent] @n] $groupid "Conditions" [dict get $ConditionsDictGroupIterators $groupid]
        } else {
            ::write::writeGroupMesh [[$group parent] @n] $groupid "nodal"
        }
    }
}

proc DEM::write::writeCustomBlock { } {
    write::WriteString "Begin Custom"
    write::WriteString "Custom write for DEM, any app can call me, so be careful!"
    write::WriteString "End Custom"
    write::WriteString ""
}

DEM::write::Init
