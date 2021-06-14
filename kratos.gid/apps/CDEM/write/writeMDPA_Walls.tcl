

# Overwritten to ad TOP BOTTOM params
proc DEM::write::DefineFEMExtraConditions {props} {
    set material_analysis [write::getValue DEMTestMaterial Active]
    if {$material_analysis == "true"} {
        set is_material_test [dict get $props Material Variables MaterialTest]
        if {$is_material_test == "true"} {
            set as_condition [dict get $props Material Variables DefineTopBot]
            if {$as_condition eq "top"} {
                write::WriteString "    TOP 1"
                write::WriteString "    BOTTOM 0"
            } else {
                write::WriteString "    TOP 0"
                write::WriteString "    BOTTOM 1"
            }
        }
    } else {
        write::WriteString "    TOP 0"
        write::WriteString "    BOTTOM 0"
    }
    
    set GraphPrint [dict get $props Material Variables GraphPrint]
    set GraphPrintval 0
    if {[write::isBooleanTrue $GraphPrint]} {
        set GraphPrintval 1
    } 
    write::WriteString "    FORCE_INTEGRATION_GROUP $GraphPrintval"
}