package require gid_draw_opengl

namespace eval Solid::symbols {
    variable opengl_list
    variable scale_draw_loads 1e-1
}

#to be used directly as symbol proc (to draw a condition as a 3D shape without take into account any direction to be oriented)
#valuesList is unused, but necessary because it is automatically added when invokind the symbol proc
#e.g <symbol proc='Solid::symbols::draw_file_mesh images/conditions/selfweight.msh black blue' orientation='global'/>
proc Solid::symbols::draw_file_mesh { filename color_lines color_surfaces valuesList } {    
    set full_filename [file join $Solid::dir $filename]
    set list_id [gid_draw_opengl::draw_file_mesh $full_filename $color_lines $color_surfaces ""]
    return $list_id
}

#valuesList will be like: {ByFunction No {}} {modulus 9.81 m/s^2} {direction 0.0,-1.0,0.0 {}} {compound_assignment direct {}} {Interval Total {}}
proc Solid::symbols::draw_selfweight { valuesList } {    
    set full_filename [file join $Solid::dir images conditions selfweight.msh]
    set color_lines black
    set color_surfaces blue
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }    
    set modulus $data(modulus)
    if { $modulus == 0 } {
        #really it is like is not applied
        return ""
    }
    set direction [split $data(direction) ,]
    set opposite_direction [math::linearalgebra::scale_vect -1.0 $direction]
    if { [info procs gid_draw_opengl::draw_file_mesh_oriented_z_direction] != "" } {
        set list_id [gid_draw_opengl::draw_file_mesh_oriented_z_direction $full_filename $color_lines $color_surfaces $opposite_direction]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::draw_file_mesh_oriented_z_direction $full_filename $color_lines $color_surfaces $opposite_direction]      
    }
    return $list_id
}

#valuesList will be like: {ByFunction No {}} {modulus 2.0 N} {direction 1.0,0.0,0.0 {}} {compound_assignment direct {}} {Interval Total {}}
proc Solid::symbols::draw_load { valuesList } {    
    variable opengl_list
    variable scale_draw_loads
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }
    set modulus $data(modulus)
    if { $modulus == 0 } {
        #really it is like is not applied
        return ""
    }
    set direction [split $data(direction) ,]
    set force [MathUtils::ScalarByVectorProd $modulus $direction]
    set x_axis [math::linearalgebra::unitLengthVector $force]
    lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis
    #gid_draw_opengl::set_scale_draw_loads 1.0    
    #set bounding_box [lindex [GiD_Info layers -bbox -use geometry] 0]
    #set bounding_box_diagonal [MathUtils::VectorDistance [lrange $bounding_box 0 2] [lrange $bounding_box 3 5]]
    #set scale_draw_loads [expr $bounding_box_diagonal*1e-2]
    set scale [expr {$scale_draw_loads*[math::linearalgebra::norm_two $force]}]
    set transform_matrix [concat [math::linearalgebra::scale_vect $scale $x_axis] 0 [math::linearalgebra::scale_vect $scale $y_axis] 0 [math::linearalgebra::scale_vect $scale $z_axis] 0 0 0 0 1]
    set symbol point_load
    if { ![info exists opengl_list($symbol)] } {
        set opengl_list($symbol) [gid_draw_opengl::create_opengl_list_point_load]               
    }
    if { [info procs gid_draw_opengl::draw_opengl_list] != "" } {
        set list_id [gid_draw_opengl::draw_opengl_list $opengl_list($symbol) $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::draw_opengl_list $opengl_list($symbol) $transform_matrix]
    }
    return $list_id
}

