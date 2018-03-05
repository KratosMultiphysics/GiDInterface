
namespace eval ::Structural::Formfinding {
    # Variable declaration
    
}

# copy problem folder to restore the formfinding problem
proc Structural::Formfinding::CopyFormfinding {} {
    #delete formfinding folder if it exists
    # set script_file [file nativename [GiD_Info project modelname].gid]
    set script_folder [GiD_Info project modelname].gid
    set folder_name [file tail [GiD_Info project modelname]].gid
    set new_folder [file join $script_folder $folder_name]
    file delete -force $new_folder

    #copy formfinding to temp folder
    set script_parent_folder [file dirname $script_folder]
    set temp_directory [file join $script_parent_folder temp]
    file copy $script_folder $temp_directory
    
    # copy temp folder to current directory
    file copy $temp_directory $new_folder
    
    # delete temp directory
    file delete -force $temp_directory
    # set current_directory [file normalize [info script]]
    GidUtils::SetWarnLine "Security copy created inside the model folder"
}

# update nodal coordinates
proc Structural::Formfinding::ModifyNodes {} {
    set node_list [GiD_Result get {Displacement Kratos 1.1}]
    set counter 0
    foreach node $node_list {
        # ensure that the header is not taken into account
        incr counter
        if { $counter > 3 } {
            set node_id [lindex $node 0]
            set displacement [lindex $node 1]
            set displacement_x [lindex $displacement 0]
            set displacement_y [lindex $displacement 1]
            set displacement_z [lindex $displacement 2]
            set point [GiD_Mesh get node $node_id]
            set value_x [lindex $point 1]
            set value_y [lindex $point 2]
            set value_z [lindex $point 3]
            set new_value_x [expr {$value_x + $displacement_x}]
            set new_value_y [expr {$value_y + $displacement_y}]
            set new_value_z [expr {$value_z + $displacement_z}]
            set new_value {}
            lappend new_value $new_value_x $new_value_y $new_value_z
            GiD_Mesh edit node $node_id $new_value
        }
    } 
    GidUtils::SetWarnLine "Preprocess mesh is now updated"
}

proc Structural::Formfinding::UpdateGeometry { } {
    CopyFormfinding
    ModifyNodes
}

