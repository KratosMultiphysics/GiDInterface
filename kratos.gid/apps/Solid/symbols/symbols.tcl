package require gid_draw_opengl

namespace eval Solid::symbols {    
}

#to be used directly as symbol proc (to draw a condition as a 3D shape without take into account any direction to be oriented)
#valuesList is unused, but necessary because it is automatically added when invokind the symbol proc
#e.g <symbol proc='Solid::symbols::draw_file_mesh images/conditions/selfweight.msh black blue' orientation='global'/>
proc Solid::symbols::draw_file_mesh { filename color_lines color_surfaces valuesList } {    
    set full_filename [file join $Solid::dir $filename]
    if { [info procs gid_draw_opengl::create_opengl_list_from_file_mesh] != "" } {
        set list_id [gid_draw_opengl::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces ""]
    } else {
        set list_id [Solid::symbols::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces ""]
    }
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
        #the value could be set by other function field, intead as modulus, consider like positive modulus
        set modulus 1.0
    }
    set direction [split $data(direction) ,]
    if { [llength $direction] == 2 } {
        lappend direction 0.0
    }
    set opposite_direction [math::linearalgebra::scale_vect -1.0 $direction]
    if { [info procs gid_draw_opengl::create_opengl_list_from_file_mesh_oriented_z_direction] != "" } {
        set list_id [gid_draw_opengl::create_opengl_list_from_file_mesh_oriented_z_direction $full_filename $color_lines $color_surfaces $opposite_direction]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::create_opengl_list_from_file_mesh_oriented_z_direction $full_filename $color_lines $color_surfaces $opposite_direction]      
    }
    return $list_id
}

#valuesList will be like: {ByFunction No {}} {modulus 2.0 N} {direction 1.0,0.0,0.0 {}} {compound_assignment direct {}} {Interval Total {}}
proc Solid::symbols::draw_load { valuesList } {    
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }
    set modulus $data(modulus)
    if { $modulus == 0 } {
        #the value could be set by other function field, intead as modulus, consider like positive modulus
        set modulus 1.0
    }
    set direction [split $data(direction) ,]
    if { [llength $direction] == 2 } {
        lappend direction 0.0
    }
    set force [MathUtils::ScalarByVectorProd $modulus $direction]
    set x_axis [math::linearalgebra::unitLengthVector $force]
    lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis    
    set transform_matrix [concat $x_axis 0 $y_axis 0 $z_axis 0 0 0 0 1]    
    if { [info procs gid_draw_opengl::create_opengl_list_drawing] != "" } {        
        set list_id [gid_draw_opengl::create_opengl_list_drawing gid_draw_opengl::draw_point_load $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::create_opengl_list_drawing Solid::symbols::draw_point_load $transform_matrix]
    }
    return $list_id
}

proc Solid::symbols::draw_arrow { valuesList } {    
    set full_filename [file join $Solid::dir images conditions arrow.msh]
    set color_lines black
    set color_surfaces blue
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }    
    set modulus $data(modulus)
    if { $modulus == 0 } {
        #the value could be set by other function field, intead as modulus, consider like positive modulus
        set modulus 1.0
    }
    set direction [split $data(direction) ,]
    if { [llength $direction] == 2 } {
        lappend direction 0.0
    }    
    set force [math::linearalgebra::scale_vect $modulus $direction]
    set x_axis [math::linearalgebra::unitLengthVector $force]
    lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis    
    set transform_matrix [concat $x_axis 0 $y_axis 0 $z_axis 0 0 0 0 1]
    if { [info procs gid_draw_opengl::create_opengl_list_from_file_mesh] != "" } {
        set list_id [gid_draw_opengl::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces $transform_matrix]      
    }
    return $list_id
}

