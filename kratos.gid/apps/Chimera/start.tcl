namespace eval ::Chimera {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::Chimera::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable attributes
    variable kratos_name

    apps::LoadAppById "Fluid"
    set kratos_name $::Fluid::kratos_name
    set dir [apps::getMyDir "Chimera"]
    
    set ::Model::ValidSpatialDimensions [list 2D]
    spdAux::SetSpatialDimmension "2D"
    spdAux::processIncludes

    set attributes [dict create]

    set prefix Chim

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    dict set attributes UseIntervals 1

    LoadMyFiles
}

proc ::Chimera::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}

proc ::Chimera::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

# proc ::Chimera::BeforeMeshGeneration {elementsize} {
#     variable oldMeshType
    
#     set project_path [GiD_Info project modelname]
#     if {$project_path ne "UNNAMED"} {
#         catch {file delete -force [file join [write::GetConfigurationAttribute dir] "[Kratos::GetModelName].post.res"]}
#         # Set Octree
#         set oldMeshType [GiD_Set MeshType]
#         ::GiD_Set MeshType 2
#     } else {
#         after 500 {WarnWin "You need to save the project before meshing"}
#         return "-cancel-"
#     }
# }

# proc ::Chimera::AfterMeshGeneration {fail} {
#     variable oldMeshType
#     GiD_Set MeshType $oldMeshType
# }

::Chimera::Init
