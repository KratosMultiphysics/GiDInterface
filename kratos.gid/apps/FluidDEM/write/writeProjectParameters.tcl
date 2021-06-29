# Project Parameters
proc ::FluidDEM::write::getParametersDict { } {
    set project_parameters_dict [dict create]

    # # Gravity
    dict set project_parameters_dict gravity_parameters [FluidDEM::write::GetGravityDict]

    # Time_stepping
    set automatic_time_step [write::getValue FDEMTimeParameters AutomaticDeltaTime]
    set time_step [write::getValue FDEMTimeParameters DEMDeltaTime]
    dict set project_parameters_dict time_stepping "automatic_time_step" $automatic_time_step
    dict set project_parameters_dict time_stepping "time_step" $time_step

    # output_interval
    set output_interval [write::getValue FDEMTimeParameters OutputInterval]
    dict set project_parameters_dict "output_interval" $output_interval

    # non newtonian fluid
    dict set project_parameters_dict non_newtonian_fluid [FluidDEM::write::GetNonNewtonianFluidDict]

    # Problem data  - calling directly GetDefaultProblemDataDict should be enough
    dict set project_parameters_dict problem_data [write::GetDefaultProblemDataDict $Fluid::app_id]

    #set do_print_results_option [write::getValue FluidDEM_GeneralParameters PrintResults]
    dict set project_parameters_dict "do_print_results_option" true

    # coupling FDEMCoupling
    dict set project_parameters_dict coupling [FluidDEM::write::GetCouplingDict]

    # custom dem
    set do_search_neighbours [write::getValue FDEMCoupling NeighbourSearch]
    set translational_integration_scheme [write::getValue FDEMCoupling TranslatIntScheme]
    dict set project_parameters_dict custom_dem "do_solve_dem" true
    dict set project_parameters_dict custom_dem "do_search_neighbours" $do_search_neighbours
    dict set project_parameters_dict custom_dem "type_of_dem_inlet" VelocityImposed
    dict set project_parameters_dict custom_dem "translational_integration_scheme" $translational_integration_scheme

    # nodal results
    dict set project_parameters_dict dem_nodal_results [FluidDEM::write::GetDEMNodalResultsDict]
    dict set project_parameters_dict fluid_nodal_results [FluidDEM::write::GetFluidNodalResultsDict]
    
    # Hydrodynamic Properties
    dict set project_parameters_dict properties [FluidDEM::write::GetHydrodynamicPropertiesList]
    
    # output configuration  #TODO to be checked/modified by GCasas
    dict set project_parameters_dict sdem_output_processes [write::GetDefaultOutputProcessDict $Fluid::app_id]
    FluidDEM::write::InitExternalProjectParameters
    dict set project_parameters_dict dem_parameters $FluidDEM::write::dem_project_parameters
    dict set project_parameters_dict dem_parameters "solver_settings" "strategy" "swimming_sphere_strategy"
    dict set project_parameters_dict fluid_parameters $FluidDEM::write::fluid_project_parameters
    
    # Update the fluid element
    set element_name {*}[FluidDEM::write::GetCurrentFluidElementName]
    dict set project_parameters_dict fluid_parameters solver_settings formulation element_type $element_name
    if { $element_name eq "qsvmsDEM" } {
        dict set project_parameters_dict fluid_parameters solver_settings solver_type "MonolithicDEM"
        dict unset project_parameters_dict fluid_parameters solver_settings time_scheme
    }

    return $project_parameters_dict
}

