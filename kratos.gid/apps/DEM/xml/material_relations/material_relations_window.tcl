

proc DEM::xml::ShowMaterialRelationWindow { } {
    # window name
    set w .gid.windowmatrel
    
    if {[winfo exist $w]} {destroy $w}
    toplevel $w
    wm withdraw $w
    set x [expr [winfo rootx .gid]+[winfo width .gid]/2-[winfo width $w]/2]
    set y [expr [winfo rooty .gid]+[winfo height .gid]/2-[winfo height $w]/2]
    wm geom $w +$x+$y
    wm transient $w .gid    
    InitWindow $w [_ "Kratos Multiphysics - DEM - Material Relations"] Kratos "" "" 1

    set materials [list ]
    foreach mat_node [DEM::write::GetMaterialsNodeList] {
        set mat_name [write::getValueByNode $mat_node]
        if {$mat_name ni $materials} {
            lappend materials $mat_name
        }
    }
    W $materials
    
    set table $w.tree
    ttk::treeview $table -columns $materials -displaycolumns $materials
    foreach header $materials {
        $table heading $header -text $header -anchor center
    }
    pack $table

    set length [llength $materials]
    for {set i 0} { $i < $length } { incr i } {
        set row [list]
        set ref_mat_name [lindex $materials $i]
        for {set j 0} { $j < $length } { incr j } {
            lappend row X
        }
        $table insert "" end -id $ref_mat_name -text $ref_mat_name -values $row
    }
}