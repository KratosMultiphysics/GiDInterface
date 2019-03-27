
proc Kratos::ForceRun { } {
    # validated by escolano@cimne.upc.edu
    variable must_write_calc_data
    set temp $must_write_calc_data
    set must_write_calc_data 0
    GiD_Process Utilities Calculate
    set must_write_calc_data $temp
}

proc Kratos::DestroyWindows {} {
    gid_groups_conds::close_all_windows
    spdAux::DestroyWindow
    if {$::Kratos::kratos_private(UseWizard)} {
        smart_wizard::DestroyWindow
    }
    ::Kratos::EndCreatePreprocessTBar
}

proc Kratos::ResetModel { } {
    foreach layer [GiD_Info layers] {
        GiD_Process 'Layers Delete $layer Yes escape escape
    }
    foreach group [GiD_Groups list] {
        if {[GiD_Groups exists $group]} {GiD_Groups delete $group}
    }
}

proc Kratos::GetModelName { } {
    return [file tail [GiD_Info project ModelName]]
}

proc Kratos::IsModelEmpty { } {
    if {[GiD_Groups list] != ""} {return false}
    if {[GiD_Layers list] != "Layer0"} {return false}
    if {[GiD_Geometry list point 1:end] != ""} {return false}
    return true
}

proc Kratos::CheckValidProjectName {modelname} {
    set fail 0
    set filename [file tail $modelname]
    if {[string is double $filename]} {set fail 1}
    if {[write::isBoolean $filename]} {set fail 1}
    if {$filename == "null"} {set fail 1}
    return $fail
}

proc Kratos::PrintArray {a {pattern *}} {
    # ABSTRACT:
    # Print the content of array nicely
    
    upvar 1 $a array  
    if {![array exists array]} {
        error "\"$a\" isn't an array"
    }
    set maxl 0
    foreach name [lsort [array names array $pattern]] {
        if {[string length $name] > $maxl} {
            set maxl [string length $name]
        }
    }
    set maxl [expr {$maxl + [string length $a] + 2}]
    foreach name [lsort [array names array $pattern]] {
        set nameString [format %s(%s) $a $name]
        W "[format "%-*s = %s" $maxl $nameString $array($name)]"
    }
}