proc FluidDEM::write::GetHydrodynamicPropertiesList { } {
    set properties_list [list ]

    set hydrodynamic_laws_dict [GetHydrodynamicLawsDict]
    set mat_dict [write::getMatDict]
    #set mat_dict [dict merge [write::getMatDict] $DEM::write::inletProperties]
    foreach property [dict keys $mat_dict] {
        if { [dict get $mat_dict $property APPID] eq "DEM"} {
            if {"hydrodynamic_law" in [dict keys $mat_dict $property ]} {
                set properties_dict [dict create]
                set law [dict get $hydrodynamic_laws_dict [dict get $mat_dict $property hydrodynamic_law]]
                #WV law
                set partgroup [write::getPartsSubModelPartId]
                dict set properties_dict properties_id [dict get $mat_dict $property MID]
                dict set properties_dict hydrodynamic_law_parameters                                         "name"                         [dict get $law hydrodynamic_law_name]
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
                lappend properties_list $properties_dict
            }
        }
    }

    return $properties_list
}

proc FluidDEM::write::GetFluidNodalResultsDict { } {
    set fluid_nodal_results_dict [dict create ]

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
    set VORTICITY                   [write::getValue FluidNodalResults Vorticity]
    set VELOCITY_LAPLACIAN          [write::getValue FluidNodalResults VelocityLaplacian]
    set VELOCITY_LAPLACIAN_RATE     [write::getValue FluidNodalResults VelocityLaplacianRate]
    set BODY_FORCE                  [write::getValue FluidNodalResults BodyForce]
    set VELOCITY                    [write::getValue FluidNodalResults FVelocity]
    set PRESSURE                    [write::getValue FluidNodalResults FPressure]

    dict set fluid_nodal_results_dict "BODY_FORCE" $BODY_FORCE
    dict set fluid_nodal_results_dict "DISPERSE_FRACTION" $DISPERSE_FRACTION
    dict set fluid_nodal_results_dict "DISTANCE" $DISTANCE
    dict set fluid_nodal_results_dict "FLUID_FRACTION_GRADIENT" $FLUID_FRACTION_GRADIENT
    dict set fluid_nodal_results_dict "FLUID_FRACTION_RATE" $FLUID_FRACTION_RATE
    dict set fluid_nodal_results_dict "FLUID_FRACTION" $FLUID_FRACTION
    dict set fluid_nodal_results_dict "HYDRODYNAMIC_REACTION" $HYDRODYNAMIC_REACTION
    dict set fluid_nodal_results_dict "MATERIAL_ACCELERATION" $MATERIAL_ACCELERATION
    dict set fluid_nodal_results_dict "PARTICLE_VEL_FILTERED" $PARTICLE_VEL_FILTERED
    dict set fluid_nodal_results_dict "PRESSURE_GRADIENT" $PRESSURE_GRADIENT
    dict set fluid_nodal_results_dict "PRESSURE" $PRESSURE
    dict set fluid_nodal_results_dict "VELOCITY_GRADIENT" false
    dict set fluid_nodal_results_dict "VELOCITY_LAPLACIAN_RATE" $VELOCITY_LAPLACIAN_RATE
    dict set fluid_nodal_results_dict "VELOCITY_LAPLACIAN" $VELOCITY_LAPLACIAN
    dict set fluid_nodal_results_dict "VELOCITY" $VELOCITY
    dict set fluid_nodal_results_dict "VISCOSITY" $VISCOSITY
    dict set fluid_nodal_results_dict "VORTICITY" $VORTICITY

    return $fluid_nodal_results_dict
}


