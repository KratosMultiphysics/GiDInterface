proc DEM::write::WriteMDPAParts { } {
    variable last_property_id
    # Prepare properties
    write::processMaterials "" $last_property_id
    set last_property_id [expr $last_property_id + [dict size $::write::mat_dict]]
    # Headers
    write::writeModelPartData

    # Materials
    writeMaterialsParts

    # Nodal coordinates (only for DEM Parts <inefficient> )
    write::writeNodalCoordinatesOnParts
    
    # Element connectivities (Groups on STParts)
    write::writeElementConnectivities

    # Element radius
    writeSphereRadius

    # SubmodelParts
    write::writePartSubModelPart
    writeVelocityMeshes
}

proc DEM::write::writeSphereRadius { } {
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set grouppid [write::GetWriteGroupName $groupid]
        write::WriteString "Begin NodalData RADIUS // GUI group identifier: $grouppid"
        GiD_WriteCalculationFile connectivities [dict create $groupid "%.0s %10d 0 %10g\n"]
        write::WriteString "End NodalData"
        write::WriteString ""
    }
}

proc DEM::write::GetNodalConditionsGroups { {include_cond 0} } {
    set groups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        if {$include_cond} {lappend groups [[$group parent] @n]}
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}

proc DEM::write::writeVelocityMeshes { } {
    foreach {cid groupid} [DEM::write::GetNodalConditionsGroups 1] {
        ::write::writeGroupSubModelPart $cid $groupid "nodal"
    }
}

proc DEM::write::writeMaterialsParts { } {
    variable partsProperties
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Parts'\]/group"
    set partsProperties $::write::mat_dict
    #set ::write::mat_dict [dict create]
    #write::processMaterials $xp1
    #set partsProperties $::write::mat_dict
    #set ::write::mat_dict $old_mat_dict
    # WV inletProperties

    set printable [list PARTICLE_DENSITY YOUNG_MODULUS POISSON_RATIO PARTICLE_FRICTION PARTICLE_COHESION COEFFICIENT_OF_RESTITUTION PARTICLE_MATERIAL ROLLING_FRICTION ROLLING_FRICTION_WITH_WALLS DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME]
 
    foreach group [dict keys $partsProperties] {
        write::WriteString "Begin Properties [dict get $partsProperties $group MID]"
        dict set partsProperties $group DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_D_Hertz_viscous_Coulomb
        dict set partsProperties $group DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME DEMContinuumConstitutiveLaw
        foreach {prop val} [dict get $partsProperties $group] {
            if {$prop in $printable} {
                write::WriteString "    $prop $val"
            }
        }
        write::WriteString "End Properties\n"
    }
}