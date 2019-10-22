namespace eval ::FluidDEM::write {
    variable fluid_project_parameters
    variable dem_project_parameters
}

proc ::FluidDEM::write::Init { } {

    variable fluid_project_parameters
    variable dem_project_parameters
    variable general_project_parameters
    set fluid_project_parameters [dict create]
    set dem_project_parameters [dict create]
    set general_project_parameters [dict create]
    SetAttribute main_script_file "MainKratos.py"

}

# Events
proc FluidDEM::write::writeModelPartEvent { } {

    set filename [Kratos::GetModelName]

    Fluid::write::Init
    Fluid::write::InitConditionsMap
    Fluid::write::SetCoordinatesByGroups 1
    write::writeAppMDPA Fluid
    write::RenameFileInModel "$filename.mdpa" "${filename}Fluid.mdpa"

    DEM::write::Init
    set DEM::write::delete_previous_mdpa 0
    write::writeAppMDPA DEM

}
proc FluidDEM::write::writeCustomFilesEvent { } {
    Fluid::write::WriteMaterialsFile False
    SetAttribute main_script_file "MainKratos.py"
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]

}

proc FluidDEM::write::WriteMaterialsFile { } {

}

proc FluidDEM::write::SetAttribute {att val} {
    DEM::write::SetAttribute $att $val
}

proc FluidDEM::write::GetAttribute {att} {
    return [DEM::write::GetAttribute $att]
}

proc FluidDEM::write::GetAttributes {} {
    return [DEM::write::GetAttributes]
}

proc FluidDEM::write::AddAttributes {configuration} {
    DEM::write::AddAttributes $configuration
}

proc FluidDEM::write::AddValidApps {appid} {
    DEM::write::AddAttribute validApps $appid
}

proc Fluid::write::getFluidModelPartFilename { } {
    return [Kratos::GetModelName]Fluid
}

FluidDEM::write::Init