namespace eval ::FluidDEM::write {
    namespace path ::FluidDEM
    Kratos::AddNamespace [namespace current]
    
    variable fluid_project_parameters
    variable dem_project_parameters
}

proc ::FluidDEM::write::Init { } {
    variable fluid_project_parameters
    set fluid_project_parameters [dict create]
    variable dem_project_parameters
    set dem_project_parameters [dict create]
    variable general_project_parameters
    set general_project_parameters [dict create]
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
    FluidDEM::write::WriteMaterialsFile
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]

}

proc FluidDEM::write::WriteMaterialsFile { } {
    Fluid::write::WriteMaterialsFile True
    DEM::write::writeMaterialsFile
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

