namespace eval ::BasicFlow::examples {
    namespace path ::BasicFlow
    Kratos::AddNamespace [namespace current]
}

# Common functions for all examples that uses BasicFlow App
proc ::BasicFlow::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}