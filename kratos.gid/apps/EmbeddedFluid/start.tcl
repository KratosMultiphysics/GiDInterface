namespace eval ::EmbeddedFluid {
    Kratos::AddNamespace [namespace current]
    
    # Variable declaration
    variable dir
    variable _app
    
    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::EmbeddedFluid::Init { app } {
    # Variable initialization
    variable dir
    variable _app
    set _app $app

    set dir [apps::getMyDir "EmbeddedFluid"]

    Kratos::AddRestoreVar "::GidPriv(DuplicateEntities)"
    set ::GidPriv(DuplicateEntities) 1

    ::EmbeddedFluid::xml::Init
    ::EmbeddedFluid::xml::BoundingBox::Init
    ::EmbeddedFluid::write::Init
}

proc ::EmbeddedFluid::BeforeMeshGeneration {elementsize} {
    variable oldMeshType
    
    # Delete previous results
    catch {file delete -force [file join [write::GetConfigurationAttribute dir] "[Kratos::GetModelName].post.res"]}

    # Set Octree as volume mesher
    set oldMeshType [GiD_Set MeshType]
    ::GiD_Set MeshType 2
    
}

# Restore the previous mesher
proc ::EmbeddedFluid::AfterMeshGeneration {fail} {
    variable oldMeshType
    GiD_Set MeshType $oldMeshType
}

# Add buttons to the left toolbar
proc ::EmbeddedFluid::CustomToolbarItems { } {
    # Stl import
    Kratos::ToolbarAddItem "ImportMesh" "Import.png" [list -np- EmbeddedFluid::xml::ImportMeshWindow] [= "Import embedded mesh"]
    # Move the imported stl
    Kratos::ToolbarAddItem "Move" "move.png" [list -np- CopyMove Move] [= "Move the geometry/mesh"]
    # Create the bounding box
    Kratos::ToolbarAddItem "Box" "box.png" [list -np- EmbeddedFluid::xml::BoundingBox::CreateWindow] [= "Generate the bounding box"]
}
