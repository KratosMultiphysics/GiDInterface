namespace eval ::Fluid::examples {
    namespace path ::Fluid
    Kratos::AddNamespace [namespace current]
}

# Common functions for all examples that uses Fluid App
proc ::Fluid::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}

proc ::Fluid::examples::AddCuts { } {
    # Cuts
    set results "[spdAux::getRoute FLResults]/container\[@n='GiDOutput'\]"
    set cp [[customlib::GetBaseRoot] selectNodes "$results/container\[@n = 'CutPlanes'\]/blockdata\[@name = 'CutPlane'\]"]
    [$cp selectNodes "./value\[@n = 'point'\]"] setAttribute v "0.0,0.5,0.0"
}