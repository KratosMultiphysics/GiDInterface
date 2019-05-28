# Project Parameters
proc ::FluidDEM::write::getParametersDict { } {
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
    set time_step [write::getValue FDEMTimeParameters DEMDeltaTime]
    dict set project_parameters_dict time_stepping "automatic_time_step"                $automatic_time_step
    dict set project_parameters_dict time_stepping "time_step"                          $time_step

    # output_interval
    set output_interval [write::getValue FDEMTimeParameters OutputInterval]
    dict set project_parameters_dict "output_interval"                                  $output_interval

    # non newtonian fluid
    set non_newtonian_option        [write::getValue DEMFluidNonNewtonian non_newtonian_option]
    set yield_stress                [write::getValue DEMFluidNonNewtonian yield_stress]
    set regularization_coefficient  [write::getValue DEMFluidNonNewtonian regularization_coefficient]
    set power_law_tol               [write::getValue DEMFluidNonNewtonian power_law_tol]
    set power_law_k                 [write::getValue DEMFluidNonNewtonian power_law_k]
    set power_law_n                 [write::getValue DEMFluidNonNewtonian power_law_n]

    dict set project_parameters_dict non_newtonian_fluid "non_newtonian_option"         $non_newtonian_option
    dict set project_parameters_dict non_newtonian_fluid "power_law_k"                  $power_law_k
    dict set project_parameters_dict non_newtonian_fluid "power_law_n"                  $power_law_n
    dict set project_parameters_dict non_newtonian_fluid "yield_stress"                 $yield_stress
    dict set project_parameters_dict non_newtonian_fluid "regularization_coefficient"   $regularization_coefficient
    dict set project_parameters_dict non_newtonian_fluid "power_law_tol"                $power_law_tol


    # Problem data  - calling directly GetDefaultProblemDataDict should be enough
    dict set project_parameters_dict problem_data [write::GetDefaultProblemDataDict $Fluid::app_id]
    # set model_name [Kratos::GetModelName]
    # dict set project_parameters_dict problem_data                         $model_name
    # dict set project_parameters_dict "ControlTime"            [write::getValue DEMTimeParameters ScreenInfoOutput]

    #set do_print_results_option [write::getValue FluidDEM_GeneralParameters PrintResults]
    dict set project_parameters_dict "do_print_results_option"                          true

    # coupling FDEMCoupling
    set coupling_level_type [write::getValue FDEMCoupling CouplingLevel]
    set interaction_start_time [write::getValue FDEMCoupling InteractionStart]
    dict set project_parameters_dict coupling "coupling_level_type"                             $coupling_level_type
    dict set project_parameters_dict coupling "coupling_weighing_type"                         2
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

    # derivative recovery disabled by now
    #dict set project_parameters_dict derivative_recovery "store_full_gradient_option" "false"

    # custom dem
    set do_search_neighbours [write::getValue FDEMCoupling NeighbourSearch]
    set translational_integration_scheme [write::getValue FDEMCoupling TranslatIntScheme]
    dict set project_parameters_dict custom_dem "do_solve_dem" true
    dict set project_parameters_dict custom_dem "do_search_neighbours" $do_search_neighbours
    dict set project_parameters_dict custom_dem "type_of_dem_inlet" VelocityImposed
    dict set project_parameters_dict custom_dem "translational_integration_scheme" $translational_integration_scheme

    # dem_nodal_results
    set ANGULAR_VELOCITY                    [write::getValue DEMNodalResults AngularVelocity]
    set BASSET_FORCE                        [write::getValue DEMNodalResults BassetForce]
    set BUOYANCY                            [write::getValue DEMNodalResults Buoyancy]
    set CONTACT_FORCES                      [write::getValue DEMNodalResults ContactForces]
    set DRAG_FORCE                          [write::getValue DEMNodalResults DragForce]
    set ELASTIC_FORCES                      [write::getValue DEMNodalResults ElasForces]
    set FLUID_ACCEL_PROJECTED               [write::getValue DEMNodalResults FluidAccelProjected]
    set FLUID_FRACTION_GRADIENT_PROJECTED   [write::getValue DEMNodalResults FluidFractionGradientProjected]
    set FLUID_FRACTION_PROJECTED            [write::getValue DEMNodalResults FluidFractionProjected]
    set FLUID_VEL_LAPL_PROJECTED            [write::getValue DEMNodalResults FluidVelocityLaplacianProjected]
    set FLUID_VEL_LAPL_RATE_PROJECTED       [write::getValue DEMNodalResults FluidVelocityLaplacianRateProjected]
    set FLUID_VEL_PROJECTED                 [write::getValue DEMNodalResults FluidVelocityProjected]
    set FLUID_VEL_PROJECTED_RATE            [write::getValue DEMNodalResults FluidVelocityProjectedRate]
    set FLUID_VISCOSITY_PROJECTED           [write::getValue DEMNodalResults FluidViscosityProjected]
    set HYDRODYNAMIC_FORCE                  [write::getValue DEMNodalResults HydrodynamicForce]
    set HYDRODYNAMIC_MOMENT                 [write::getValue DEMNodalResults HydrodynamicMoment]
    set IMPACT_WEAR                         [write::getValue DEMNodalResults ImpactWear]
    set LIFT_FORCE                          [write::getValue DEMNodalResults LiftForce]
    set NON_DIMENSIONAL_VOLUME_WEAR         [write::getValue DEMNodalResults NonDimensionalVolWear]
    set PRESSURE                            [write::getValue DEMNodalResults Pressure]
    set PRESSURE_GRAD_PROJECTED             [write::getValue DEMNodalResults PressureGradientProj]
    set RADIUS                              [write::getValue DEMNodalResults Radius]
    set REYNOLDS_NUMBER                     [write::getValue DEMNodalResults ReynoldsN]
    set SLIP_VELOCITY                       [write::getValue DEMNodalResults SlipVelocity]
    set TOTAL_FORCES                        [write::getValue DEMNodalResults TotalForces]
    set VIRTUAL_MASS_FORCE                  [write::getValue DEMNodalResults VirtualMassForce]

    dict set project_parameters_dict dem_nodal_results "ANGULAR_VELOCITY" $ANGULAR_VELOCITY
    dict set project_parameters_dict dem_nodal_results "BASSET_FORCE" $BASSET_FORCE
    dict set project_parameters_dict dem_nodal_results "BUOYANCY" $BUOYANCY
    dict set project_parameters_dict dem_nodal_results "CONTACT_FORCES" $CONTACT_FORCES
    dict set project_parameters_dict dem_nodal_results "DRAG_FORCE" $DRAG_FORCE
    dict set project_parameters_dict dem_nodal_results "ELASTIC_FORCES" $ELASTIC_FORCES
    dict set project_parameters_dict dem_nodal_results "FLUID_ACCEL_PROJECTED" $FLUID_ACCEL_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_FRACTION_GRADIENT_PROJECTED" $FLUID_FRACTION_GRADIENT_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_FRACTION_PROJECTED" $FLUID_FRACTION_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_LAPL_PROJECTED" $FLUID_VEL_LAPL_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_LAPL_RATE_PROJECTED" $FLUID_VEL_LAPL_RATE_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_PROJECTED_RATE" $FLUID_VEL_PROJECTED_RATE
    dict set project_parameters_dict dem_nodal_results "FLUID_VEL_PROJECTED" $FLUID_VEL_PROJECTED
    dict set project_parameters_dict dem_nodal_results "FLUID_VISCOSITY_PROJECTED" $FLUID_VISCOSITY_PROJECTED
    dict set project_parameters_dict dem_nodal_results "HYDRODYNAMIC_FORCE" $HYDRODYNAMIC_FORCE
    dict set project_parameters_dict dem_nodal_results "HYDRODYNAMIC_MOMENT" $HYDRODYNAMIC_MOMENT
    dict set project_parameters_dict dem_nodal_results "IMPACT_WEAR" $IMPACT_WEAR
    dict set project_parameters_dict dem_nodal_results "LIFT_FORCE" $LIFT_FORCE
    dict set project_parameters_dict dem_nodal_results "NON_DIMENSIONAL_VOLUME_WEAR" $NON_DIMENSIONAL_VOLUME_WEAR
    dict set project_parameters_dict dem_nodal_results "PRESSURE_GRAD_PROJECTED" $PRESSURE_GRAD_PROJECTED
    dict set project_parameters_dict dem_nodal_results "PRESSURE" $PRESSURE
    dict set project_parameters_dict dem_nodal_results "RADIUS" $RADIUS
    dict set project_parameters_dict dem_nodal_results "REYNOLDS_NUMBER" $REYNOLDS_NUMBER
    dict set project_parameters_dict dem_nodal_results "SLIP_VELOCITY" $SLIP_VELOCITY
    dict set project_parameters_dict dem_nodal_results "TOTAL_FORCES" $TOTAL_FORCES
    dict set project_parameters_dict dem_nodal_results "VIRTUAL_MASS_FORCE" $VIRTUAL_MASS_FORCE

    # fluid_nodal_results
    set MATERIAL_ACCELERATION       [write::getValue FluidNodalResults MaterialAccel]
    set VELOCITY_GRADIENT           [write::getValue FluidNodalResults VelocityGrad]
    set PRESSURE_GRADIENT           [write::getValue FluidNodalResults PressureGrad]
    set FLUID_FRACTION              [write::getValue FluidNodalResults FluidFraction]
    set DISPERSE_FRACTION           [write::getValue FluidNodalResults DisperseFraction]
    set PARTICLE_VEL_FILTERED       [write::getValue FluidNodalResults ParticleVelFiltered]
    set FLUID_FRACTION_GRADIENT     [write::getValue FluidNodalResults FluidFractionGrad]
    set FLUID_FRACTION_RATE         [write::getValue FluidNodalResults FluidFractionRate]
    set HYDRODYNAMIC_REACTION       [write::getValue FluidNodalResults HydrodynamicReaction]
    set VISCOSITY                   [write::getValue FluidNodalResults Viscosity]
    set DISTANCE                    [write::getValue FluidNodalResults Distance]
    set SLIP_VELOCITY               [write::getValue FluidNodalResults SlipVelocity]
    set VORTICITY                   [write::getValue FluidNodalResults Vorticity]
    set VELOCITY_LAPLACIAN          [write::getValue FluidNodalResults VelocityLaplacian]
    set VELOCITY_LAPLACIAN_RATE     [write::getValue FluidNodalResults VelocityLaplacianRate]
    set BODY_FORCE                  [write::getValue FluidNodalResults BodyForce]
    set VELOCITY                    [write::getValue FluidNodalResults FVelocity]
    set PRESSURE                    [write::getValue FluidNodalResults FPressure]

    dict set project_parameters_dict fluid_nodal_results "BODY_FORCE" $BODY_FORCE
    dict set project_parameters_dict fluid_nodal_results "DISPERSE_FRACTION" $DISPERSE_FRACTION
    dict set project_parameters_dict fluid_nodal_results "DISTANCE" $DISTANCE
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION_GRADIENT" $FLUID_FRACTION_GRADIENT
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION_RATE" $FLUID_FRACTION_RATE
    dict set project_parameters_dict fluid_nodal_results "FLUID_FRACTION" $FLUID_FRACTION
    dict set project_parameters_dict fluid_nodal_results "HYDRODYNAMIC_REACTION" $HYDRODYNAMIC_REACTION
    dict set project_parameters_dict fluid_nodal_results "MATERIAL_ACCELERATION" $MATERIAL_ACCELERATION
    dict set project_parameters_dict fluid_nodal_results "PARTICLE_VEL_FILTERED" $PARTICLE_VEL_FILTERED
    dict set project_parameters_dict fluid_nodal_results "PRESSURE_GRADIENT" $PRESSURE_GRADIENT
    dict set project_parameters_dict fluid_nodal_results "PRESSURE" $PRESSURE
    dict set project_parameters_dict fluid_nodal_results "SLIP_VELOCITY" $SLIP_VELOCITY
    dict set project_parameters_dict fluid_nodal_results "VELOCITY_GRADIENT" false
    dict set project_parameters_dict fluid_nodal_results "VELOCITY_LAPLACIAN_RATE" $VELOCITY_LAPLACIAN_RATE
    dict set project_parameters_dict fluid_nodal_results "VELOCITY_LAPLACIAN" $VELOCITY_LAPLACIAN
    dict set project_parameters_dict fluid_nodal_results "VELOCITY" $VELOCITY
    dict set project_parameters_dict fluid_nodal_results "VISCOSITY" $VISCOSITY
    dict set project_parameters_dict fluid_nodal_results "VORTICITY" $VORTICITY

    # set time_things [DEM::write::GetTimeSettings]
    #     set MaxTimeStep [dict get $time_things DeltaTime]
    # dict set project_parameters_dict "MaxTimeStep"                      $MaxTimeStep
    #     set TTime [dict get $time_things EndTime]
    # dict set project_parameters_dict "FinalTime"                        $TTime
    # # dict set project_parameters_dict "ControlTime"                      [write::getValue DEMTimeParameters ScreenInfoOutput]
    # # dict set project_parameters_dict "NeighbourSearchFrequency"         [write::getValue DEMTimeParameters NeighbourSearchFrequency]

    # Properties
    set hydrodynamic_laws_dict [GetHydrodynamicLawsDict]
    set properties_list [list ]
    set mat_dict [dict merge [write::getMatDict] $DEM::write::inletProperties]
    foreach property [dict keys $mat_dict] {
        if { [dict get $mat_dict $property APPID] eq "DEM"} {
            set properties_dict [dict create]
            set law [dict get $hydrodynamic_laws_dict [dict get $mat_dict $property hydrodynamic_law]]
            #WV law
            set partgroup [write::getPartsSubModelPartId]
            dict set properties_dict properties_id [dict get $mat_dict $property MID]
            dict set properties_dict hydrodynamic_law_parameters                                         "name"                         HydrodynamicInteractionLaw
            dict set properties_dict hydrodynamic_law_parameters buoyancy_parameters                     "name"                         [dict get $law buoyancy_parameters]
            dict set properties_dict hydrodynamic_law_parameters inviscid_force_parameters               "name"                         [dict get $law inviscid_force_parameters]
            dict set properties_dict hydrodynamic_law_parameters inviscid_force_parameters               "do_apply_faxen_corrections"   [dict get $law do_apply_faxen_corrections]
            dict set properties_dict hydrodynamic_law_parameters drag_parameters                         "name"                         [dict get $law drag_parameters]
            dict set properties_dict hydrodynamic_law_parameters history_force_parameters                "name"                         [dict get $law history_force_parameters]
            dict set properties_dict hydrodynamic_law_parameters history_force_parameters                "quadrature_order"             [dict get $law quadrature_order]
            dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "do_use_mae"                   [dict get $law do_use_mae]
            dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "m"                            [dict get $law m]
            dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "window_time_interval"         [dict get $law window_time_interval]
            dict set properties_dict hydrodynamic_law_parameters history_force_parameters mae_parameters "type"                         [dict get $law type]
            # dict set properties_dict hydrodynamic_law_parameters vorticity_induced_lift_parameters "name" "default"
            # dict set properties_dict hydrodynamic_law_parameters rotation_induced_lift_parameters "name" "default"
            # dict set properties_dict hydrodynamic_law_parameters steady_viscous_torque_parameters "name" "default"
            lappend properties_list $properties_dict
        }
    }

    dict set project_parameters_dict properties $properties_list

    # output configuration  #TODO to be checked/modified by GCasas
    dict set project_parameters_dict sdem_output_processes [write::GetDefaultOutputProcessDict $Fluid::app_id]
    FluidDEM::write::InitExternalProjectParameters
    dict set project_parameters_dict dem_parameters $FluidDEM::write::dem_project_parameters
    dict set project_parameters_dict dem_parameters "solver_settings" "strategy" "swimming_sphere_strategy"
    dict set project_parameters_dict fluid_parameters $FluidDEM::write::fluid_project_parameters
    # set FluidDEM::write::general_project_parameters [getParametersDict]
    # dict set project_parameters_dict $FluidDEM::write::general_project_parameters
    return $project_parameters_dict
}

proc FluidDEM::write::GetHydrodynamicLawsDict { } {
    set laws [dict create ]
    set dem_hydrodynamic_law_nodes [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute "DEMFluidHydrodynamicLaw"]/blockdata"]
    foreach hydro_law $dem_hydrodynamic_law_nodes {
        set law [dict create]
        set law_name [$hydro_law @name]
        dict set law name $law_name
        foreach value [$hydro_law getElementsByTagName "value"] {
            dict set law [$value @n] [write::getValueByNode $value]
        }
        dict set laws $law_name $law
    }
    return $laws
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
