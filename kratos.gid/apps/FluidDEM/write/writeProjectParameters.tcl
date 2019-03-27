# Project Parameters
proc ::FluidDEM::write::getParametersDict { } {
    set project_parameters_dict [dict create]
    dict set project_parameters_dict "Dimension" [expr 3]

    # Gravity
    lassign [DEM::write::GetGravity] gx gy gz
    # Add data to the parameters_dict
    dict set project_parameters_dict "GravityX"                         $gx
    dict set project_parameters_dict "GravityY"                         $gy
    dict set project_parameters_dict "GravityZ"                         $gz

    set time_things [DEM::write::GetTimeSettings]
        set MaxTimeStep [dict get $time_things DeltaTime]
    dict set project_parameters_dict "MaxTimeStep"                      $MaxTimeStep
        set TTime [dict get $time_things EndTime]
    dict set project_parameters_dict "FinalTime"                        $TTime
    # TODO: check this getValues no working correctly
    # dict set project_parameters_dict "ControlTime"                      [write::getValue DEMTimeParameters ScreenInfoOutput]
    # dict set project_parameters_dict "NeighbourSearchFrequency"         [write::getValue DEMTimeParameters NeighbourSearchFrequency]

    # Properties
    set properties_dict [dict create]
    set partgroup [write::getPartsSubModelPartId]
    dict set properties_dict "model_part_name" [write::GetModelPartNameWithParent [concat [lindex $partgroup 0]]]
    dict set properties_dict properties_id 1
    dict set properties_dict hydrodynamic_law_parameters "name" "HydrodynamicInteractionLaw"
    dict set properties_dict hydrodynamic_law_parameters buoyancy_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters inviscid_force_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters drag_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters vorticity_induced_lift_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters rotation_induced_lift_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters steady_viscous_torque_parameters "name" "default"

    set properties_list [list ]
    lappend properties_list $properties_dict
    dict set project_parameters_dict properties $properties_list

    FluidDEM::write::InitExternalProjectParameters
    dict set project_parameters_dict dem_parameters $FluidDEM::write::dem_project_parameters
    dict set project_parameters_dict fluid_parameters $FluidDEM::write::fluid_project_parameters
    # set FluidDEM::write::general_project_parameters [getParametersDict]
    # dict set project_parameters_dict $FluidDEM::write::general_project_parameters
    return $project_parameters_dict
}


proc FluidDEM::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}


proc FluidDEM::write::InitExternalProjectParameters { } {
    # Fluid section
    #UpdateUniqueNames Fluid
    apps::setActiveAppSoft Fluid
    write::initWriteConfiguration [Fluid::write::GetAttributes]
    set FluidDEM::write::fluid_project_parameters [Fluid::write::getParametersDict]

    # Structure section
    #UpdateUniqueNames DEM
    apps::setActiveAppSoft DEM
    write::initWriteConfiguration [DEM::write::GetAttributes]
    set FluidDEM::write::dem_project_parameters [DEM::write::getParametersDict]


    apps::setActiveAppSoft FluidDEM
}
