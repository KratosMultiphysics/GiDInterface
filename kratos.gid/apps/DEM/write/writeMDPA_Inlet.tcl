proc DEM::write::WriteMDPAInlet { } {
    # Headers
    write::writeModelPartData

    writeMaterials

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
    foreach groupid [dict keys $inletProperties ] {
        ::write::writeGroupMesh Inlet $groupid "nodal" "" "" [dict get $inletProperties $groupid]
    }
}
proc DEM::write::writeMaterials { } {
    variable inletProperties
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Inlet'\]/group"
    set old_mat_dict $::write::mat_dict
    set ::write::mat_dict [dict create]
    write::processMaterials $xp1
    set inletProperties $::write::mat_dict
    set ::write::mat_dict $old_mat_dict
    # WV inletProperties

    set printable [list PARTICLE_DENSITY YOUNG_MODULUS POISSON_RATIO PARTICLE_FRICTION PARTICLE_COHESION COEFFICIENT_OF_RESTITUTION PARTICLE_MATERIAL ROLLING_FRICTION PARTICLE_SPHERICITY DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME]
    
    
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties\n"

    foreach group [dict keys $inletProperties] {
        write::WriteString "Begin Properties [dict get $inletProperties $group MID] // Inlet group: [write::GetWriteGroupName $group]"
        dict set inletProperties $group DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME [dict get $inletProperties $group ConstitutiveLaw]
        dict set inletProperties $group DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME DEMContinuumConstitutiveLaw
        dict set inletProperties $group PARTICLE_FRICTION 0.9999999999999999
        foreach {prop val} [dict get $inletProperties $group] {
            if {$prop in $printable} {
                write::WriteString "    $prop $val"
            }
        }
        write::WriteString "End Properties\n"
    }
}