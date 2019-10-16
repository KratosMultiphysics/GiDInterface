# Project Parameters
proc ::DEMPFEM::write::getParametersDict { } {
    set projectParametersDict [DEM::write::getParametersDict]

    dict set projectParametersDict coupling_level_type 1
    dict set projectParametersDict time_averaging_type 0
    dict set projectParametersDict interaction_start_time 0.0
    dict set projectParametersDict pick_individual_forces_option false
    dict set projectParametersDict do_search_neighbours true
    dict set projectParametersDict include_faxen_terms_option false
    dict set projectParametersDict include_faxen_terms_option_comment "(relevant if the Maxey Riley equation is used)"
    dict set projectParametersDict gradient_calculation_type 1
    dict set projectParametersDict gradient_calculation_type_comment "(Not calculated (0), volume-weighed average(1), Superconvergent recovery(2))"
    dict set projectParametersDict laplacian_calculation_type 2
    dict set projectParametersDict laplacian_calculation_type_comment "(Not calculated (0), Finite element projection (1), Superconvergent recovery(2))"
    dict set projectParametersDict buoyancy_force_type 2
    dict set projectParametersDict buoyancy_force_type_comment "null buoyancy (0), compute buoyancy (1)  if drag_force_type is 2 buoyancy is always parallel to gravity"
    set drag_type_tree [write::getValue DEMPFEM_CouplingParameters DragType]
    if {$drag_type_tree == "None"} {
        set drag_type 0
    } elseif {$drag_type_tree == "Stokes"} {
        set drag_type 1
    } elseif {$drag_type_tree == "AllReynolds"} {
        set drag_type 2
    } elseif {$drag_type_tree == "Ganser"} {
        set drag_type 3
    } elseif {$drag_type_tree == "Ishii"} {
        set drag_type 4
    }
    dict set projectParametersDict drag_force_type $drag_type
    dict set projectParametersDict drag_force_type_comment " null drag (0), Stokes (1), Weatherford (2), Ganser (3), Ishii (4), Newtonian Regime (5)"
    dict set projectParametersDict virtual_mass_force_type 0
    dict set projectParametersDict virtual_mass_force_type_comment "null virtual mass force (0)"
    dict set projectParametersDict lift_force_type 0
    dict set projectParametersDict lift_force_type_comment "# null lift force (0), Saffman (1)"
    dict set projectParametersDict magnus_force_type 0
    dict set projectParametersDict magnus_force_type_comment " null magnus force (0), Rubinow and Keller (1), Oesterle and Bui Dihn (2)"
    dict set projectParametersDict hydro_torque_type 0
    dict set projectParametersDict hydro_torque_type_comment "null hydrodynamic torque (0), Dennis (1)"
    dict set projectParametersDict drag_modifier_type 0
    dict set projectParametersDict viscosity_modification_type 0

    dict set projectParametersDict coupling_weighing_type 2
    dict set projectParametersDict coupling_weighing_type_comment "{fluid_to_DEM, DEM_to_fluid, fluid_fraction} = {lin, lin, imposed} (-1), {lin, const, const} (0), {lin, lin, const} (1), {lin, lin, lin} (2), averaging method (3)"
    dict set projectParametersDict fluid_model_type 1
    dict set projectParametersDict fluid_model_type_comment " untouched, velocity incremented by 1/fluid_fraction (0), modified mass conservation only (1)"
    dict set projectParametersDict coupling_scheme_type "UpdatedFluid"
    dict set projectParametersDict coupling_scheme_type_comment " UpdatedFluid, UpdatedDEM"
    dict set projectParametersDict print_particles_results_option false
    dict set projectParametersDict add_each_hydro_force_option true
    dict set projectParametersDict add_each_hydro_force_option_comment " add each of the hydrodynamic forces (drag, lift and virtual mass)"
    dict set projectParametersDict project_at_every_substep_option true
    dict set projectParametersDict manually_imposed_drag_law_option false
    dict set projectParametersDict stationary_problem_option false
    dict set projectParametersDict stationary_problem_option_comment " stationary, stop calculating the fluid after it reaches the stationary state"
    dict set projectParametersDict flow_in_porous_medium_option false
    dict set projectParametersDict flow_in_porous_medium_option_comment " the porosity is an imposed field"
    dict set projectParametersDict flow_in_porous_DEM_medium_option false
    dict set projectParametersDict flow_in_porous_DEM_medium_option_comment "the DEM part is kept static"
    dict set projectParametersDict embedded_option true
    dict set projectParametersDict embedded_option_comment "the embedded domain tools are to be used"
    dict set projectParametersDict make_results_directories_option true
    dict set projectParametersDict make_results_directories_option_comment "results are written into a folder (../results) inside the problem folder"
    dict set projectParametersDict body_force_on_fluid_option true
    dict set projectParametersDict print_debug_info_option false
    dict set projectParametersDict print_debug_info_option_comment " print a summary of global physical measures"
    dict set projectParametersDict print_particles_results_cycle 1
    dict set projectParametersDict print_particles_results_cycle_comment " number of 'ticks' per printing cycle"
    dict set projectParametersDict debug_tool_cycle 10
    dict set projectParametersDict debug_tool_cycle_comment " number of 'ticks' per debug computations cycle"
    dict set projectParametersDict similarity_transformation_type 0
    dict set projectParametersDict similarity_transformation_type_comment " no transformation (0), Tsuji (1)"
    dict set projectParametersDict dem_inlet_element_type "SphericSwimmingParticle3D"
    dict set projectParametersDict dem_inlet_element_type_comment " SphericParticle3D, SphericSwimmingParticle3D"
    dict set projectParametersDict drag_modifier_type 2
    dict set projectParametersDict drag_modifier_type_comment " Hayder (2), Chien (3) # problemtype option"
    dict set projectParametersDict drag_porosity_correction_type 0
    dict set projectParametersDict drag_porosity_correction_type_comment " No correction (0), Richardson and Zaki (1)"
    dict set projectParametersDict min_fluid_fraction 0.2
    dict set projectParametersDict initial_drag_force 0.0
    dict set projectParametersDict drag_law_slope 0.0
    dict set projectParametersDict power_law_tol 0.0
    dict set projectParametersDict model_over_real_diameter_factor 1.0
    dict set projectParametersDict model_over_real_diameter_factor_comment " not active if similarity_transformation_type = 0"
    dict set projectParametersDict max_pressure_variation_rate_tol 1e-3
    dict set projectParametersDict max_pressure_variation_rate_tol_comment " for stationary problems, criterion to stop the fluid calculations"
    dict set projectParametersDict time_steps_per_stationarity_step 15
    dict set projectParametersDict time_steps_per_stationarity_step_comment " number of fluid time steps between consecutive assessment of stationarity steps"
    dict set projectParametersDict meso_scale_length 0.2
    dict set projectParametersDict meso_scale_length_comment " the radius of the support of the averaging function for homogenization (<=0 for automatic calculation)"
    dict set projectParametersDict shape_factor 0.5
    dict set projectParametersDict non_newtonian_option false

    dict set projectParametersDict PostFluidPressure true
    dict set projectParametersDict print_REYNOLDS_NUMBER_option false
    dict set projectParametersDict print_PRESSURE_GRAD_PROJECTED_option false
    dict set projectParametersDict print_FLUID_VEL_PROJECTED_option false
    dict set projectParametersDict print_FLUID_ACCEL_PROJECTED_option false
    dict set projectParametersDict print_BUOYANCY_option false
    dict set projectParametersDict print_DRAG_FORCE_option false
    dict set projectParametersDict print_VIRTUAL_MASS_FORCE_option false
    dict set projectParametersDict print_BASSET_FORCE_option false
    dict set projectParametersDict print_LIFT_FORCE_option false
    dict set projectParametersDict print_FLUID_VEL_PROJECTED_RATE_option false
    dict set projectParametersDict print_FLUID_VISCOSITY_PROJECTED_option false
    dict set projectParametersDict print_FLUID_FRACTION_PROJECTED_option false
    dict set projectParametersDict print_FLUID_VEL_LAPL_PROJECTED_option false
    dict set projectParametersDict print_FLUID_VEL_LAPL_RATE_PROJECTED_option false
    dict set projectParametersDict print_HYDRODYNAMIC_FORCE_option false
    dict set projectParametersDict print_HYDRODYNAMIC_MOMENT_option false
    dict set projectParametersDict print_MESH_VELOCITY1_option false
    dict set projectParametersDict print_BODY_FORCE_option false
    dict set projectParametersDict print_FLUID_FRACTION_option false
    dict set projectParametersDict print_FLUID_FRACTION_GRADIENT_option false
    dict set projectParametersDict print_HYDRODYNAMIC_REACTION_option false
    dict set projectParametersDict print_PRESSURE_option true
    dict set projectParametersDict print_PRESSURE_GRADIENT_option false
    dict set projectParametersDict print_DISPERSE_FRACTION_option false
    dict set projectParametersDict print_MEAN_HYDRODYNAMIC_REACTION_option false
    dict set projectParametersDict print_VELOCITY_LAPLACIAN_option false
    dict set projectParametersDict print_VELOCITY_LAPLACIAN_RATE_option false

    return $projectParametersDict
}

proc DEMPFEM::write::writeParametersEvent { } {
    # DEM
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
    write::CloseFile
    write::RenameFileInModel ProjectParameters.json ProjectParametersDEM.json

    # PFEM
    write::OpenFile ProjectParameters.json
    dict set ::PfemFluid::write::Names DeltaTime PFEMDeltaTime
    PfemFluid::write::writeParametersEvent
}

proc PfemFluid::write::GetTimeSettings { } {
    set result [dict create]
    dict set result time_step [write::getValue PFEMFLUID_TimeParameters PFEMDeltaTime]
    dict set result start_time 0.0
    dict set result end_time [write::getValue PFEMFLUID_TimeParameters EndTime]
    return $result
}

proc DEM::write::GetTimeSettings { } {
    set result [dict create]
    dict set result DeltaTime [write::getValue DEMTimeParameters DEMDeltaTime]
    dict set result EndTime [write::getValue DEMTimeParameters EndTime]
    return $result
}


proc PfemFluid::write::GetGravity { } {
    return [DEM::write::GetGravity]
}
