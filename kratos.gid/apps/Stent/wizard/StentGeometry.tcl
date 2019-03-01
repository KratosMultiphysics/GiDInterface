
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
    set pi [expr 2*asin(1.0)]
    set degtorad 0.0174532925199
    set stent_perimeter [expr 2*$stent_radius*$pi]
    set point_distance_row [expr $stent_perimeter/$number_wires]
    set point_distance_column [expr $point_distance_row * tan($degtorad * (90-$angle))]

    set num_rows [expr 1 + ($number_wires *2)]
    set num_cols [expr 2 + (($stent_length/$point_distance_column) *2)]

    set points_x(0,0) 0.0
    set points_y(0,0) 0.0
    set points_z(0,0) 0.0

    set i 0
    for {set j 1} {$j <= $num_rows} {incr j} {
        if {[expr $i % 2] eq 0} {
            set tj [expr $j-2]
            set points_y($i,$j) [expr $points_y($i,$tj) + $point_distance_column]
        }
    }
}

proc ValidateDraw { } {
    return 0
}

Stent::Wizard::Init

