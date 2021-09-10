# Overwrite DEM function
proc DEM::write::WriteMDPAParts { } {
    # Headers
    write::writeModelPartData
    
    # Process properties
    DEM::write::processPartMaterials
    
    # Materials
    DEM::write::writeMaterialsParts
    
    # Nodal coordinates (only for DEM Parts <inefficient> )
    write::writeNodalCoordinatesOnParts
    write::writeNodalCoordinatesOnGroups [GetDEMGroupsCustomSubmodelpart]
    write::writeNodalCoordinatesOnGroups [DEM::write::GetDEMGroupsInitialC]
    write::writeNodalCoordinatesOnGroups [DEM::write::GetDEMGroupsBoundaryC]
    write::writeNodalCoordinatesOnGroups [DEM::write::GetNodesForGraphs]
    
    # Element connectivities
    write::writeElementConnectivities
    
    # Begin NodalData RADIUS
    DEM::write::writeSphereRadius
    
    # Begin NodalData COHESIVE_GROUP
    CDEM::write::writeCohesiveGroups
    
    # Begin NodalData SKIN_SPHERE
    CDEM::write::writeSkinSphereNodes
    
    # SubmodelParts
    write::writePartSubModelPart
    DEM::write::writeDEMConditionMeshes
    
    # CustomSubmodelParts
    DEM::write::WriteCustomDEMSmp
}

proc CDEM::write::writeCohesiveGroups { } {
    set root [customlib::GetBaseRoot]
    if {$::Model::SpatialDimension eq "3D"} {
        set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-Cohesive'\]/group"
    } else {
        set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'DEM-Cohesive2D'\]/group"
    }
    set cohesive_group 0
    foreach group [$root selectNodes $xp1] {
        incr cohesive_group
        set groupid [$group @n]
        set group_id [write::GetWriteGroupName $groupid]
        write::WriteString "Begin NodalData COHESIVE_GROUP // GUI group identifier: $group_id"
        GiD_WriteCalculationFile connectivities [dict create $groupid "%.0s %10d 0 $cohesive_group\n"]
        write::WriteString "End NodalData"
        write::WriteString ""
        
    }
}

proc CDEM::write::writeSkinSphereNodes { } {
    # Write Skin Sphere
    set number 1
    set list_of_active_dem_elements ""
        if {[GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE]} {
        if {$::Model::SpatialDimension eq "2D"} {
            set skin_element_ids [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE all_mesh -element_type circle] ; # Get the ids of elements in SKIN_SPHERE
        } else {
            set skin_element_ids [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE all_mesh -element_type sphere]
        }
        } else {
            set skin_element_ids [list]
        }

    write::WriteString "Begin NodalData SKIN_SPHERE"
    GiD_WriteCalculationFile connectivities [dict create SKIN_SPHERE_DO_NOT_DELETE "%.0s %10d 0 $number\n"]
    write::WriteString "End NodalData"
        write::WriteString ""
}
