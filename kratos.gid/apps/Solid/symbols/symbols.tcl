package require gid_draw_opengl

namespace eval Solid::symbols {
    variable opengl_list
     
}

#args will be like: {ByFunction No {}} {modulus 2.0 N} {direction 1.0,0.0,0.0 {}} {compound_assignment direct {}} {Interval Total {}}
proc Solid::symbols::draw_Load3D { args } {
    variable opengl_list
    foreach item [lindex $args 0] {
        lassign $item key value unit
        set data($key) $value
    }
    set direction [split $data(direction) ,]
    set modulus $data(modulus)
    set force [MathUtils::ScalarByVectorProd $modulus $direction]        
    set matrix_x_axis [math::linearalgebra::unitLengthVector $force]
    lassign [MathUtils::CalculateLocalAxisFromXAxis $matrix_x_axis] matrix_y_axis matrix_z_axis
    set transform_matrix [concat $matrix_x_axis 0 $matrix_y_axis 0 $matrix_z_axis 0 0 0 0 1]

    set symbol point_load
    if { ![info exists opengl_list($symbol)] } {
        set opengl_list($symbol) [gid_draw_opengl::create_opengl_list_point_load]               
    }
    set list_id [GiD_OpenGL draw -genlists 1]
    GiD_OpenGL draw -newlist $list_id compile
    GiD_OpenGL draw -pushmatrix -multmatrix $transform_matrix
    GiD_OpenGL draw -call $opengl_list($symbol)
    GiD_OpenGL draw -popmatrix
    GiD_OpenGL draw -endlist
    return $list_id
}
