namespace eval ::DEMPFEM {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::DEMPFEM::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes

    set attributes [dict create]
    set kratos_name DEMPFEMapplication

    set dir [apps::getMyDir "DEMPFEM"]
    set prefix DEMPFEM_

    set ::spdAux::TreeVisibility 0

    apps::LoadAppById "DEM"
    apps::LoadAppById "PfemFluid"

    # Intervals
    dict set attributes UseIntervals 1

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    set ::Model::ValidSpatialDimensions [list 3D]
    LoadMyFiles
    # ::spdAux::CreateDimensionWindow
}

proc ::DEMPFEM::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $dir examples examples.tcl]]
}

proc ::DEMPFEM::BeforeMeshGeneration {elementsize} {
    ::DEM::BeforeMeshGeneration $elementsize
}

proc ::DEMPFEM::AfterMeshGeneration {fail} {
    ::DEM::AfterMeshGeneration $fail
}

proc ::DEMPFEM::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::DEMPFEM::CustomToolbarItems { } {
    variable dir
    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::DEMPFEM::examples::InnerSphere] [= "Example\nInnerSphere"]
}

proc ::DEMPFEM::AfterSaveModel {filespd} {
    ::DEM::AfterSaveModel $filespd
}

::DEMPFEM::Init
