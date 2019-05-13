namespace eval Stent::Wizard {
    # Namespace variables declaration
    
}

proc Stent::Wizard::Init { } {
    #W "Carga los pasos"
}

proc Stent::Wizard::Geometry { win } {
    smart_wizard::AutoStep $win Geometry
    smart_wizard::SetWindowSize 650 650
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
    set stent_radius [ smart_wizard::GetProperty Geometry StentRadius,value]
    set stent_length [ smart_wizard::GetProperty Geometry StentLength,value]
    set crimped_on [ smart_wizard::GetProperty Geometry CrimpedButton,value]

    set angle [ smart_wizard::GetProperty Geometry AngleBetweenWires,value]
    
    #New Variables to define the changes
    set variable_angle [ smart_wizard::GetProperty Geometry VariableAngleButton,value]
    set angle_crimped [ smart_wizard::GetProperty Geometry AngleCrimped,value]
    set angle_transition [ smart_wizard::GetProperty Geometry AngleTransition,value]
    set angle_open [ smart_wizard::GetProperty Geometry AngleOpen,value]
    set one_over_two [smart_wizard::GetProperty Geometry OneOverTwoButton,value]
    set Nurbs_Line [smart_wizard::GetProperty Geometry NurbsButton,value]
    
    # Calculated parameters
    set wire_diameter [expr 2.0*$wire_radius]
    set pi [expr 2*asin(1.0)]
    set stent_perimeter [expr 2*$stent_radius*$pi]
    set point_distance_row [expr $stent_perimeter/$number_wires]
    set num_cols [expr 1 + ($number_wires *2)]
    
    # Calculate the point coordinates
    lassign [CalculatePointArrays $stent_length $point_distance_row $angle_open $angle_transition $angle_crimped $variable_angle $num_cols $wire_diameter] num_rows tmp_x tmp_y tmp_z tmp_bx tmp_by tmp_bz
    array set points_x $tmp_x
    array set points_y $tmp_y
    array set points_z $tmp_z
    array set b_points_x $tmp_bx
    array set b_points_y $tmp_by
    array set b_points_z $tmp_bz
    
    #IF 1-OVER-2 BUTTON IS OFF
    if {$one_over_two eq "No"} {
        set cont1 1
        set c 1
        GiD_Geometry -v2 create point $cont1 $layer_name $points_x(0,0) $points_y(0,0) 0.0
        for {set j 0} {$j < $num_rows} {incr j} {
            if {$c eq 1} {set c 0} {set c 1}
            
            for {set i 0} {$i < $num_cols} {incr i} {
                if {$points_x($i,$j) eq 0.0 && $points_y($i,$j) eq 0.0 } {
                    
                } else {
                    incr cont1
                    if {$c eq 0 || $j eq 0} {
                        lappend outer_nodes [GiD_Geometry -v2 create point $cont1 $layer_name $points_x($i,$j) $points_y($i,$j) $points_z($i,$j)]
                    } elseif {$j eq [expr $num_rows - 1] } {
                        GiD_Geometry -v2 create point $cont1 $layer_name $points_x($i,$j) $points_y($i,$j) $points_z($i,$j)
                    } else {
                        lappend inner_nodes [GiD_Geometry -v2 create point $cont1 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) $b_points_z($i,$j)]
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
                    if {$g eq 1 || $j eq 0 } {
                        lappend outer_nodes [GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) 0.0]
                    } elseif {$j eq [expr $num_rows -1 ]} {
                        GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) 0.0
                    } else {
                        lappend inner_nodes [GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) $b_points_z($i,$j)]
                    }
                }
            }
        }
    } elseif {$one_over_two eq "Yes"} {
        set cont1 1
        set c 1
        set cont1over2 2
        set j 0
        
        GiD_Geometry -v2 create point $cont1 $layer_name $points_x(0,0) $points_y(0,0) 0.0
        
        for {set i 1} {$i < $num_cols} {incr i} {
            if {$points_x($i,$j) eq 0.0 && $points_y($i,$j) eq 0.0} {
                
            } else {
                incr cont1
                GiD_Geometry -v2 create point $cont1 $layer_name $points_x($i,$j) $points_y($i,$j) $points_z($i,$j)
            }
        }
        
        for {set j 1} {$j < $num_rows} {incr j} {
            if {$c eq 1 && $cont1over2 eq 2} {
                set c 0
                set cont1over2 0
            } elseif {$c eq 0 && $cont1over2 eq 2} {
                set c 1
                set cont1over2 0
            }
            for {set i 0} {$i < $num_cols} {incr i} {
                if {$points_x($i,$j) eq 0.0 && $points_y($i,$j) eq 0.0 } {
                    
                } else {
                    incr cont1
                    if {$c eq 0 } {
                        lappend outer_nodes [GiD_Geometry -v2 create point $cont1 $layer_name $points_x($i,$j) $points_y($i,$j) $points_z($i,$j)]
                    } elseif {$j eq [expr $num_rows -1 ]} {
                        GiD_Geometry -v2 create point $cont1 $layer_name $points_x($i,$j) $points_y($i,$j) $points_z($i,$j)
                    } else {
                        set varieble_wire [expr -1.0 * $wire_diameter]
                        lappend inner_nodes [GiD_Geometry -v2 create point $cont1 $layer_name $points_x($i,$j) $points_y($i,$j) $varieble_wire]
                    }
                }
            }
            incr cont1over2
        }
        
        set cont11 100001
        set g 1
        set cont1over2p 2
        set j 0
        
        GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x(0,0) $b_points_y(0,0) 0.0
        
        for {set i 1} {$i < $num_cols} {incr i} {
            if {$b_points_x($i,$j) eq 0.0 && $b_points_y($i,$j) eq 0.0} {
                
            } else {
                incr cont11
                GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) 0.0
            }
        }
        
        for {set j 1} {$j < $num_rows} {incr j} {
            if {$g eq 0 && $cont1over2p eq 2} {
                set g 1
                set cont1over2p 0
            } elseif {$g eq 1 && $cont1over2p eq 2} {
                set g 0
                set cont1over2p 0
            }
            for {set i 0} {$i < $num_cols} {incr i} {
                if {$b_points_x($i,$j) eq 0.0 && $b_points_y($i,$j) eq 0.0 } {
                    
                } else {
                    incr cont11
                    if {$g eq 1 } {
                        lappend outer_nodes [GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) 0.0]
                    } elseif {$j eq [expr $num_rows -1 ]} {
                        GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) 0.0
                    } else {
                        lappend inner_nodes [GiD_Geometry -v2 create point $cont11 $layer_name $b_points_x($i,$j) $b_points_y($i,$j) $b_points_z($i,$j)]
                    }
                }
            }
            incr cont1over2p
        }
    }
    
    #If it is Nurbs-lines instead straight lines
    if {$Nurbs_Line eq "Yes"} {
        array set Matrix1 [FillBidimensionalArray $number_wires $num_rows 0.0]
        array set Matrix2 [FillBidimensionalArray $number_wires $num_rows 0.0]
        #array set NurbsMatrix [FillBidimensionalArray $number_wires [expr ($num_rows*2) - 1 ] 0.0]

       
        MoveNodesToCylinder
        GiD_Process Mescape Utilities Collapse model Yes 

        if {$crimped_on == "Yes"} {
            createcrimpado
            GiD_Process Mescape Utilities Collapse model Yes 
        } 
        
        #Initialization of Matrix1 and Matrix2
        set StarterPoint 0
        for {set j 0} {$j < $number_wires} {incr j} {
            incr StarterPoint
            set Matrix1($j,0) $StarterPoint
            set Matrix2($j,0) $StarterPoint
            for {set i 1} {$i < $num_rows} {incr i} {
                set ti [expr $i-1]
                set Matrix1($j,$i) [expr $Matrix1($j,$ti) + $number_wires]
                if {$i eq 1} {
                    set ti [expr $i-1]
                    set Matrix2($j,$i) [expr $Matrix2($j,$ti) + 100000 + $number_wires + 1]
                } else {
                    set ti [expr $i-1]
                    set Matrix2($j,$i) [expr $Matrix2($j,$ti) +  $number_wires + 1]
                }
                if {$i eq [expr $num_rows - 1]} {
                    set Matrix2($j,$i) [expr $Matrix2($j,$i) - 100000]
                }
            }
        }
        #Corrections on Matrix1 and Matrix2 with the exceptions
        set StarterPoint 0
        for {set j 0} {$j < $number_wires} {incr j} {
            set count1 0
            set count2 0  
            set p_value 0
            incr StarterPoint
            set i [expr $StarterPoint*2 - 1]
            if {$i < $num_rows} {
                set ti [expr $i-1]
                set Matrix1($j,$i) [expr $Matrix1($j,$ti) + (2*$number_wires)]                
            } else {
                set i 0
            }
            set l_value [expr ((2*$number_wires) + 1 - 2*$j) - 1]       
            if {$l_value < $num_rows} {
                set tl [expr $l_value - 1]
                set Matrix2($j,$l_value) [expr $Matrix2($j,$tl) + 1]               
            } else {
                set p_value 1
                
            }
            for {set t [expr $i + 1]} {$t < $num_rows} {incr t} {
                incr count1
                if {[expr $count1 % (2*$number_wires)] eq 0} {
                    set tt [expr $t-1]
                    set Matrix1($j,$t) [expr $Matrix1($j,$tt) + (2*$number_wires)]                    
                } else {
                    set tt [expr $t-1]
                    set Matrix1($j,$t) [expr $Matrix1($j,$tt) + $number_wires]                      
                }
            }
            if {$p_value eq 0} {
                for {set k [expr $l_value + 1]} {$k < $num_rows} {incr k} {
                    incr count2
                    if {[expr $count2 % (2*$number_wires)] eq 0} {
                        set tk [expr $k-1]
                        set Matrix2($j,$k) [expr $Matrix2($j,$tk) + 1]                         
                    } else {
                        set tk [expr $k-1]
                        set Matrix2($j,$k) [expr $Matrix2($j,$tk) + $number_wires + 1]     
                    }
                    if {$k eq [expr $num_rows - 1] } {
                        set Matrix2($j,$k) [expr $Matrix2($j,$k) - 100000] 
                    }
                }
            }
            
        }
    
        for {set j 0} {$j < $number_wires} {incr j} {
            set ti [expr $num_rows -1]
            if {$Matrix2($j,$ti) eq $Matrix1(0,$ti)} {
                set index(0) $j
            }
        }
        for {set j 1} {$j < $number_wires} {incr j} {
            set tj [expr $j -1]
            if {$index($tj) ne [expr $number_wires - 1]} {
                set index($j) [expr $index($tj) + 1]
            } else {
                set index($j) 0
            }
        
        }   
             
        #Creation of NurbsMatrix: each row have all the points to join with each NurbsLine       
        for {set j 0} {$j < $number_wires} {incr j} {
                                                        
            set count3 0
            for {set i 0} {$i < $num_rows} {incr i} {
                set NurbsMatrix($j,$i) $Matrix1($j,$i)
            }
            for {set i $num_rows} {$i < [expr $num_rows * 2 - 1]} {incr i} {
                incr count3
                set ip [expr $num_rows - $count3 - 1]
                set t $index($j)
                set NurbsMatrix($j,$i) $Matrix2($t,$ip)               
            }
        }

        GidUtils::DisableGraphics
        set contNurbs 0
        for {set j 0} {$j < $number_wires} {incr j} {
            incr contNurbs
            set end_point [expr $num_rows * 2 - 2]
            set columns [list]
            set keys [array names NurbsMatrix $j,*]
            foreach key $keys {
                lappend columns [lindex [split $key ,] 1]
            }
            set columns [lsort -integer $columns]
            set interpolation_coordinates  [list]
            foreach column $columns {
                set key $j,$column
                set point_id $NurbsMatrix($key)
                set xyz [lrange [GiD_Geometry get point $point_id] 1 3]
                lappend interpolation_coordinates {*}$xyz
            }
            lappend wires_1 [GiD_Geometry -v2 create line $contNurbs nurbsline $layer_name $NurbsMatrix($j,0) $NurbsMatrix($j,$end_point) [list -interpolate $interpolation_coordinates]]
            GiD_Process Mescape Utilities Collapse model Yes 
        }
        
        #DIVIDE IN THE MIDDLE THE NURBS_LINES and THEN DIVIDE THE REST
        
        set contNurbs 0
        set new_lines_id $number_wires

        set first_point [expr $num_rows - 1]
        for {set j 0} {$j < $number_wires} {incr j} {
            incr contNurbs
            set help_value 0
            set columns [list]
            set keys [array names NurbsMatrix $j,*]
            foreach key $keys {
                lappend columns [lindex [split $key ,] 1]
            }
            set columns [lsort -integer $columns]
            set key $j,$first_point
            set point_id $NurbsMatrix($key)
            GiD_Process Mescape Geometry edit DivideLine Multiple Point Fjoin $point_id $contNurbs escape escape
            incr new_lines_id
            set new_lines_id2 [expr $new_lines_id +1]        
            foreach column $columns {
                if {$column < [expr $num_rows - 1]} {
                    set key $j,$column
                    set point_id $NurbsMatrix($key)
                    if {$help_value == 0 && $point_id > $number_wires} {
                        GiD_Process Mescape Geometry edit DivideLine Multiple Point Fjoin $point_id $new_lines_id escape escape
                        lappend wires_1 [expr $new_lines_id + 2]
                        set new_lines_id [expr $new_lines_id + 3]
                        incr help_value
                    } elseif {$point_id > $number_wires} {
                        GiD_Process Mescape Geometry edit DivideLine Multiple Point Fjoin $point_id $new_lines_id escape escape
                        lappend wires_1 [expr $new_lines_id + 1]
                        set new_lines_id [expr $new_lines_id + 2]                       
                    }
                }
            }
            lappend wires_1 [expr $new_lines_id]
            set new_lines_id3 [expr $new_lines_id +1]
            foreach column $columns {
                if {$column < [expr $num_rows - 1]} {
                    set key $j,$column
                    set point_id $NurbsMatrix($key)
                    set column2 [expr ($num_rows*2-2)-$column]
                    set key $j,$column2
                    set point2_id $NurbsMatrix($key)
                    if {$help_value == 1 && $point_id > $number_wires} {
                        GiD_Process Mescape Geometry edit DivideLine Multiple Point Fjoin $point2_id $new_lines_id2 escape escape
                        set new_lines_id [expr $new_lines_id + 2]
                        lappend wires_2 $new_lines_id
                        incr help_value
                    } elseif {$point_id > $number_wires} {
                        GiD_Process Mescape Geometry edit DivideLine Multiple Point Fjoin $point2_id $new_lines_id3 escape escape
                        set new_lines_id3 [expr $new_lines_id3 + 2]
                        set new_lines_id [expr $new_lines_id + 2]
                        lappend wires_2 $new_lines_id                      
                    }
                }
            }
            lappend wires_2 [expr $new_lines_id - 1]
                       
        }
                      
        # DivideNurbsLines (create in proc separated)
        GiD_Process Mescape Utilities Collapse model Yes

        # JOINTS
        set points_1_id [GiD_Geometry list point]
        set cont4 1000000
        set joints [list]
        foreach point_1 $points_1_id {
            if {$point_1 < 100000 } {
                incr cont4
                set punto1 $point_1
                set punto2 [expr $punto1 +100000]
                lappend joints [GiD_Geometry -v2 create line $cont4 stline $layer_name $punto1 $punto2]
            }
        }


        GidUtils::EnableGraphics 
        GiD_Process 'Zoom Frame


    #ELSE it is straight line
    } else {
        set cont2 0
        set cont3 [expr $number_wires + 1]
        set n 0
        set s 1
        set d -1
        
        set wires_1 [list]
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
                    lappend wires_1 [GiD_Geometry -v2 create line $cont2 stline $layer_name $punto1 $punto2]
                }
            } else {
                incr cont3
                incr cont2
                set punto1 $m
                set punto2 [expr $punto1 - $number_wires]
                lappend wires_1 [GiD_Geometry -v2 create line $cont2 stline $layer_name $punto1 $punto2]
            }
        }
        
        set cont22 100000
        set cont3 [expr $number_wires + 1]
        set n 0
        set s 1
        set d -1
        set wires_2 [list ]
        
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
                    lappend wires_2 [GiD_Geometry -v2 create line $cont22 stline $layer_name $punto1 $punto2]
                }
            } else {
                incr cont3
                incr cont22
                set punto1 $m
                set punto2 [expr $punto1 - $number_wires - 1]
                lappend wires_2 [GiD_Geometry -v2 create line $cont22 stline $layer_name $punto1 $punto2]
            }
        }

        set cont4 1000000
        set joints [list]
        for {set q 1} {$q < $cont1} {incr q} {
            incr cont4
            set punto1 $q
            set punto2 [expr $punto1 +100000]
            lappend joints [GiD_Geometry -v2 create line $cont4 stline $layer_name $punto1 $punto2]
        }
   
        MoveNodesToCylinder
        GiD_Process Mescape Utilities Collapse model Yes

        if {$crimped_on == "Yes"} {
            createcrimpado
            GiD_Process Mescape Utilities Collapse model Yes 
        } 

    }


    for {set i 1} {$i <= $number_wires} {incr i} {
        lappend bottom $i
        lappend top [expr $cont1 +1 - $i]
    }


    GiD_Groups create bottom
    GiD_EntitiesGroups assign bottom points $bottom
    
    GiD_Groups create top
    GiD_EntitiesGroups assign top points $top
  
    GiD_Groups create structure
    
    GiD_Groups create wires_1
    GiD_EntitiesGroups assign wires_1 lines $wires_1   
    GiD_EntitiesGroups assign structure lines $wires_1

    GiD_Groups create wires_2
    GiD_EntitiesGroups assign wires_2 lines $wires_2
    GiD_EntitiesGroups assign structure lines $wires_2

    GiD_Groups create joints
    GiD_EntitiesGroups assign joints lines $joints
    GiD_EntitiesGroups assign structure lines $joints
        
    GiD_Groups create "inner nodes"
    GiD_EntitiesGroups assign "inner nodes" points $inner_nodes
    GiD_Groups create "outer nodes"
    GiD_EntitiesGroups assign "outer nodes" points $outer_nodes

    foreach point $top {
        set idx [lsearch $outer_nodes $point]
        set outer_nodes [lreplace $outer_nodes $idx $idx]
        GiD_EntitiesGroups unassign "outer nodes" points $point
    }
    foreach point $bottom {
        set idx [lsearch $outer_nodes $point]
        set outer_nodes [lreplace $outer_nodes $idx $idx]
    }
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame    

}