proc FluidDEM::write::GetDEMNodalResultsDict { } {
    set dem_nodal_results_dict [dict create ]

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
    # set PRESSURE                            [write::getValue DEMNodalResults Pressure]
    set PRESSURE_GRAD_PROJECTED             [write::getValue DEMNodalResults PressureGradientProj]
    set RADIUS                              [write::getValue DEMNodalResults Radius]
    set REYNOLDS_NUMBER                     [write::getValue DEMNodalResults ReynoldsN]
    set SLIP_VELOCITY                       [write::getValue DEMNodalResults SlipVelocity]
    set TOTAL_FORCES                        [write::getValue DEMNodalResults TotalForces]
    set VIRTUAL_MASS_FORCE                  [write::getValue DEMNodalResults VirtualMassForce]

    dict set dem_nodal_results_dict "ANGULAR_VELOCITY" $ANGULAR_VELOCITY
    dict set dem_nodal_results_dict "BASSET_FORCE" $BASSET_FORCE
    dict set dem_nodal_results_dict "BUOYANCY" $BUOYANCY
    dict set dem_nodal_results_dict "CONTACT_FORCES" $CONTACT_FORCES
    dict set dem_nodal_results_dict "DRAG_FORCE" $DRAG_FORCE
    dict set dem_nodal_results_dict "ELASTIC_FORCES" $ELASTIC_FORCES
    dict set dem_nodal_results_dict "FLUID_ACCEL_PROJECTED" $FLUID_ACCEL_PROJECTED
    dict set dem_nodal_results_dict "FLUID_FRACTION_GRADIENT_PROJECTED" $FLUID_FRACTION_GRADIENT_PROJECTED
    dict set dem_nodal_results_dict "FLUID_FRACTION_PROJECTED" $FLUID_FRACTION_PROJECTED
    dict set dem_nodal_results_dict "FLUID_VEL_LAPL_PROJECTED" $FLUID_VEL_LAPL_PROJECTED
    dict set dem_nodal_results_dict "FLUID_VEL_LAPL_RATE_PROJECTED" $FLUID_VEL_LAPL_RATE_PROJECTED
    dict set dem_nodal_results_dict "FLUID_VEL_PROJECTED_RATE" $FLUID_VEL_PROJECTED_RATE
    dict set dem_nodal_results_dict "FLUID_VEL_PROJECTED" $FLUID_VEL_PROJECTED
    dict set dem_nodal_results_dict "FLUID_VISCOSITY_PROJECTED" $FLUID_VISCOSITY_PROJECTED
    dict set dem_nodal_results_dict "HYDRODYNAMIC_FORCE" $HYDRODYNAMIC_FORCE
    dict set dem_nodal_results_dict "HYDRODYNAMIC_MOMENT" $HYDRODYNAMIC_MOMENT
    dict set dem_nodal_results_dict "IMPACT_WEAR" $IMPACT_WEAR
    dict set dem_nodal_results_dict "LIFT_FORCE" $LIFT_FORCE
    dict set dem_nodal_results_dict "NON_DIMENSIONAL_VOLUME_WEAR" $NON_DIMENSIONAL_VOLUME_WEAR
    dict set dem_nodal_results_dict "PRESSURE_GRAD_PROJECTED" $PRESSURE_GRAD_PROJECTED
    dict set dem_nodal_results_dict "RADIUS" $RADIUS
    dict set dem_nodal_results_dict "REYNOLDS_NUMBER" $REYNOLDS_NUMBER
    dict set dem_nodal_results_dict "SLIP_VELOCITY" $SLIP_VELOCITY
    dict set dem_nodal_results_dict "TOTAL_FORCES" $TOTAL_FORCES
    dict set dem_nodal_results_dict "VIRTUAL_MASS_FORCE" $VIRTUAL_MASS_FORCE

    return $dem_nodal_results_dict
}

proc FluidDEM::write::GetNonNewtonianFluidDict { } {
    set non_newtonian_fluid_dict [dict create ]

    set non_newtonian_option        [write::getValue DEMFluidNonNewtonian non_newtonian_option]
    set yield_stress                [write::getValue DEMFluidNonNewtonian yield_stress]
    set regularization_coefficient  [write::getValue DEMFluidNonNewtonian regularization_coefficient]
    set power_law_tol               [write::getValue DEMFluidNonNewtonian power_law_tol]
    set power_law_k                 [write::getValue DEMFluidNonNewtonian power_law_k]
    set power_law_n                 [write::getValue DEMFluidNonNewtonian power_law_n]

    dict set pnon_newtonian_fluid_dict "non_newtonian_option"         $non_newtonian_option
    dict set pnon_newtonian_fluid_dict "power_law_k"                  $power_law_k
    dict set pnon_newtonian_fluid_dict "power_law_n"                  $power_law_n
    dict set pnon_newtonian_fluid_dict "yield_stress"                 $yield_stress
    dict set pnon_newtonian_fluid_dict "regularization_coefficient"   $regularization_coefficient
    dict set pnon_newtonian_fluid_dict "power_law_tol"                $power_law_tol

    return $non_newtonian_fluid_dict
}