#valuesList will be like: {{ByFunction No {}} {value 4 Pa} {compound_assignment direct {}} {Interval Total {}}}
proc Solid::symbols::draw_surface_pressure { valuesList } {
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
        #the value could be set by other function field, intead as modulus, consider like positive modulus
        set load_local_direction [list 0 0 -1]
    }    
    set x_axis $load_local_direction
    lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis
    set transform_matrix [concat $x_axis 0 $y_axis 0 $z_axis 0 0 0 0 1]
    if { [info procs gid_draw_opengl::create_opengl_list_drawing] != "" } {
        set list_id [gid_draw_opengl::create_opengl_list_drawing gid_draw_opengl::draw_point_load $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::create_opengl_list_drawing Solid::symbols::draw_point_load $transform_matrix]
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
        #the value could be set by other function field, intead as modulus, consider like positive modulus
        set load_local_direction [list 0 0 -1]
    }    
    set dictionary [dict create load_type local load_vector $load_local_direction]    
    return $dictionary
}

proc Solid::symbols::draw_moment { valuesList } {    
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }
    set modulus $data(modulus)
    if { $modulus == 0 } {
        #the value could be set by other function field, intead as modulus, consider like positive modulus
        set modulus 1.0
    }
    set direction [split $data(direction) ,]
    if { [llength $direction] == 2 } {
        lappend direction 0.0
    }    
    set force [MathUtils::ScalarByVectorProd $modulus $direction]
    set x_axis [math::linearalgebra::unitLengthVector $force]
    lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis    
    set transform_matrix [concat $x_axis 0 $y_axis 0 $z_axis 0 0 0 0 1]    
    if { [info procs gid_draw_opengl::create_opengl_list_drawing] != "" } {        
        set list_id [gid_draw_opengl::create_opengl_list_drawing gid_draw_opengl::draw_point_momentum $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::create_opengl_list_drawing Solid::symbols::draw_point_momentum $transform_matrix]
    }
    return $list_id
}

proc Solid::symbols::draw_spring { valuesList } {    
    set full_filename [file join $Solid::dir images conditions spring.msh]
    set color_lines black
    set color_surfaces blue
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }    
    set modulus $data(modulus)
    if { $modulus == 0 } {
        #the value could be set by other function field, intead as modulus, consider like positive modulus
        set modulus 1.0
    }
    set direction [split $data(direction) ,]
    if { [llength $direction] == 2 } {
        lappend direction 0.0
    }    
    set momentum [math::linearalgebra::scale_vect $modulus $direction]
    set x_axis [math::linearalgebra::unitLengthVector $momentum]
    lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis    
    set transform_matrix [concat $x_axis 0 $y_axis 0 $z_axis 0 0 0 0 1]
    if { [info procs gid_draw_opengl::create_opengl_list_from_file_mesh] != "" } {
        set list_id [gid_draw_opengl::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces $transform_matrix]      
    }
    return $list_id
}

proc Solid::symbols::draw_surface_ballast { valuesList } {
    set full_filename [file join $Solid::dir images conditions spring.msh]
    set color_lines black
    set color_surfaces blue
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }
    set modulus $data(value)
    if { $modulus > 0 } {
        set load_local_direction [list 0 0 1]
    } elseif { $modulus < 0 } {
        set load_local_direction [list 0 0 -1]
    } else {
        #the value could be set by other function field, intead as modulus, consider like positive modulus
        set load_local_direction [list 0 0 1]
    }    
    set x_axis $load_local_direction
    lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis
    set transform_matrix [concat $x_axis 0 $y_axis 0 $z_axis 0 0 0 0 1]
    if { [info procs gid_draw_opengl::create_opengl_list_from_file_mesh] != "" } {
        set list_id [gid_draw_opengl::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces $transform_matrix]      
    }
    return $list_id
}

#cannot be used because now parts are for all types: shells, beams and solids, 
#and cannot set at design time orientation='shell_thickness', 'section' and the appropriated proc for each case
#orientation='[some_proc]' cannot be used because the xml_node provided to some_proc is the one of <symbol > 
#that does not contain the element type
proc Solid::symbols::draw_parts_shell { valuesList } {
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }    
    set thickness $data(THICKNESS)      
    return [dict create thickness $thickness]    
}