proc Stent::Wizard::CalculatePointArrays {stent_length point_distance_row angle_open angle_transition angle_crimped variable_angle num_cols wire_diameter} {
    
    set degtorad 0.0174532925199

    #IF VARIABLE ANGLE IS ON
    if {$variable_angle eq "Yes"} {
        set length_open [expr 0.53*$stent_length]
        set length_linear [expr 0.27*$stent_length]
        set length_closed [expr 0.20*$stent_length] 
        
        set point_distance_column_open [expr $point_distance_row * tan($degtorad * (90-$angle_open))]
        set point_distance_column_transition [expr $point_distance_row * tan($degtorad * (90-$angle_transition))]
        set point_distance_column_crimped [expr $point_distance_row * tan($degtorad * (90-$angle_crimped))]
        
        set num_rows_open [expr 1 + (int(double($length_open)/($point_distance_column_open/2.0))) ]
        set num_rows_transition [expr int(double($length_linear)/($point_distance_column_transition/2.0)) ]
        set num_rows_closed [expr int(double($length_closed)/($point_distance_column_crimped/2.0)) ]
        
        
        while {[expr abs($length_closed - $num_rows_closed*($point_distance_column_crimped/2) ) > abs($length_closed - (($num_rows_closed + 1)*($point_distance_column_crimped/2)) )]} {
            incr num_rows_closed
            
        }
        while {[expr abs($length_linear - $num_rows_transition *($point_distance_column_transition/2) ) > abs($length_linear - (($num_rows_transition + 1)*($point_distance_column_transition/2)) )]} {
            incr num_rows_transition
            
        }
        while {[expr abs($length_open - ($num_rows_open -1 )*($point_distance_column_open/2) ) > abs($length_open - ($num_rows_open*($point_distance_column_open/2)) )]} {
            incr num_rows_open
            
        }
        
        set num_rows_total [expr $num_rows_open + $num_rows_transition +$num_rows_closed]
        
        array set points_x [FillBidimensionalArray $num_cols $num_rows_total 0.0]
        array set points_y [FillBidimensionalArray $num_cols $num_rows_total 0.0]
        array set points_z [FillBidimensionalArray $num_cols $num_rows_total 0.0]
        
        array set b_points_x [FillBidimensionalArray $num_cols $num_rows_total 0.0]
        array set b_points_y [FillBidimensionalArray $num_cols $num_rows_total 0.0]
        array set b_points_z [FillBidimensionalArray $num_cols $num_rows_total 0.0]
        
        # This assign the points with z=0 taking into acount the different distance between rows (crimped/transition/open)
        #Initialization with i=0
        
        set i 0
        for {set j 1} {$j < $num_rows_total} {incr j} {
            if {[expr $j % 2] eq 0 && $j <= $num_rows_closed} {
                set tj [expr $j-2]
                set points_y($i,$j) [expr $points_y($i,$tj) + $point_distance_column_crimped]
            } elseif {[expr $j % 2] eq 0 && $j > $num_rows_closed && $j <= [expr $num_rows_closed + $num_rows_transition]} {
                if {$j == [expr $num_rows_closed +1] } {
                    set tj [expr $j-2]
                    set points_y($i,$j) [expr $points_y($i,$tj) + $point_distance_column_transition/2 + $point_distance_column_crimped/2]
                } else {
                    set tj [expr $j-2]
                    set points_y($i,$j) [expr $points_y($i,$tj) + $point_distance_column_transition]
                }
                # if {$j eq [expr $num_rows_closed + 1] && $point_distance_column_transition < [expr $point_distance_column_crimped/2]} {
                #     set variable_repeat [expr ceil ( ($point_distance_column_crimped/2) / $point_distance_column_transition)]
                #     set points_y($i,$j) [expr $points_y($i,$j) + ($variable_repeat *$point_distance_column_transition)]
                # }
            } elseif {[expr $j % 2] eq 0 && $j > [expr $num_rows_closed + $num_rows_transition]} {
                set tj [expr $j-2]
                set points_y($i,$j) [expr $points_y($i,$tj) + $point_distance_column_open]
                if {$j eq [expr $num_rows_closed + 1 + $num_rows_transition] && $point_distance_column_open <= [expr $point_distance_column_transition/2]} {
                    set variable_repeat2 [expr ceil ( ($point_distance_column_transition/2) / $point_distance_column_open)]
                    set points_y($i,$j) [expr $points_y($i,$j) + ($variable_repeat2 * $point_distance_column_open)]

                }
            }
        }
        #The rest of the points
        for {set j 0} {$j < $num_rows_total} {incr j} {
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
                    if {[expr $i % 2] ne 0 && $j <= $num_rows_closed} {
                        set ti [expr $i-1]
                        set tj [expr $j-1]
                        set points_x($i,$j) [expr $points_x($ti,$tj) + $point_distance_row/2]
                        set points_y($i,$j) [expr $points_y($ti,$tj) + $point_distance_column_crimped/2]
                    } elseif {[expr $i % 2] ne 0 && $j > $num_rows_closed && $j <= [expr $num_rows_closed + $num_rows_transition]} {   
                        set ti [expr $i-1]
                        set tj [expr $j-1]
                        set points_x($i,$j) [expr $points_x($ti,$tj) + $point_distance_row/2]
                        set points_y($i,$j) [expr $points_y($ti,$tj) + $point_distance_column_transition/2]
                    } elseif {[expr $i % 2] ne 0 && $j > [expr $num_rows_closed + $num_rows_transition]} {
                        set ti [expr $i-1]
                        set tj [expr $j-1]
                        set points_x($i,$j) [expr $points_x($ti,$tj) + $point_distance_row/2]
                        set points_y($i,$j) [expr $points_y($ti,$tj) + $point_distance_column_open/2]
                    }
                }
            }
        }
        
        # The same as above to assign the points with z=wire diameter taking into acount the different distance between rows (crimped/transition/open)
        
        for {set j 1} {$j < $num_rows_total} {incr j} {
            if {[expr $j % 2] eq 0 && $j <= $num_rows_closed} {
                set tj [expr $j-2]
                set b_points_x(0,$j) $b_points_x(0,$tj)
                set b_points_y(0,$j) [expr $b_points_y(0,$tj) + $point_distance_column_crimped]
                set b_points_z(0,$j) [expr -1.0 * $wire_diameter]
            } elseif {[expr $j % 2] eq 0 && $j > $num_rows_closed && $j <= [expr $num_rows_closed + $num_rows_transition]} {
                if {$j == [expr $num_rows_closed +1] } {
                    set tj [expr $j-2]
                    set b_points_y(0,$j) [expr $b_points_y(0,$tj) + $point_distance_column_transition/2 + $point_distance_column_crimped/2]
                } else {
                    set tj [expr $j-2]
                    set b_points_y(0,$j) [expr $b_points_y(0,$tj) + $point_distance_column_transition]
                }
                # set tj [expr $j-2]
                # set b_points_x(0,$j) $b_points_x(0,$tj)
                # set b_points_y(0,$j) [expr $b_points_y(0,$tj) + $point_distance_column_transition]
                # if {$j eq [expr $num_rows_closed +1] && $point_distance_column_transition < [expr $point_distance_column_crimped/2]} {
                #     set variable_repeat [expr ceil ( ($point_distance_column_crimped/2) / $point_distance_column_transition)]
                #     set b_points_y(0,$j) [expr $b_points_y(0,$j) + ($variable_repeat *$point_distance_column_transition)]
                # }
                set b_points_z(0,$j) [expr -1.0 * $wire_diameter]
            } elseif {[expr $j % 2] eq 0 && $j > [expr $num_rows_closed + $num_rows_transition]} {
                set tj [expr $j-2]
                set b_points_x(0,$j) $b_points_x(0,$tj)
                set b_points_y(0,$j) [expr $b_points_y(0,$tj) + $point_distance_column_open]
                if {$j eq [expr $num_rows_closed + 1 + $num_rows_transition] && $point_distance_column_open <= [expr $point_distance_column_transition/2]} {
                    set variable_repeat2 [expr ceil ( ($point_distance_column_transition/2) / $point_distance_column_open)]
                    set b_points_y(0,$j) [expr $b_points_y(0,$j) + ($variable_repeat2 * $point_distance_column_open)]
                }
                set b_points_z(0,$j) [expr -1.0 * $wire_diameter]
            }
        }
        
        for {set j 0} {$j < $num_rows_total} {incr j} {
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
                    if {[expr $i % 2] ne 0 && $j <= $num_rows_closed} {
                        set ti [expr $i-1]
                        set tj [expr $j-1]
                        set b_points_x($i,$j) [expr $b_points_x($ti,$tj) + $point_distance_row/2]
                        set b_points_y($i,$j) [expr $b_points_y($ti,$tj) + $point_distance_column_crimped/2]
                        set b_points_z($i,$j) [expr -1.0 * $wire_diameter]
                    } elseif {[expr $i % 2] ne 0 && $j > $num_rows_closed && $j <= [expr $num_rows_closed + $num_rows_transition]} {
                        set ti [expr $i-1]
                        set tj [expr $j-1]
                        set b_points_x($i,$j) [expr $b_points_x($ti,$tj) + $point_distance_row/2]
                        set b_points_y($i,$j) [expr $b_points_y($ti,$tj) + $point_distance_column_transition/2]
                        set b_points_z($i,$j) [expr -1.0 * $wire_diameter]
                    } elseif {[expr $i % 2] ne 0 && $j > [expr $num_rows_closed + $num_rows_transition]} {
                        set ti [expr $i-1]
                        set tj [expr $j-1]
                        set b_points_x($i,$j) [expr $b_points_x($ti,$tj) + $point_distance_row/2]
                        set b_points_y($i,$j) [expr $b_points_y($ti,$tj) + $point_distance_column_open/2]
                        set b_points_z($i,$j) [expr -1.0 * $wire_diameter]
                    }
                }
            }
        }
        set num_rows $num_rows_total
        set inner_nodes [list ]
        set outer_nodes [list ]
    } else {
        set point_distance_column [expr $point_distance_row * tan($degtorad * (90-$angle))]
        set num_rows [expr 1 + (int(double($stent_length)/$point_distance_column) *2)]
        #abs( H - ( ( cant j - 1) * b/2))
        # if ((abs (H-((cantj-1)*(b/2)))) > (abs (H-(cantj*(b/2))))):
        while {[expr abs($stent_length - ($num_rows -1)* ($point_distance_column/2)) > abs($stent_length - ($num_rows*($point_distance_column/2)) )]} {
            incr num_rows
        }
        
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
        set inner_nodes [list ]
        set outer_nodes [list ]
    }
    return [list $num_rows [array get points_x]  [array get points_y ]  [array get points_z ]  [array get b_points_x ]  [array get b_points_y ]  [array get b_points_z]]
}

