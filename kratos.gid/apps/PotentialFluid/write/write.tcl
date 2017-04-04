namespace eval PotentialFluid::write {

}

proc PotentialFluid::write::Init { } {
    # Namespace variables inicialization
}

# Events
proc PotentialFluid::write::writeModelPartEvent { } {
    Fluid::write::AddValidApps "PotentialFluid"
    set err [Fluid::write::Validate]
    if {$err ne ""} {error $err}
    write::initWriteData $Fluid::write::PartsUN "PTFLMaterials"
    write::writeModelPartData
    Fluid::write::writeProperties
    write::writeMaterials $Fluid::write::validApps
    write::writeNodalCoordinatesOnParts
    write::writeElementConnectivities
    Fluid::write::writeConditions
    Fluid::write::writeMeshes
}
proc PotentialFluid::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/KratosPotentialFlow.py"
    write::RenameFileInModel "KratosPotentialFlow.py" "MainKratos.py"
}


PotentialFluid::write::Init
