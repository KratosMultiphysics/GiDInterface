namespace eval ::EmbeddedFluid {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable oldMeshType
    variable kratos_name
}

proc ::EmbeddedFluid::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable attributes
    variable kratos_name

    apps::LoadAppById "Fluid"
    set kratos_name $::Fluid::kratos_name

    set dir [apps::getMyDir "EmbeddedFluid"]
    set attributes [dict create]

    set prefix EMBFL

    set ::Model::ValidSpatialDimensions [list 3D]
    spdAux::SetSpatialDimmension "3D"

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    dict set attributes UseIntervals 1

    LoadMyFiles
    Kratos::AddRestoreVar "::GidPriv(DuplicateEntities)"
    set ::GidPriv(DuplicateEntities) 1

    #::spdAux::CreateDimensionWindow
}

proc ::EmbeddedFluid::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir examples examples.tcl]]
    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir xml ImportWindowController.tcl]]
    uplevel #0 [list source [file join $dir xml BoundingBoxWindowController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}

proc ::EmbeddedFluid::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::EmbeddedFluid::BeforeMeshGeneration {elementsize} {
    variable oldMeshType
    
    set project_path [GiD_Info project modelname]
    if {$project_path ne "UNNAMED"} {
        catch {file delete -force [file join [write::GetConfigurationAttribute dir] "[Kratos::GetModelName].post.res"]}
        # Set Octree
        set oldMeshType [GiD_Set MeshType]
        ::GiD_Set MeshType 2
    } else {
        after 500 {WarnWin "You need to save the project before meshing"}
        return "-cancel-"
    }
}

proc ::EmbeddedFluid::AfterMeshGeneration {fail} {
    variable oldMeshType
    GiD_Set MeshType $oldMeshType
}

::EmbeddedFluid::Init