proc Stent::Wizard::FillBidimensionalArray { size_x size_y { value 0.0} } {
    for {set i 0} {$i < $size_x} {incr i} {
        for {set j 0} {$j < $size_y} {incr j} {
            set farray($i,$j) $value
        }
    }
    return [array get farray]
}
proc Stent::Wizard::MoveNodesToCylinder { } {
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

proc Stent::Wizard::createcrimpado { } {
    # Get the parameters
    set wire_radius [ smart_wizard::GetProperty Geometry WireRadius,value]
    set number_wires [ smart_wizard::GetProperty Geometry NumberOfWires,value]
    set angle [ smart_wizard::GetProperty Geometry AngleBetweenWires,value]
    set stent_radius [ smart_wizard::GetProperty Geometry StentRadius,value]
    set stent_radius_closed [ smart_wizard::GetProperty Geometry StentRadiusClosed,value]
    set stent_length [ smart_wizard::GetProperty Geometry StentLength,value]
    
    # Calculated parameters
    set wire_diameter [expr 2.0*$wire_radius]
    set pi [expr 2*asin(1.0)]
    set degtorad 0.0174532925199
    set stent_perimeter [expr 2*$stent_radius*$pi]
    set point_distance_row [expr $stent_perimeter/$number_wires]
    set point_distance_column [expr $point_distance_row * tan($degtorad * (90-$angle))]

    set num_cols [expr 1 + ($number_wires *2)]
    set num_rows [expr 1 + (int(double($stent_length)/$point_distance_column) *2)]
    
    if {[expr abs($stent_length - 1.0*($num_rows/1.0*($point_distance_row/2))) > abs($stent_length - 1.0*(($num_rows+1)/1.0*($point_distance_row/2)))]} {
        incr num_rows
    }
    if {[expr abs($stent_length - 1.0*($num_rows/1.0*($point_distance_row/2))) > abs($stent_length - 1.0*(($num_rows+1)/1.0*($point_distance_row/2)))]} {
        incr num_rows
    }
    
    GidUtils::DisableGraphics 
    set t0 [clock seconds]
    set old_create_always_new_point [GiD_Set CreateAlwaysNewPoint]
    GiD_Set CreateAlwaysNewPoint 1
    set xmin 1e15
    set xmax -1e15
    set ymin 1e15
    set ymax -1e15
    set zmin 1e15
    set zmax -1e15
    set length_open [expr 0.53*$stent_length]
    set length_linear [expr 0.27*$stent_length]
    set length_closed [expr 0.20*$stent_length]
    set hinv [expr 1.0/$length_linear]
    set rmin $stent_radius_closed
    set rmin2 [expr $stent_radius_closed-$wire_diameter]
    set rmax  $stent_radius
    set rmax2 [expr $stent_radius-$wire_diameter]
    set rhomedio [expr $stent_radius-$wire_radius] 
    set point_ids [GiD_Geometry list point]
    foreach num $point_ids {
        lassign [GiD_Geometry get point $num] layer x y z
        if { $xmin > $x } { set xmin $x }
        if { $xmax < $x } { set xmax $x }
        if { $ymin > $y } { set ymin $y }
        if { $ymax < $y } { set ymax $y }
    }
    
    set zA $length_closed
    set zB [expr $zA + $length_linear]
    foreach num $point_ids {
        lassign [GiD_Geometry get point $num] layer x y z    
        set rho [expr sqrt(pow($x,2)+pow($z,2))]
        set phi [expr atan2($z,$x)]
        set zeta $y
        if {$zeta<=$zA} {
            if { $rho >= $rhomedio } {
                set rho $rmin
            } elseif {$rho<= $rhomedio} {
                set rho $rmin2
            }        
        } elseif {$zeta>$zA && $zeta<$zB } {
            if {$rho>= $rhomedio} {
                set rho [expr $rmin+(($rmax-$rmin)/($zB-$zA)*($zeta-$zA))]
            } elseif { $rho<= $rhomedio }  {
                set rho [expr $rmin2 + (($rmax2-$rmin2)/($zB-$zA)*($zeta-$zA))]
            }                        
        }
        set x [expr $rho*cos($phi)]
        set y $zeta
        set z [expr $rho*sin($phi)]
        
        GiD_Process Mescape Geometry Edit MovePoint $num $x $y $z escape

    }
    GiD_Set CreateAlwaysNewPoint $old_create_always_new_point  
    GidUtils::EnableGraphics 
    GiD_Process 'Zoom Frame 
}

# proc Stent::Wizard::DivideNurbsLines { } {
#     set number_wires [smart_wizard::GetProperty Geometry NumberOfWires,value]
 
# }

proc Stent::Wizard::HideCrimpedRadius { } {
    
    set crimped_on [ smart_wizard::GetProperty Geometry CrimpedButton,value]
    if {$crimped_on == "Yes"} {
        #mala suerte
    } else {
        
    }
}

proc Stent::Wizard::HideVariableAngleButton { } {
    
    set variable_angle [ smart_wizard::GetProperty Geometry VariableAngleButton,value]
    if {$variable_angle == "Yes"} {
        #nosequeponer
    } else {
        
    }
}

proc Stent::Wizard::HideOneOverTwoButton { } {
    
    set one_over_two [ smart_wizard::GetProperty Geometry OneOverTwoButton,value]
    if {$one_over_two  == "Yes"} {
        #nosequeponer
    } else {
        
    }
}

proc Stent::Wizard::HideNurbsButton { } {
    
    set Nurbs_Line  [ smart_wizard::GetProperty Geometry NurbsButton,value]
    if {$Nurbs_Line  == "Yes"} {
        #nosequeponer
    } else {
        
    }
}


Stent::Wizard::Init