proc Solid::symbols::draw_thickness { thickness } {
    set z_max [expr $thickness*0.5]
    set z_min [expr -1.0*$z_max]
    GiD_OpenGL draw -color $::gid_draw_opengl::rgb(black)
    GiD_OpenGL draw -polygonmode frontandback line    
    GiD_OpenGL draw -begin quads -vertex [list 0 -0.5 $z_min] -vertex [list 0 0.5 $z_min] -vertex [list 1 0.5 $z_min] -vertex [list 1 -0.5 $z_min] -end
    GiD_OpenGL draw -begin quads -vertex [list 0 -0.5 $z_max] -vertex [list 0 0.5 $z_max] -vertex [list 1 0.5 $z_max] -vertex [list 1 -0.5 $z_max] -end
    GiD_OpenGL draw -color $::gid_draw_opengl::rgb(green)
    GiD_OpenGL draw -polygonmode frontandback fill    
    GiD_OpenGL draw -begin quads -vertex [list 0 -0.5 $z_min] -vertex [list 0 0.5 $z_min] -vertex [list 1 0.5 $z_min] -vertex [list 1 -0.5 $z_min] -end
    GiD_OpenGL draw -begin quads -vertex [list 0 -0.5 $z_max] -vertex [list 0 0.5 $z_max] -vertex [list 1 0.5 $z_max] -vertex [list 1 -0.5 $z_max] -end
}

proc Solid::symbols::draw_parts { valuesList } {    
    set list_id ""
    foreach item $valuesList {
        lassign $item key value unit
        set data($key) $value
        #set unit($key) $unit
    }
    set beam_elements { LargeDisplacementBeamElement3D LargeDisplacementBeamEMCElement3D }
    set shell_elemenst { ShellThinElement ShellThickElement ShellThinCorotationalElement ShellThickCorotationalElement }
    if { [lsearch $shell_elemenst $data(Element)] != -1 } {
        set thickness $data(THICKNESS)        
        set drawing_procedure [list Solid::symbols::draw_thickness $thickness]
    } elseif { [lsearch $beam_elements $data(Element)] != -1 } {        
        
        #the kind of data depends on $data(ConstitutiveLaw) that is storing the kind of profile: UserDefined3D, RectangularSection3D, ...
        set profile $data(ConstitutiveLaw)        
        set rotate_90 1
        if { $profile== "UserDefined3D" } {
            #set area $data(AREA)        
            if { $data(INERTIA_Y) > $data(INERTIA_X) } {
                set rotate_90 0
            }
        } elseif { $profile== "RectangularSection3D" } {
            if { $data(SECTION_WIDTH) > $data(SECTION_HEIGHT) } {
                set rotate_90 0
            }
        } else {
            set rotate_90 1
        }
        #draw a double t profile
        set drawing_procedure [list gid_draw_opengl::draw_symbol_section_properties {0.0 0.0 0.0} {1.0 0.0 0.0} $rotate_90 1.0 1.0]
    } else {
        #assumed solid
        return ""      
    }
    set transform_matrix ""
    if { [info procs gid_draw_opengl::create_opengl_list_drawing] != "" } {
        set list_id [gid_draw_opengl::create_opengl_list_drawing $drawing_procedure $transform_matrix]
    } else {
        #to allow use it before the proc is available in next GiD 14.1.1d
        set list_id [Solid::symbols::create_opengl_list_drawing $drawing_procedure $transform_matrix]
    }    
    return $list_id
}

#only to show how is called, without drawing nothing
proc Solid::symbols::draw_parts_free { valuesList geom_mesh ov num pnts points ent_type center scale } {
    W "valuesList=$valuesList geom_mesh=$geom_mesh ov=$ov num=$num pnts=$pnts points=$points ent_type=$ent_type center=$center scale=$scale"
    return ""
}

######## START procs temporary defined copied from gid_draw_opengl package
#to allow use it before the proc is available in next GiD 14.1.1d
#to be deleted when this problemtype require this version or higher (and off course this version is available)

