# Project Parameters
proc ::FluidDEM::write::getParametersDict { } {
    W "5"
    set project_parameters_dict [dict create]

    set gravity_value [write::getValue DEMGravity GravityValue]
    set gravity_X [write::getValue DEMGravity Cx]
    set gravity_Y [write::getValue DEMGravity Cy]
    set gravity_Z [write::getValue DEMGravity Cz]

    dict set project_parameters_dict gravity_parameters "modulus" $gravity_value
    lassign [MathUtils::VectorNormalized [list $gravity_X $gravity_Y $gravity_Z]] gravity_X gravity_Y gravity_Z
    dict set project_parameters_dict gravity_parameters "direction" [list $gravity_X $gravity_Y $gravity_Z]


    # # Gravity
    # lassign [DEM::write::GetGravity] gx gy gz
    # # Add data to the parameters_dict
    # dict set project_parameters_dict "GravityX"                         $gx
    # dict set project_parameters_dict "GravityY"                         $gy
    # dict set project_parameters_dict "GravityZ"                         $gz

    # add time_stepping
    set automatic_time_step [write::getValue FDEMTimeParameters AutomaticDeltaTime]
    set time_step [write::getValue FDEMTimeParameters FluidDeltaTime]
    #set automatic_time_step2 [write::getValue FLAutomaticDeltaTime]

    dict set project_parameters_dict time_stepping "automatic_time_step"                $automatic_time_step
    dict set project_parameters_dict time_stepping "time_step"                          $time_step


    # Problem data  - calling directly GetDefaultProblemDataDict should be enough
    dict set project_parameters_dict problem_data [write::GetDefaultProblemDataDict $Fluid::app_id]
    # set model_name [Kratos::GetModelName]
    # dict set project_parameters_dict problem_data                         $model_name
    W "6"
    # do_print_results_option
    # dict set project_parameters_dict "ControlTime"            [write::getValue DEMTimeParameters ScreenInfoOutput]
    set do_print_results_option [write::getValue FluidDEM_CouplingParameters PrintResults]
    dict set project_parameters_dict "do_print_results_option"                          $do_print_results_option

    # output_interval
    set output_interval [write::getValue FluidDEM_CouplingParameters OutputInterval]
    dict set project_parameters_dict "output_interval"                                  $output_interval

    # coupling FDEMCoupling
    set coupling_level_type [write::getValue FDEMCoupling CouplingLevel]
    set interaction_start_time [write::getValue FDEMCoupling InteractionStart]
    dict set project_parameters_dict coupling "coupling_level_type"                             $coupling_level_type
    dict set project_parameters_dict coupling "interaction_start_time"                          $interaction_start_time

    set time_averaging_type [write::getValue FDEMfwCoupling TimeAveraging]
    dict set project_parameters_dict coupling forward_coupling "time_averaging_type"            $time_averaging_type

    set meso_scale_length [write::getValue FDEMbwCoupling MesoScaleLength]
    set shape_factor [write::getValue FDEMbwCoupling ShapeFactor]
    set filter_velocity_option [write::getValue FDEMbwCoupling FilterVelocity]
    set apply_time_filter [write::getValue FDEMbwCoupling ApplyTimeFilter]
    set min_fluid_fraction [write::getValue FDEMbwCoupling MinFluidFraction]
    set fluid_fraction_grad_type [write::getValue FDEMbwCoupling FluidFractGradT]
    set calculate_diffusivity_option [write::getValue FDEMbwCoupling CalcDiffusivity]
    set viscosity_modification_type [write::getValue FDEMbwCoupling ViscosityModif]

    dict set project_parameters_dict coupling backward_coupling "meso_scale_length"             $meso_scale_length
    dict set project_parameters_dict coupling backward_coupling "shape_factor"                  $shape_factor
    dict set project_parameters_dict coupling backward_coupling "filter_velocity_option"        $filter_velocity_option
    dict set project_parameters_dict coupling backward_coupling "apply_time_filter_to_fluid_fraction_option"   $apply_time_filter
    dict set project_parameters_dict coupling backward_coupling "min_fluid_fraction"            $min_fluid_fraction
    dict set project_parameters_dict coupling backward_coupling "fluid_fraction_grad_type"      $fluid_fraction_grad_type
    dict set project_parameters_dict coupling backward_coupling "calculate_diffusivity_option"  $calculate_diffusivity_option
    dict set project_parameters_dict coupling backward_coupling "viscosity_modification_type"   $viscosity_modification_type

    # derivative recovery
    dict set project_parameters_dict derivative_recovery "store_full_gradient_option" "false"

    # custom dem
    set do_search_neighbours [write::getValue FDEMCoupling NeighbourSearch]
    set translational_integration_scheme [write::getValue FDEMCoupling TranslatIntScheme]
    dict set project_parameters_dict custom_dem "do_search_neighbours" $do_search_neighbours
    dict set project_parameters_dict custom_dem "translational_integration_scheme" $translational_integration_scheme


    # dem_nodal_results
    set REYNOLDS_NUMBER [write::getValue NodalResults DEMNodalResults ReynoldsN]
    set SLIP_VELOCITY [write::getValue NodalResults DEMNodalResults SlipVelocity]
    set RADIUS [write::getValue NodalResults DEMNodalResults Radius]
    set ANGULAR_VELOCITY [write::getValue NodalResults DEMNodalResults AngularVelocity]
    set ELASTIC_FORCES [write::getValue NodalResults DEMNodalResults ElasForces]
    set CONTACT_FORCES [write::getValue NodalResults DEMNodalResults ContactForces]
    set TOTAL_FORCES [write::getValue NodalResults DEMNodalResults TotalForces]
    set PRESSURE [write::getValue NodalResults DEMNodalResults Pressure]
    set PRESSURE_GRAD_PROJECTED [write::getValue NodalResults DEMNodalResults PressureGradientProj]
    set HYDRODYNAMIC_FORCE [write::getValue NodalResults DEMNodalResults HydrodynamicForce]
    set HYDRODYNAMIC_MOMENT [write::getValue NodalResults DEMNodalResults HydrodynamicMoment]
    set FLUID_VEL_PROJECTED [write::getValue NodalResults DEMNodalResults FluidVelocityProjected]
    set FLUID_VEL_PROJECTED_RATE [write::getValue NodalResults DEMNodalResults FluidVelocityProjectedRate]
    set FLUID_VEL_LAPL_PROJECTED [write::getValue NodalResults DEMNodalResults FluidVelocityLaplacianProjected]
    set FLUID_VEL_LAPL_RATE_PROJECTED [write::getValue NodalResults DEMNodalResults FluidVelocityLaplacianRateProjected]
    set FLUID_ACCEL_PROJECTED [write::getValue NodalResults DEMNodalResults FluidAccelProjected]
    set FLUID_FRACTION_PROJECTED [write::getValue NodalResults DEMNodalResults FluidFractionProjected]
    set FLUID_FRACTION_GRADIENT_PROJECTED [write::getValue NodalResults DEMNodalResults FluidFractionGradientProjected]
    set FLUID_VISCOSITY_PROJECTED [write::getValue NodalResults DEMNodalResults FluidViscosityProjected]
    set BUOYANCY [write::getValue NodalResults DEMNodalResults Buoyancy]
    set DRAG_FORCE [write::getValue NodalResults DEMNodalResults DragForce]
    set VIRTUAL_MASS_FORCE [write::getValue NodalResults DEMNodalResults VirtualMassForce]
    set BASSET_FORCE [write::getValue NodalResults DEMNodalResults BassetForce]
    set LIFT_FORCE [write::getValue NodalResults DEMNodalResults LiftForce]
    set IMPACT_WEAR [write::getValue NodalResults DEMNodalResults ImpactWear]
    set NON_DIMENSIONAL_VOLUME_WEAR [write::getValue NodalResults DEMNodalResults NonDimensionalVolWear]

    dict set project_parameters_dict dem_nodal_results "REYNOLDS_NUMBER" $REYNOLDS_NUMBER

    dict set project_parameters_dict dem_nodal_results "SLIP_VELOCITY" SLIP_VELOCITY
    dict set project_parameters_dict dem_nodal_results "RADIUS" $RADIUS
    dict set project_parameters_dict dem_nodal_results "ANGULAR_VELOCITY" $ANGULAR_VELOCITY
    dict set project_parameters_dict dem_nodal_results "ELASTIC_FORCES" $ELASTIC_FORCES
    dict set project_parameters_dict dem_nodal_results "CONTACT_FORCES" $CONTACT_FORCES
    dict set project_parameters_dict dem_nodal_results "TOTAL_FORCES" $TOTAL_FORCES
    dict set project_parameters_dict dem_nodal_results "PRESSURE" $PRESSURE
    dict set project_parameters_dict dem_nodal_results "PRESSURE_GRAD_PROJECTED" $PRESSURE_GRAD_PROJECTED
    dict set project_parameters_dict dem_nodal_results "HYDRODYNAMIC_FORCE" $HYDRODYNAMIC_FORCE
    dict set project_parameters_dict dem_nodal_results "HYDRODYNAMIC_MOMENT" $HYDRODYNAMIC_MOMENT
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_PROJECTED" $FLUID_VEL_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_PROJECTED_RATE" $FLUID_VEL_PROJECTED_RATE
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_LAPL_PROJECTED" $FLUID_VEL_LAPL_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_LAPL_RATE_PROJECTED" $FLUID_VEL_LAPL_RATE_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_ACCEL_PROJECTED" $FLUID_ACCEL_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_FRACTION_PROJECTED" $FLUID_FRACTION_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_FRACTION_GRADIENT_PROJECTED" $FLUID_FRACTION_GRADIENT_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_VISCOSITY_PROJECTED" $FLUID_VISCOSITY_PROJECTED
    dict set project_parameters_dict dem_nodal_results "BUOYANCY" $BUOYANCY
    dict set project_parameters_dict dem_nodal_results "DRAG_FORCE" $DRAG_FORCE
    dict set project_parameters_dict dem_nodal_results "VIRTUAL_MASS_FORCE" $VIRTUAL_MASS_FORCE
    dict set project_parameters_dict dem_nodal_results "BASSET_FORCE" $BASSET_FORCE
    dict set project_parameters_dict dem_nodal_results "LIFT_FORCE" $LIFT_FORCE
    dict set project_parameters_dict dem_nodal_results "IMPACT_WEAR" $IMPACT_WEAR
    dict set project_parameters_dict dem_nodal_results "NON_DIMENSIONAL_VOLUME_WEAR" $NON_DIMENSIONAL_VOLUME_WEAR



    # fluid_nodal_results
    set MATERIAL_ACCELERATION [write::getValue NodalResults FluidNodalResults MaterialAccel]
    set FLUID_GRADIENT [write::getValue NodalResults FluidNodalResults VelocityGrad]
    set PRESSURE_GRADIENT [write::getValue NodalResults FluidNodalResults PressureGrad]
    set FLUID_FRACTION [write::getValue NodalResults FluidNodalResults FluidFraction]
    set DISPERSE_FRACTION [write::getValue NodalResults FluidNodalResults DisperseFraction]
    set PARTICLE_VEL_FILTERED [write::getValue NodalResults FluidNodalResults ParticleVelFiltered]
    set FLUID_FRACTION_GRADIENT [write::getValue NodalResults FluidNodalResults FluidFractionGrad]
    set FLUID_FRACTION_RATE [write::getValue NodalResults FluidNodalResults FluidFractionRate]
    set HYDRODYNAMIC_REACTION [write::getValue NodalResults FluidNodalResults HydrodynamicReaction]
    set VISCOSITY [write::getValue NodalResults FluidNodalResults Viscosity]
    set DISTANCE [write::getValue NodalResults FluidNodalResults Distance]
    set SLIP_VELOCITY [write::getValue NodalResults FluidNodalResults SlipVelocity]
    set VORTICITY [write::getValue NodalResults FluidNodalResults Vorticity]
    set VELOCITY_LAPLACIAN [write::getValue NodalResults FluidNodalResults VelocityLaplacian]
    set VELOCITY_LAPLACIAN_RATE [write::getValue NodalResults FluidNodalResults VelocityLaplacianRate]
    set BODY_FORCE [write::getValue NodalResults FluidNodalResults BodyForce]


    dict set project_parameters_dict fluid_nodal_results "MATERIAL_ACCELERATION" $MaterialAccel
    dict set project_parameters_dict fluid_nodal_results "FLUID_GRADIENT" $VelocityGrad
    dict set project_parameters_dict fluid_nodal_results "PRESSURE_GRADIENT" $PressureGrad
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION" $FluidFraction

    dict set project_parameters_dict fluid_nodal_results "DISPERSE_FRACTION" $DisperseFraction
    dict set project_parameters_dict fluid_nodal_results "PARTICLE_VEL_FILTERED" $ParticleVelFiltered

    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION_GRADIENT" $FluidFractionGrad
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION_RATE" $FluidFractionRate
    dict set project_parameters_dict fluid_nodal_results "HYDRODYNAMIC_REACTION" $HydrodynamicReaction

    dict set project_parameters_dict fluid_nodal_results "VISCOSITY" $Viscosity
    dict set project_parameters_dict fluid_nodal_results "DISTANCE" $Distance
    dict set project_parameters_dict fluid_nodal_results "SLIP_VELOCITY" $SlipVelocity
    dict set project_parameters_dict fluid_nodal_results "VORTICITY" $Vorticity
    dict set project_parameters_dict fluid_nodal_results "VELOCITY_LAPLACIAN" $VelocityLaplacian
    dict set project_parameters_dict fluid_nodal_results "VELOCITY_LAPLACIAN_RATE" $VelocityLaplacianRate
    dict set project_parameters_dict fluid_nodal_results "BODY_FORCE" $BodyForce

    W "7"

    # set time_things [DEM::write::GetTimeSettings]
    #     set MaxTimeStep [dict get $time_things DeltaTime]
    # dict set project_parameters_dict "MaxTimeStep"                      $MaxTimeStep
    #     set TTime [dict get $time_things EndTime]
    # dict set project_parameters_dict "FinalTime"                        $TTime
    # # dict set project_parameters_dict "ControlTime"                      [write::getValue DEMTimeParameters ScreenInfoOutput]
    # # dict set project_parameters_dict "NeighbourSearchFrequency"         [write::getValue DEMTimeParameters NeighbourSearchFrequency]

    # Properties
    set properties_dict [dict create]
    W "7.1"
    set partgroup [write::getPartsSubModelPartId]
    W "7.2"
    dict set properties_dict "model_part_name" [write::GetModelPartNameWithParent [concat [lindex $partgroup 0]]]
    W "7.3"
    dict set properties_dict properties_id 1
    dict set properties_dict hydrodynamic_law_parameters                                         "name"                         "HydrodynamicInteractionLaw"
    dict set properties_dict hydrodynamic_law_parameters buoyancy_parameters                     "name"                         "default"
    dict set properties_dict hydrodynamic_law_parameters inviscid_force_parameters               "name"                         "default"
    dict set properties_dict hydrodynamic_law_parameters inviscid_force_parameters               "do_apply_faxen_corrections"   "false"
    dict set properties_dict hydrodynamic_law_parameters drag_parameters                         "name"                         "StokesDragLaw"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters                "name"                         "default"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters                "quadrature_order"             "2 "

    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "do_use_mae"                   "false"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "m"                            "10"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "window_time_interval"         "0.1,"
    dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "type"                         "4"

    # dict set properties_dict hydrodynamic_law_parameters vorticity_induced_lift_parameters "name" "default"
    # dict set properties_dict hydrodynamic_law_parameters rotation_induced_lift_parameters "name" "default"
    # dict set properties_dict hydrodynamic_law_parameters steady_viscous_torque_parameters "name" "default"
    W "8"
    set properties_list [list ]
    lappend properties_list $properties_dict
    dict set project_parameters_dict properties $properties_list

    W "9"
    # output configuration  #TODO to be checked/modified by GCasas
    dict set project_parameters_dict sdem_output_processes [write::GetDefaultOutputProcessDict $Fluid::app_id]
    W "10"
    FluidDEM::write::InitExternalProjectParameters
    W "11"
    dict set project_parameters_dict dem_parameters $FluidDEM::write::dem_project_parameters
    W "12"
    dict set project_parameters_dict dem_parameters "solver_settings" "strategy" "swimming_sphere_strategy"
    W "13"
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
