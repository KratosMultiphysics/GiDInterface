namespace eval ::FreeSurface::examples {
    namespace path ::FreeSurface
    Kratos::AddNamespace [namespace current]
}

# Common functions for all examples that uses Fluid App
proc ::FreeSurface::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}

