
namespace eval Stent::Wizard {
    # Namespace variables declaration
    
}

proc Stent::Wizard::Init { } {
    #W "Carga los pasos"
}

proc Stent::Wizard::Geometry { win } {
    smart_wizard::AutoStep $win Geometry
    smart_wizard::SetWindowSize 650 500
}

proc Stent::Wizard::NextGeometry { } {
    
}

proc Stent::Wizard::DrawGeometry {} {
    Kratos::ResetModel

    set layer_name helicoide
    GiD_Layers create $layer_name
    
    set err [ValidateDraw]
    if {$err ne 0} {
        return ""
    }
    # Get the parameters
    set wire_radius [ smart_wizard::GetProperty Geometry WireRadius,value]
    set number_wires [ smart_wizard::GetProperty Geometry NumberOfWires,value]
    set angle [ smart_wizard::GetProperty Geometry AngleBetweenWires,value]
    set stent_radius [ smart_wizard::GetProperty Geometry StentRadius,value]
    set stent_length [ smart_wizard::GetProperty Geometry StentLength,value]
    
    # Calculated parameters
    set wire_diameter [expr 2.0*$wire_radius]
    set pi [expr 2*asin(1.0)]
    set degtorad 0.0174532925199
    set stent_perimeter [expr 2*$stent_radius*$pi]
    set point_distance_row [expr $stent_perimeter/$number_wires]
    set point_distance_column [expr $point_distance_row * tan($degtorad * (90-$angle))]

    set num_cols [expr 1 + ($number_wires *2)]
    set num_rows [expr 2 + (int(double($stent_length)/$point_distance_column) *2)]

    array set points_x [FillBidimensionalArray $num_cols $num_rows 0.0]
    array set points_y [FillBidimensionalArray $num_cols $num_rows 0.0]
    array set points_z [FillBidimensionalArray $num_cols $num_rows 0.0]

    set i 0
    for {set j 1} {$j < $num_rows} {incr j} {
        if {[expr $j % 2] eq 0} {
            set tj [expr $j-2]
            set points_y($i,$j) [expr $points_y($i,$tj) + $point_distance_column]
        }
    }

    for {set j 0} {$j < $num_rows} {incr j} {
        if {[expr $j % 2] eq 0} {
            for {set i 1} {$i < $num_cols} {incr i} {
                if {[expr $i % 2] eq 0} {
                    set ti [expr $i-2]
                    set points_x($i,$j) [expr $points_x($ti,$j) + $point_distance_row]
                    set points_y($i,$j) [expr $points_y($ti,$j)]
                }
            }
        } else {
            for {set i 0} {$i < $num_cols} {incr i} {
                if {[expr $i % 2] ne 0} {
                    set ti [expr $i-1]
                    set tj [expr $j-1]
                    set points_x($i,$j) [expr $points_x($ti,$tj) + $point_distance_row/2]
                    set points_y($i,$j) [expr $points_y($ti,$tj) + $point_distance_column/2]
                }
            }
        }
    }

    array set b_points_x [FillBidimensionalArray $num_cols $num_rows 0.0]
    array set b_points_y [FillBidimensionalArray $num_cols $num_rows 0.0]
    array set b_points_z [FillBidimensionalArray $num_cols $num_rows 0.0]

    for {set j 1} {$j < $num_rows} {incr j} {
        if {[expr $j % 2] eq 0} {
            set tj [expr $j-2]
            set b_points_x(0,$j) $b_points_x(0,$tj)
            set b_points_y(0,$j) [expr $b_points_y(0,$tj) + $point_distance_column]
            set b_points_z(0,$j) [expr -1.0 * $wire_diameter]
        }
    }
    
    for {set j 0} {$j < $num_rows} {incr j} {
        if {[expr $j % 2] == 0 || $j == 0} {
            for {set i 1} {$i < $num_cols} {incr i} {
                if {[expr $i % 2] == 0} {
                    set ti [expr $i-2]
                    set b_points_x($i,$j) [expr $b_points_x($ti,$j) + $point_distance_row]
                    set b_points_y($i,$j) [expr $b_points_y($ti,$j)]
                    set b_points_z($i,$j) [expr -1.0 * $wire_diameter]
                }
            }
        } else {
            for {set i 0} {$i < $num_cols} {incr i} {
                if {[expr $i % 2] ne 0} {
                    set ti [expr $i-1]
                    set tj [expr $j-1]
                    set b_points_x($i,$j) [expr $b_points_x($ti,$tj) + $point_distance_row/2]
                    set b_points_y($i,$j) [expr $b_points_y($ti,$tj) + $point_distance_column/2]
                    set b_points_z($i,$j) [expr -1.0 * $wire_diameter]
                }
            }
        }
    }

    set cont1 1
    set c 1
    GiD_Geometry -v2 create point $cont1 $layer_name $points_x(0,0) $points_y(0,0) 0.0
    for {set j 0} {$j < $num_rows} {incr j} {
        if {$c eq 1} {set c 0} {set c 1}

        for {set i 0} {$i < $num_cols} {incr i} {
            if {$points_x($i,$j) eq 0.0 && $points_y($i,$j) eq 0.0 } {

            } else {
                incr cont1
                if {$c eq 0 || $j eq [expr $num_rows - 1] || $j eq 0} {
                    GiD_Geometry -v2 create point $cont1 $layer_name $points_x($i,$j) $points_y($i,$j) $points_z($i,$j)
                } else {
                    GiD_Geometry -v2 create point $cont1 $layer_name $points_x($i,$j) $points_y($i,$j) [expr -1.0 * $wire_diameter]
                }
            }
        }
    }

    set cont11 100001
    set g 1

    GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x(0,0) $b_points_y(0,0) 0.0
    for {set j 0} {$j < $num_rows} {incr j} {
        if {$g eq 1} {set g 0} {set g 1}

        for {set i 0} {$i < $num_cols} {incr i} {
            if {$b_points_x($i,$j) eq 0.0 && $b_points_y($i,$j) eq 0.0 } {

            } else {
                incr cont11
                if {$g eq 1 || $j eq 0 || $j eq $num_rows} {
                    GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) 0.0
                } else {
                    GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) $b_points_z($i,$j)
                }
            }
        }
    }
    

    set cont2 0
    set cont3 [expr $number_wires + 1]
    set n 0
    set s 1
    set d -1


    for {set m [expr $number_wires +2]} {$m < [expr $cont1+1]} {incr m} {

        if {$s eq 0 && $cont3 eq $number_wires} {
            set s 1
            set cont3 0
            incr d
        } elseif {$s eq 1 && $cont3 eq [expr $number_wires + 1]} {                      
            set s 0
            set cont3 0
        }    

        if {$s eq 1} {
            incr cont3
            set n [expr int(($m+$d)/($number_wires+1))]
            if {$m ne [expr ($n*($number_wires +1)+$number_wires -$d)]} {
                incr cont2
                set punto1 $m
                set punto2 [expr $punto1 - $number_wires]
                GiD_Geometry -v2 create line $cont2 stline $layer_name $punto1 $punto2
            }
        } else {
            incr cont3
            incr cont2
            set punto1 $m
            set punto2 [expr $punto1 - $number_wires]
            GiD_Geometry -v2 create line $cont2 stline $layer_name $punto1 $punto2
        }
    }

    set cont22 100000
    set cont3 [expr $number_wires + 1]
    set n 0
    set s 1
    set d -1


    for {set m [expr 100000 + $number_wires +2]} {$m < [expr $cont11+1]} {incr m} {

        if {$s eq 0 && $cont3 eq $number_wires} {
            set s 1
            set cont3 0
            incr d
        } elseif {$s eq 1 && $cont3 eq [expr $number_wires + 1]} {                      
            set s 0
            set cont3 0
        }    

        if {$s eq 1} {
            incr cont3
            set n [expr int((($m-100000)+$d)/($number_wires+1))]
            if {[expr $m - 100000] ne [expr ($n*($number_wires +1)-$d)]} {
                incr cont22
                set punto1 $m
                set punto2 [expr $punto1 - $number_wires - 1]
                GiD_Geometry -v2 create line $cont22 stline $layer_name $punto1 $punto2
            }
        } else {
            incr cont3
            incr cont22
            set punto1 $m
            set punto2 [expr $punto1 - $number_wires - 1]
            GiD_Geometry -v2 create line $cont22 stline $layer_name $punto1 $punto2
        }
    }

    set cont4 1000000
    for {set q 2} {$q < $cont1} {incr q} {
        incr cont4
        set punto1 $q
        set punto2 [expr $punto1 +100000]
        GiD_Geometry -v2 create line $cont4 stline $layer_name $punto1 $punto2
    }

    movenodestocylinder
    GiD_Process Mescape Utilities Collapse model Yes 

}

