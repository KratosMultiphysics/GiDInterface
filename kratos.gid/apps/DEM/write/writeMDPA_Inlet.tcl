proc DEM::write::WriteMDPAInlet { } {
    # Headers
    write::writeModelPartData

    writeMaterialsInlet

    # Nodal coordinates (only for DEM Parts <inefficient> )
    write::writeNodalCoordinatesOnGroups [GetInletGroups]
    
    # SubmodelParts
    writeInletMeshes
}

proc DEM::write::GetInletGroups { } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Inlet'\]/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::writeInletMeshes { } {
    variable inletProperties
    
    foreach groupid [dict keys $inletProperties ] {
        set what nodal
        if {![dict exists $::write::submodelparts [list Inlet ${groupid}]]} {
            set mid [expr [llength [dict keys $::write::submodelparts]] +1]
            set good_name [write::transformGroupName $groupid]
            set mid "Inlet_${good_name}"
            dict set ::write::submodelparts [list Inlet ${groupid}] $mid
            set gdict [dict create]
            set f "%10i\n"
            set f [subst $f]
            set group_real_name [write::GetWriteGroupName $groupid]
            dict set gdict $group_real_name $f
            write::WriteString "Begin SubModelPart $mid // Group $groupid // Subtree Inlet"
            write::WriteString "    Begin SubModelPartData"
            write::WriteString "        PROPERTIES_ID [dict get $inletProperties $groupid MID]"
            write::WriteString "        RIGID_BODY_MOTION 0"
            write::WriteString "        IDENTIFIER $mid"
            write::WriteString "        INJECTOR_ELEMENT_TYPE [dict get $inletProperties $groupid ELEMENT_TYPE]"
            write::WriteString "        ELEMENT_TYPE [dict get $inletProperties $groupid ELEMENT_TYPE]"
            write::WriteString "        CONTAINS_CLUSTERS 0"
            set velocity [dict get $inletProperties $groupid VELOCITY_MODULUS]
            set velocity_X [dict get $inletProperties $groupid DIRECTION_VECTORX]
            set velocity_Y [dict get $inletProperties $groupid DIRECTION_VECTORY]
            set velocity_Z [dict get $inletProperties $groupid DIRECTION_VECTORZ]
            lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
            lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
            write::WriteString "        VELOCITY \[3\] ($vx, $vy, $vz)"
            write::WriteString "        MAX_RAND_DEVIATION_ANGLE [dict get $inletProperties $groupid MAX_RAND_DEVIATION_ANGLE]"
            set type_of_measurement [dict get $inletProperties $groupid FLOW_MEASUREMENT]
            if {$type_of_measurement eq "Kilograms"} {
                set number_of_particles 200.0
                set mass_flow_option 1
                set mass_flow [dict get $inletProperties $groupid INLET_NUMBER_OF_KILOGRAMS]
            } else {
                set number_of_particles [dict get $inletProperties $groupid INLET_NUMBER_OF_PARTICLES]
                set mass_flow_option 0
                set mass_flow 0.5
            }   
            write::WriteString "        INLET_NUMBER_OF_PARTICLES $number_of_particles"
            write::WriteString "        IMPOSED_MASS_FLOW_OPTION $mass_flow_option"
            write::WriteString "        MASS_FLOW $mass_flow"
            set interval [dict get $inletProperties $groupid Interval]
            lassign [write::getInterval $interval] ini end
            write::WriteString "        INLET_START_TIME $ini"
            if {$end in [list "End" "end"]} {set end [write::getValue DEMTimeParameters EndTime]}
            write::WriteString "        INLET_STOP_TIME $end"
            set diameter [dict get $inletProperties $groupid DIAMETER]
            write::WriteString "        RADIUS [expr $diameter / 2]"
            write::WriteString "        PROBABILITY_DISTRIBUTION [dict get $inletProperties $groupid PROBABILITY_DISTRIBUTION]"
            write::WriteString "        STANDARD_DEVIATION [dict get $inletProperties $groupid STANDARD_DEVIATION]"
            write::WriteString "        RANDOM_ORIENTATION 1"
            write::WriteString "        ORIENTATION \[4\] (0.0, 0.0, 0.0, 1.0)"
            
            write::WriteString "    End SubModelPartData"
            write::WriteString "    Begin SubModelPartNodes"
            GiD_WriteCalculationFile nodes -sorted $gdict
            write::WriteString "    End SubModelPartNodes"
            write::WriteString "End SubModelPart"
        }
    }
}

proc DEM::write::writeMaterialsInlet { } {
    variable inletProperties
    variable last_property_id
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Inlet'\]/group"
    set old_mat_dict $::write::mat_dict
    set ::write::mat_dict [dict create]
    write::processMaterials $xp1 $DEM::write::last_property_id
    set DEM::write::last_property_id [expr $last_property_id + [dict size $::write::mat_dict]]
    
    set inletProperties $::write::mat_dict
    set ::write::mat_dict $old_mat_dict
    # WV inletProperties

    set printable [list PARTICLE_DENSITY YOUNG_MODULUS POISSON_RATIO PARTICLE_FRICTION PARTICLE_COHESION COEFFICIENT_OF_RESTITUTION PARTICLE_MATERIAL ROLLING_FRICTION ROLLING_FRICTION_WITH_WALLS PARTICLE_SPHERICITY DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME]

    foreach group [dict keys $inletProperties] {
        write::WriteString "Begin Properties [dict get $inletProperties $group MID] // Inlet group: [write::GetWriteGroupName $group]"
        dict set inletProperties $group DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_D_Hertz_viscous_Coulomb
        dict set inletProperties $group DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME DEMContinuumConstitutiveLaw
        foreach {prop val} [dict get $inletProperties $group] {
            if {$prop in $printable} {
                write::WriteString "    $prop $val"
            }
        }
        write::WriteString "End Properties\n"
    }
}