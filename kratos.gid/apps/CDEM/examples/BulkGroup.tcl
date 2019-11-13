
proc ::CDEM::examples::BulkGroup {args} {
    

    if {![Kratos::IsModelEmpty]} {
        set entity surfaces
        if {$::Model::SpatialDimension eq "3D"} {
            set entity volumes
        }
        set txt "Bulk grouping of all the current $entity is about to be executed"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    CreateAndAssignBondedGroups
    
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::CDEM::examples::CreateAndAssignBondedGroups { } {
    # Prepare the variables
    set entity surface
    set condition_id "DEM-Cohesive2D"
    if {$::Model::SpatialDimension eq "3D"} {
        set entity volume
        set condition_id "DEM-Cohesive"
    }
    # Locate the condition
    set DEMConditions [spdAux::getRoute "DEMConditions"]
    set cohesive_cond "$DEMConditions/condition\[@n='$condition_id'\]"

    # Get the list of entities (surfaces/volumes)
    set entity_list [GiD_Geometry -v2 list $entity]
    # Foreach entity, create subgroup and assign it to the condition
    set entity_list_length [objarray length $entity_list]
    for {set i 0} {$i < $entity_list_length} {incr i} {
        # Get the entity id
        set entity_id [objarray get $entity_list $i] 
        # Create the subgroup
        set group_id "Bonded_domain_groups//SG$entity_id"
        GiD_Groups create $group_id
        # Assign entity to subgroup
        GiD_EntitiesGroups assign $group_id volumes $entity_id
        # Assign the subgroup to the tree condition
        set cohesive_group [customlib::AddConditionGroupOnXPath $cohesive_cond $group_id]
    }
}
