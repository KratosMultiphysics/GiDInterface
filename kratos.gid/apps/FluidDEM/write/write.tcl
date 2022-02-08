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
    Validate
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

proc FluidDEM::write::Validate { } {
    if {[GiD_Info mesh] eq 0} {[error "Model not meshed"]}
}

proc FluidDEM::write::writeCustomFilesEvent { } {
    FluidDEM::write::WriteMaterialsFile
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
}

# Overwritten to add CylinderContinuumParticle
proc DEM::write::GetInletElementType {} {
    set elem_name SphericSwimmingParticle3D
    if {$::Model::SpatialDimension eq "2D"} {
        set elem_name SphericSwimmingParticle2D
    }
    return $elem_name
}

proc FluidDEM::write::WriteMaterialsFile { } {
    FluidDEM::write::writeFluidModifiedMaterials [Fluid::write::GetMaterialsFile True]
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

proc FluidDEM::write::writeFluidModifiedMaterials {fluid_materials_json} {
    set new_json [dict create]
    foreach property [dict get $fluid_materials_json properties] {
        if {[dict exists $property Material Variables PERMEABILITY_11]} {
            set permeability_1 [list [dict get $property Material Variables PERMEABILITY_11] [dict get $property Material Variables PERMEABILITY_12] [dict get $property Material Variables PERMEABILITY_13]]
            set permeability_2 [list [dict get $property Material Variables PERMEABILITY_12] [dict get $property Material Variables PERMEABILITY_22] [dict get $property Material Variables PERMEABILITY_23]]
            set permeability_3 [list [dict get $property Material Variables PERMEABILITY_13] [dict get $property Material Variables PERMEABILITY_23] [dict get $property Material Variables PERMEABILITY_33]]
            dict unset property Material Variables PERMEABILITY_11; dict unset property Material Variables PERMEABILITY_12; dict unset property Material Variables PERMEABILITY_13
            dict unset property Material Variables PERMEABILITY_22; dict unset property Material Variables PERMEABILITY_23
            dict unset property Material Variables PERMEABILITY_33
            dict set property Material Variables PERMEABILITY [list $permeability_1 $permeability_2 $permeability_3]
        }
        dict lappend new_json properties $property
    }
    write::writePropertiesJsonFileDone [Fluid::write::GetAttribute materials_file] $new_json
}

FluidDEM::write::Init