proc ::FluidDEM::write::GetGravityDict { } {
    set gravity_dict [dict create ]

    # modulus
    set gravity_value [write::getValue DEMGravity GravityValue]
    dict set gravity_dict "modulus" $gravity_value

    # normalized direction
    set gravity_X [write::getValue DEMGravity Cx]
    set gravity_Y [write::getValue DEMGravity Cy]
    set gravity_Z [write::getValue DEMGravity Cz]
    lassign [MathUtils::VectorNormalized [list $gravity_X $gravity_Y $gravity_Z]] gravity_X gravity_Y gravity_Z
    dict set gravity_dict "direction" [list $gravity_X $gravity_Y $gravity_Z]

    return $gravity_dict
}

proc FluidDEM::write::GetCouplingDict { } {
    set coupling_dict [dict create ]
    set coupling_level_type [write::getValue FDEMCoupling CouplingLevel]
    set interaction_start_time [write::getValue FDEMCoupling InteractionStart]
    dict set coupling_dict "coupling_level_type" $coupling_level_type
    dict set coupling_dict "coupling_weighing_type" 2
    dict set coupling_dict "interaction_start_time" $interaction_start_time

    set time_averaging_type [write::getValue FDEMfwCoupling TimeAveraging]
    dict set coupling_dict forward_coupling "time_averaging_type" $time_averaging_type

    set meso_scale_length [write::getValue FDEMbwCoupling MesoScaleLength]
    set shape_factor [write::getValue FDEMbwCoupling ShapeFactor]
    set filter_velocity_option [write::getValue FDEMbwCoupling FilterVelocity]
    set apply_time_filter [write::getValue FDEMbwCoupling ApplyTimeFilter]
    set min_fluid_fraction [write::getValue FDEMbwCoupling MinFluidFraction]
    set fluid_fraction_grad_type [write::getValue FDEMbwCoupling FluidFractGradT]
    set calculate_diffusivity_option [write::getValue FDEMbwCoupling CalcDiffusivity]
    set viscosity_modification_type [write::getValue FDEMbwCoupling ViscosityModif]

    dict set coupling_dict backward_coupling "meso_scale_length" $meso_scale_length
    dict set coupling_dict backward_coupling "shape_factor" $shape_factor
    dict set coupling_dict backward_coupling "filter_velocity_option" $filter_velocity_option
    dict set coupling_dict backward_coupling "apply_time_filter_to_fluid_fraction_option" $apply_time_filter
    dict set coupling_dict backward_coupling "min_fluid_fraction" $min_fluid_fraction
    dict set coupling_dict backward_coupling "fluid_fraction_grad_type" $fluid_fraction_grad_type
    dict set coupling_dict backward_coupling "calculate_diffusivity_option" $calculate_diffusivity_option
    dict set coupling_dict backward_coupling "viscosity_modification_type" $viscosity_modification_type

    return $coupling_dict
}

proc FluidDEM::write::GetCurrentFluidElementName { } {
    set gnode [[customlib::GetBaseRoot] selectNodes "[spdAux::getRoute "FLParts"]/group"]
    set element [write::getValueByNode [$gnode selectNodes "./value\[@n = 'Element'\]"]]
    set element [::Model::getElement $element]
    set element_name [$element getAttribute "WriteName"]
    if {$element_name eq ""} {set element_name "vms"}
    return $element_name
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

    # DEM section
    #UpdateUniqueNames DEM
    apps::setActiveAppSoft DEM
    write::initWriteConfiguration [DEM::write::GetAttributes]
    set FluidDEM::write::dem_project_parameters [DEM::write::getParametersDict]

    apps::setActiveAppSoft FluidDEM
}
