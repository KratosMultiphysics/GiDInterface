
proc ::DEM::xml::ShowMaterialRelationWindow { } {
    
    set material_relations [GetMaterialRelationsTable]
    set materials [dict keys $material_relations]
    # window name
    set w .gid.windowmatrel
     
    InitWindow $w [_ "Kratos Multiphysics - DEM - Material Relations"] Kratos "" "" 1

    if {[llength $materials]>0} {
        set table $w.tree
        ttk::treeview $table -columns $materials -displaycolumns $materials
        foreach header $materials {
            $table heading $header -text $header -anchor center
        }
        pack $table

        foreach relation_ref [dict keys $material_relations] {
            set row [list]
            foreach relation_check [dict keys [dict get $material_relations $relation_ref]] {
                if {[dict get $material_relations $relation_ref $relation_check]} {lappend row OK} {lappend row MISSING}
            }
            $table insert "" end -id $relation_ref -text $relation_ref -values $row
        }
    } else {
        set table $w.warn
        ttk::label $table -text "No materials have been used yet"
        pack $table
    }
}

proc ::DEM::xml::GetMaterialRelationsTable {} {
    set material_relations [dict create]

    set materials [list ]
    foreach mat_node [DEM::write::GetDEMUsedMaterialsNodeList] {
        set mat_name [write::getValueByNode $mat_node]
        if {$mat_name ni $materials} {
            lappend materials $mat_name
        }
    }

    set relations [dict create]

    foreach relation [DEM::write::GetMaterialRelationsNodeList] {
        
        set mat_a [write::getValueByNode [$relation selectNodes "./value\[@n = 'MATERIAL_A'\]"]]
        set mat_b [write::getValueByNode [$relation selectNodes "./value\[@n = 'MATERIAL_B'\]"]]
        dict lappend relations $mat_a $mat_b
        if {$mat_a ne $mat_b} { dict lappend relations $mat_b $mat_a }
    }

    set length [llength $materials]
    for {set i 0} { $i < $length } { incr i } {
        set row [list]
        set ref_mat_name [lindex $materials $i]
        for {set j 0} { $j < $length } { incr j } {
            set check_mat_name [lindex $materials $j]
            set exists 0
            if {[dict exists $relations $ref_mat_name]} {
                if {$check_mat_name in [dict get $relations $ref_mat_name]} {set exists 1}
            }
            dict set material_relations $ref_mat_name $check_mat_name $exists
        }
    }

    return $material_relations

}