proc Stent::Wizard::FillBidimensionalArray { size_x size_y { value 0.0} } {
    for {set i 0} {$i < $size_x} {incr i} {
        for {set j 0} {$j < $size_y} {incr j} {
            set farray($i,$j) $value
        }
    }
    return [array get farray]
}
proc Stent::Wizard::movenodestocylinder { } {
    GidUtils::DisableGraphics 
    set kk [GiD_Set CreateAlwaysNewPoint]
    GiD_Set CreateAlwaysNewPoint 1
    set t0 [clock seconds]
    set xmin 1e15
    set xmax -1e15
    set ymin 1e15
    set ymax -1e15
    set point_ids [GiD_Geometry list point]
    foreach num $point_ids {
        lassign [GiD_Geometry get point $num] layer x y z
        if { $xmin > $x } { set xmin $x }
        if { $xmax < $x } { set xmax $x }
        if { $ymin > $y } { set ymin $y }
        if { $ymax < $y } { set ymax $y }
    }
    set dx [expr {$xmax-$xmin}]
    set k [expr {(2.0*$MathUtils::Pi)/$dx}]
    set r0 [expr {1.0/$k}]
    foreach num $point_ids {
        lassign [GiD_Geometry get point $num] layer x y z
        set r [expr {$r0+$z}]
        set angle [expr {($x-$xmin)*$k}]
        set x [expr {$r*sin($angle)}]
        set z [expr {$r*cos($angle)}]
        GiD_Process Mescape Geometry Edit MovePoint $num $x $y $z escape
    }
    GiD_Set CreateAlwaysNewPoint $kk
    GidUtils::EnableGraphics
    GiD_Process 'Zoom Frame
}

proc Stent::Wizard::ValidateDraw { } {
    return 0
}

Stent::Wizard::Init