#valuesList will be like: {{ByFunction No {}} {value 4 Pa} {compound_assignment direct {}} {Interval Total {}}}
proc Solid::symbols::draw_surface_pressure { valuesList } {
    variable opengl_list
    #variable scale_draw_loads
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }
    set modulus $data(value)
    if { $modulus == 0 } {
        #really it is like is not applied
        return ""
    }    
    #set load_local_direction [list 0 0 -1] ;#considered positive pointing oposite to local normal    
    #set force [MathUtils::ScalarByVectorProd $modulus $load_local_direction]
    #set x_axis [math::linearalgebra::unitLengthVector $force]
    #lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis    
    #set scale [expr {$scale_draw_loads*[math::linearalgebra::norm_two $force]}]
    #set transform_matrix [concat [math::linearalgebra::scale_vect $scale $x_axis] 0 [math::linearalgebra::scale_vect $scale $y_axis] 0 [math::linearalgebra::scale_vect $scale $z_axis] 0 0 0 0 1]
    set transform_matrix ""
    set symbol point_load
    if { ![info exists opengl_list($symbol)] } {
        set opengl_list($symbol) [gid_draw_opengl::create_opengl_list_point_load]               
    }
    if { [info procs gid_draw_opengl::draw_opengl_list] != "" } {
        set list_id [gid_draw_opengl::draw_opengl_list $opengl_list($symbol) $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::draw_opengl_list $opengl_list($symbol) $transform_matrix]
    }
    return $list_id
}

#draw_loads mean that is returning a dictionary but real draw is made native inside GiD based on this dict
#in this case the XML declare orientation="loads", a special value to say GiD how to draw
#valuesList will be like: {{ByFunction No {}} {value 4 Pa} {compound_assignment direct {}} {Interval Total {}}}
#but to work well by now it is necessary to assign to surfaces the surface_Local_axes, else is drawn with wrong direction (eulerangles==NULL)
proc Solid::symbols::draw_loads_surface_pressure { valuesList } {        
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }
    set modulus $data(value)    
    if { $modulus > 0 } {
        set load_local_direction [list 0 0 -1] ;#considered positive pointing oposite to local normal
    } elseif { $modulus < 0 } {
        set load_local_direction [list 0 0 1] ;#considered positive pointing oposite to local normal
    } else {
        #really it is like is not applied
        return ""
    }    
    set dictionary [dict create load_type "local" load_vector $load_local_direction]    
    return $dictionary
}


######## START procs temporary defined copied from gid_draw_opengl package
#to allow use it before the proc is available in next GiD 14.1.1d
#to be deleted when this problemtype require this version or higher (and off course this version is available)

proc Solid::symbols::draw_opengl_list { opengl_list transform_matrix } {    
    set list_id [GiD_OpenGL draw -genlists 1]
    GiD_OpenGL draw -newlist $list_id compile
    if { [llength $transform_matrix] } {
        GiD_OpenGL draw -pushmatrix -multmatrix $transform_matrix
    }
    GiD_OpenGL draw -call $opengl_list    
    if { [llength $transform_matrix] } {
        GiD_OpenGL draw -popmatrix
    }
    GiD_OpenGL draw -endlist
    return $list_id
}

#e.g. to draw a condition as a 3D shape defined in a GiD ASCII mesh file
#transform_matrix could be "" for the identity or a list with 16 values (representing a 4x4 opengl_matrix)
proc Solid::symbols::draw_file_mesh { full_filename color_lines color_surfaces transform_matrix } {    
    set list_id [GiD_OpenGL draw -genlists 1]
    GiD_OpenGL draw -newlist $list_id compile
    if { [llength $transform_matrix] } {
        GiD_OpenGL draw -pushmatrix -multmatrix $transform_matrix
    }
    gid_groups_conds::import_gid_mesh_as_openGL $full_filename $color_lines $color_surfaces
    if { [llength $transform_matrix] } {
        GiD_OpenGL draw -popmatrix
    }
    GiD_OpenGL draw -endlist
    return $list_id
}

proc Solid::symbols::draw_file_mesh_oriented_z_direction { full_filename color_lines color_surfaces z_direction } {    
    lassign [gid_groups_conds::calc_xy_shell $z_direction] x_axis y_axis z_axis
    set transform_matrix [concat $x_axis 0 $y_axis 0 $z_axis 0 0 0 0 1]
    return [Solid::symbols::draw_file_mesh $full_filename $color_lines $color_surfaces $transform_matrix]    
}

######## END procs temporary defined copied from gid_draw_opengl package
