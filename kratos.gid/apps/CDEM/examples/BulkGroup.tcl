
proc ::CDEM::examples::BulkGroup {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "Bulk grouping of all the current volumes is about to be executed"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    CreateAndAssign3DBondedGroups

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::CDEM::examples::CreateAndAssign3DBondedGroups { } {

    # This procedure can be called from the command line of GiD, after loading the CDEM problemtype, just by typing:
    # -np- ::CDEM::CreateAndAssign3DBondedGroups

    set volume_list [GiD_Geometry -v2 list volume]

    for {set i 0} {$i < [llength $volume_list]} {incr i} {

        set volume_id [lindex $volume_list $i]
        GiD_Groups create Bonded_domain_groups//SG$volume_id
        GiD_EntitiesGroups assign Bonded_domain_groups//SG$volume_id volumes $volume_id

        set DEMConditions [spdAux::getRoute "DEMConditions"]
        set cohesive_cond "$DEMConditions/condition\[@n='DEM-Cohesive'\]"
        set cohesive_group [customlib::AddConditionGroupOnXPath $cohesive_cond Bonded_domain_groups//SG$volume_id]
    }
}
