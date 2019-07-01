namespace eval Chimera::write {
    variable writeAttributes
}

proc Chimera::write::Init { } {
    # Namespace variables inicialization
    variable writeAttributes
    set writeAttributes [Fluid::write::GetAttributes]

    SetAttribute chim_parts_un ChimParts
    SetAttribute writeCoordinatesByGroups 1
    SetAttribute validApps [list "Fluid" "Chimera"]
}

# Events
proc Chimera::write::writeModelPartEvent { } {
    # Write the background mesh as the fluid
    Fluid::write::writeModelPartEvent
    write::CloseFile

    # Write the patches as independent mdpa
    Chimera::write::writePatches
}

proc Chimera::write::writePatches { } {
    set root [customlib::GetBaseRoot]
    set xp "[spdAux::getRoute [GetAttribute chim_parts_un]]/group"
    foreach patch [$root selectNodes $xp] {
        set group_id [$patch @n]
        set patch_name [write::GetWriteGroupName $group_id]
        write::OpenFile ${patch_name}.mdpa
        write::writeNodalCoordinatesOnGroups $group_id
        write::writeGroupElementConnectivities $patch ChimeraPatch$Model::SpatialDimension
        write::CloseFile
    }
}

proc Chimera::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/KratosFluid.py"
    write::RenameFileInModel "KratosFluid.py" "MainKratos.py"
}

proc Chimera::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Chimera::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Chimera::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

Chimera::write::Init
