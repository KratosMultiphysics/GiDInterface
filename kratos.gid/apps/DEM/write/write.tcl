namespace eval DEM::write {
    variable writeAttributes
    variable inletProperties
    variable last_property_id
    variable delete_previous_mdpa
}

proc DEM::write::Init { } {    
    variable writeAttributes
    set writeAttributes [dict create]
    SetAttribute validApps [list "DEM"]
    SetAttribute writeCoordinatesByGroups 1
    SetAttribute properties_location mdpa 
    SetAttribute parts_un DEMParts
    SetAttribute materials_un DEMMaterials
    SetAttribute conditions_un DEMConditions
    SetAttribute nodal_conditions_un DEMNodalConditions
    SetAttribute materials_file "DEMMaterials.json"
    SetAttribute main_script_file "KratosDEM.py"

    variable inletProperties
    set inletProperties [dict create]
    
    variable last_property_id
    set last_property_id 0
    
    variable delete_previous_mdpa
    set delete_previous_mdpa 1
}

# MDPA Blocks
proc DEM::write::writeModelPartEvent { } {
    variable last_property_id
    set last_property_id 0
    
    variable writeAttributes
    write::initWriteConfiguration $writeAttributes
    
    # MDPA Parts
    write::CloseFile
    
    variable delete_previous_mdpa
    if {$delete_previous_mdpa} {
        catch {file delete -force [file join [write::GetConfigurationAttribute dir] "[Kratos::GetModelName].mdpa"]}
    }

    write::OpenFile "[Kratos::GetModelName]DEM.mdpa"
    WriteMDPAParts
    write::CloseFile

    # MDPA Inlet
    write::OpenFile "[Kratos::GetModelName]DEM_Inlet.mdpa"
    WriteMDPAInlet
    write::CloseFile

    # MDPA Walls
    write::OpenFile "[Kratos::GetModelName]DEM_FEM_boundary.mdpa"
    WriteMDPAWalls
    write::CloseFile

    # MDPA Walls
    write::OpenFile "[Kratos::GetModelName]DEM_Clusters.mdpa"
    WriteMDPAClusters
    write::CloseFile
}

proc DEM::write::writeCustomFilesEvent { } {
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    
    write::RenameFileInModel $orig_name "MainKratos.py"
    write::RenameFileInModel "ProjectParameters.json" "ProjectParametersDEM.json"
}

# Attributes block
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

# MultiApp events
proc DEM::write::AddValidApps {appList} {
    AddAttribute validApps $appList
}

proc DEM::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

proc DEM::write::ApplyConfiguration { } {
    variable writeAttributes
    write::SetConfigurationAttributes $writeAttributes
}

DEM::write::Init