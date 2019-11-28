
proc ::MPM::examples::FallingSandBall {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawFallingSandBallGeometry$::Model::SpatialDimension
    AssignGroupsFallingSandBall$::Model::SpatialDimension
    TreeAssignationFallingSandBall$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc MPM::examples::DrawFallingSandBallGeometry3D {args} {
    
}
proc MPM::examples::DrawFallingSandBallGeometry2D {args} {
    

}


# Group assign
proc MPM::examples::AssignGroupsFallingSandBall2D {args} {
    
}
proc MPM::examples::AssignGroupsFallingSandBall3D {args} {
    
}

# Tree assign
proc MPM::examples::TreeAssignationFallingSandBall3D {args} {
    
}
proc MPM::examples::TreeAssignationFallingSandBall2D {args} {
    
}

proc MPM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}