#transform_matrix could be "" for identity
proc Solid::symbols::create_opengl_list_drawing { drawing_procedure transform_matrix } {
    set list_id [GiD_OpenGL draw -genlists 1]
    GiD_OpenGL draw -newlist $list_id compile
    if { [llength $transform_matrix] } {
        GiD_OpenGL draw -pushmatrix -multmatrix $transform_matrix
    }
    {*}$drawing_procedure
    if { [llength $transform_matrix] } {
        GiD_OpenGL draw -popmatrix
    }
    GiD_OpenGL draw -endlist
    return $list_id
}

#e.g. to draw a condition as a 3D shape defined in a GiD ASCII mesh file
#transform_matrix could be "" for the identity or a list with 16 values (representing a 4x4 opengl_matrix)
proc Solid::symbols::create_opengl_list_from_file_mesh { full_filename color_lines color_surfaces transform_matrix } {
    package require customLib
    set drawing_procedure [list gid_groups_conds::import_gid_mesh_as_openGL $full_filename $color_lines $color_surfaces]
    return [Solid::symbols::create_opengl_list_drawing  $drawing_procedure $transform_matrix]
}

proc Solid::symbols::create_opengl_list_from_file_mesh_oriented_z_direction { full_filename color_lines color_surfaces z_direction } {
    package require customLib
    lassign [gid_groups_conds::calc_xy_shell $z_direction] x_axis y_axis z_axis
    set transform_matrix [concat $x_axis 0 $y_axis 0 $z_axis 0 0 0 0 1]
    return [Solid::symbols::create_opengl_list_from_file_mesh $full_filename $color_lines $color_surfaces $transform_matrix]    
}

#arrow size 1 pointing to +x (arrow cone height 0.3, radius 0.05)
proc Solid::symbols::draw_point_load { } {
    #GiD_OpenGL draw -linewidth 2.0
    GiD_OpenGL draw -begin lines -vertex [list 0 0 0] -vertex [list 1 0 0] -end
    GiD_OpenGL draw -begin trianglefan -vertex [list 1 0 0]
    foreach angle [GidUtils::GetRange 0.0 $MathUtils::2PI 9] {
        GiD_OpenGL draw -vertex [list 0.7 [expr {0.05*cos($angle)}] [expr {0.05*sin($angle)}]]
    }
    GiD_OpenGL draw -end
    #GiD_OpenGL draw -linewidth 1.0
}

#arc and double-arrow size 1 pointing to +x (arrow cone height 0.1, radius 0.05)
proc Solid::symbols::draw_point_momentum { } {
    GiD_OpenGL draw -begin lines -vertex [list 0 0 0] -vertex [list 1 0 0] -end
    foreach x_cone_start {0.9 0.7} x_cone_end {1 0.8} {
        GiD_OpenGL draw -begin trianglefan -vertex [list $x_cone_end 0 0]
        foreach angle [GidUtils::GetRange 0.0 [expr {2.0*$MathUtils::Pi}] 9] {
            GiD_OpenGL draw -vertex [list $x_cone_start [expr {0.05*cos($angle)}] [expr {0.05*sin($angle)}]]
        }
        GiD_OpenGL draw -end
    }
    GiD_OpenGL draw -begin linestrip
    foreach angle [GidUtils::GetRange 0.0 [expr {1.5*$MathUtils::Pi}] 13] {
        GiD_OpenGL draw -vertex [list 0 [expr {0.5*cos($angle)}] [expr {0.5*sin($angle)}]]
    }    
    GiD_OpenGL draw -end
    GiD_OpenGL draw -begin trianglefan -vertex [list 0 0 -0.5]
    foreach angle [GidUtils::GetRange 0.0 [expr {2.0*$MathUtils::Pi}] 9] {
        GiD_OpenGL draw -vertex [list [expr {0.05*sin($angle)}] -0.1 [expr {-0.5+0.05*cos($angle)}] ]
    }
    GiD_OpenGL draw -end
}
######## END procs temporary defined copied from gid_draw_opengl package
