# Project Parameters
proc ::FluidDEM::write::getParametersDict { } {
    set project_parameters_dict [dict create]

    # Gravity
    lassign [DEM::write::GetGravity] gx gy gz
    # Add data to the parameters_dict
    dict set project_parameters_dict "GravityX"                         $gx
    dict set project_parameters_dict "GravityY"                         $gy
    dict set project_parameters_dict "GravityZ"                         $gz

    # add time_stepping{}

    # Problem data  - calling directly GetDefaultProblemDataDict should be enough
    dict set project_parameters_dict problem_data [write::GetDefaultProblemDataDict $Fluid::app_id]
    # set model_name [Kratos::GetModelName]
    # dict set project_parameters_dict problem_data                         $model_name

    # do_print_results_option
    # dict set project_parameters_dict "ControlTime"            [write::getValue DEMTimeParameters ScreenInfoOutput]
    dict set project_parameters_dict "do_print_results_option"                         "true"
    # output_interval
    dict set project_parameters_dict "output_interval"                                  "0.05"
    # coupling
    dict set project_parameters_dict coupling "coupling_level_type"                             "1"
    dict set project_parameters_dict coupling "coupling_weighing_type"                          "1"
    dict set project_parameters_dict coupling "coupling_weighing_type_comment"                  "{fluid_to_DEM, DEM_to_fluid, fluid_fraction} = {lin, lin, imposed} (-1), {lin, const, const} (0), {lin, lin, const} (1), {lin, lin, lin} (2), averaging method (3)"
    dict set project_parameters_dict coupling "interaction_start_time"                          "1"
    dict set project_parameters_dict coupling "time_averaging_type"                             "0.1"
    dict set project_parameters_dict coupling "coupling_level_type"                             "0"
    dict set project_parameters_dict coupling backward_coupling "meso_scale_length"             "0.2"
    dict set project_parameters_dict coupling backward_coupling "meso_scale_length_comment"     " the radius of the support of the averaging function for homogenization (<=0 for automatic calculation)"
    dict set project_parameters_dict coupling backward_coupling "shape_factor"                  "0.5"
    dict set project_parameters_dict coupling backward_coupling "filter_velocity_option"        "false"
    dict set project_parameters_dict coupling backward_coupling "apply_time_filter_to_fluid_fraction_option"   "false"
    dict set project_parameters_dict coupling backward_coupling "min_fluid_fraction"            "0.2"
    dict set project_parameters_dict coupling backward_coupling "fluid_fraction_grad_type"      "0"
    dict set project_parameters_dict coupling backward_coupling "calculate_diffusivity_option"  "false"
    dict set project_parameters_dict coupling backward_coupling "viscosity_modification_type"   "0"

    # dem_nodal_results
    dict set project_parameters_dict dem_nodal_results "REYNOLDS_NUMBER" "false"
    dict set project_parameters_dict dem_nodal_results "SLIP_VELOCITY" "false"
    dict set project_parameters_dict dem_nodal_results "RADIUS" "false"
    dict set project_parameters_dict dem_nodal_results "ANGULAR_VELOCITY" "false"
    dict set project_parameters_dict dem_nodal_results "ELASTIC_FORCES" "false"
    dict set project_parameters_dict dem_nodal_results "CONTACT_FORCES" "false"
    dict set project_parameters_dict dem_nodal_results "TOTAL_FORCES" "false"
    dict set project_parameters_dict dem_nodal_results "EXTERNAL_APPLIED_FORCE" "false"
    dict set project_parameters_dict dem_nodal_results "CATION_CONCENTRATION" "false"
    dict set project_parameters_dict dem_nodal_results "PRESSURE_GRAD_PROJECTED" "false"
    dict set project_parameters_dict dem_nodal_results "HYDRODYNAMIC_FORCE" "false"
    dict set project_parameters_dict dem_nodal_results "HYDRODYNAMIC_MOMENT" "false"
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_PROJECTED_RATE" "false"
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_LAPL_PROJECTED" "false"
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_LAPL_RATE_PROJECTED" "false"
    dict set project_parameters_dict dem_nodal_results "FLUID_ACCEL_PROJECTED" "false"
    dict set project_parameters_dict dem_nodal_results "FLUID_ACCEL_FOLLOWING_PARTICLE_PROJECTED" "false"
    dict set project_parameters_dict dem_nodal_results "FLUID_FRACTION_GRADIENT_PROJECTED" "false"
    dict set project_parameters_dict dem_nodal_results "FLUID_VISCOSITY_PROJECTED" "false"
    dict set project_parameters_dict dem_nodal_results "BUOYANCY" "false"
    dict set project_parameters_dict dem_nodal_results "DRAG_FORCE" "true"
    dict set project_parameters_dict dem_nodal_results "VIRTUAL_MASS_FORCE" "false"
    dict set project_parameters_dict dem_nodal_results "BASSET_FORCE" "false"
    dict set project_parameters_dict dem_nodal_results "LIFT_FORCE" "false"
    dict set project_parameters_dict dem_nodal_results "IMPACT_WEAR" "false"
    dict set project_parameters_dict dem_nodal_results "NON_DIMENSIONAL_VOLUME_WEAR" "false"
    dict set project_parameters_dict dem_nodal_results "PRESSURE" "false"
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_PROJECTED" "true"

    # fluid_nodal_results
    dict set project_parameters_dict fluid_nodal_results "MATERIAL_ACCELERATION" "true"
    dict set project_parameters_dict fluid_nodal_results "AVERAGED_FLUID_VELOCITY" "false"
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION" "false"
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION_OLD" "false"
    dict set project_parameters_dict fluid_nodal_results "DISPERSE_FRACTION" "false"
    dict set project_parameters_dict fluid_nodal_results "PARTICLE_VEL_FILTERED" "false"
    dict set project_parameters_dict fluid_nodal_results "TIME_AVERAGED_ARRAY_3" "false"
    dict set project_parameters_dict fluid_nodal_results "PHASE_FRACTION" "false"
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION_GRADIENT" "false"
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION_RATE" "false"
    dict set project_parameters_dict fluid_nodal_results "HYDRODYNAMIC_REACTION" "false"
    dict set project_parameters_dict fluid_nodal_results "MEAN_HYDRODYNAMIC_REACTION" "false"
    dict set project_parameters_dict fluid_nodal_results "POWER_LAW_N" "false"
    dict set project_parameters_dict fluid_nodal_results "POWER_LAW_K" "false"
    dict set project_parameters_dict fluid_nodal_results "YIELD_STRESS" "false"
    dict set project_parameters_dict fluid_nodal_results "GEL_STRENGTH" "false"
    dict set project_parameters_dict fluid_nodal_results "VISCOSITY" "false"
    dict set project_parameters_dict fluid_nodal_results "DISTANCE" "false"
    dict set project_parameters_dict fluid_nodal_results "SLIP_VELOCITY" "false"


    # set time_things [DEM::write::GetTimeSettings]
    #     set MaxTimeStep [dict get $time_things DeltaTime]
    # dict set project_parameters_dict "MaxTimeStep"                      $MaxTimeStep
    #     set TTime [dict get $time_things EndTime]
    # dict set project_parameters_dict "FinalTime"                        $TTime
    # # dict set project_parameters_dict "ControlTime"                      [write::getValue DEMTimeParameters ScreenInfoOutput]
    # # dict set project_parameters_dict "NeighbourSearchFrequency"         [write::getValue DEMTimeParameters NeighbourSearchFrequency]

    # Properties
    set properties_dict [dict create]
    set partgroup [write::getPartsSubModelPartId]
    dict set properties_dict "model_part_name" [write::GetModelPartNameWithParent [concat [lindex $partgroup 0]]]
    dict set properties_dict properties_id 1
    dict set properties_dict hydrodynamic_law_parameters "name" "HydrodynamicInteractionLaw"
    dict set properties_dict hydrodynamic_law_parameters buoyancy_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters inviscid_force_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters inviscid_force_parameters "do_apply_faxen_corrections" "false"
    dict set properties_dict hydrodynamic_law_parameters drag_parameters "name" "StokesDragLaw"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters "name" "default"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters "quadrature_order" "2 "
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters

    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "do_use_mae" "false"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "m" "10"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "window_time_interval" "0.1,"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "type" "4"

    # dict set properties_dict hydrodynamic_law_parameters vorticity_induced_lift_parameters "name" "default"
    # dict set properties_dict hydrodynamic_law_parameters rotation_induced_lift_parameters "name" "default"
    # dict set properties_dict hydrodynamic_law_parameters steady_viscous_torque_parameters "name" "default"

    set properties_list [list ]
    lappend properties_list $properties_dict
    dict set project_parameters_dict properties $properties_list


    # output configuration  #TODO to be checked/modified by GCasas
    dict set project_parameters_dict sdem_output_processes [write::GetDefaultOutputProcessDict $Fluid::app_id]

    W $project_parameters_dict

    FluidDEM::write::InitExternalProjectParameters
    dict set project_parameters_dict dem_parameters $FluidDEM::write::dem_project_parameters
    dict set dem_project_parameters solver_settings "strategy" "swimming_sphere_strategy"
    dict set project_parameters_dict fluid_parameters $FluidDEM::write::fluid_project_parameters
    # set FluidDEM::write::general_project_parameters [getParametersDict]
    # dict set project_parameters_dict $FluidDEM::write::general_project_parameters
    return $project_parameters_dict
}


proc FluidDEM::write::writeParametersEvent { } {
    W "1"
    set projectParametersDict [getParametersDict]
    W "2"
    write::SetParallelismConfiguration
    W "3"
    write::WriteJSON $projectParametersDict
    W "4"
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
