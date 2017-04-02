namespace eval Numa::xml {
    variable dir
}

proc Numa::xml::Init { } {
    variable dir
    Model::InitVariables dir $Numa::dir
    
    Model::ForgetMaterials
    Model::getMaterials Materials.xml
    
    CleanConditions
}

proc Numa::xml::getUniqueName {name} {
    return CS$name
}


proc ::Numa::xml::MultiAppEvent {args} {
    ::Dam::xml::MultiAppEvent $args
    if {$args eq "init"} {
        spdAux::parseRoutes
        spdAux::ConvertAllUniqueNames Dam CS
    }
}

proc Numa::xml::CustomTree { args } {
    if {[catch {Dam::xml::CustomTree} fid]} {
        W "Error during Dam::xml::CustomTree\n$fid"
    }
    
    set TypeOfProblem [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute DamTypeofProblem]]
    set SolStrat [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute DamSolStrat]]
    set Scheme [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute DamScheme]]
    $TypeOfProblem setAttribute values Thermo-Mechanical
    $TypeOfProblem setAttribute state disabled
    $SolStrat setAttribute values Newton-Raphson
    $SolStrat setAttribute state disabled
    $Scheme setAttribute values Newmark
    $Scheme setAttribute state disabled

    set AnalysisType [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute DamThermoMechaAnalysisType]]
    $AnalysisType setAttribute values Linear
    $AnalysisType setAttribute state disabled
    
    set mechanicalstrategyparams [[customlib::GetBaseRoot] selectNodes [spdAux::getRoute DamThermo-Mechanical-MechDataParameters]]
    $mechanicalstrategyparams setAttribute state disabled
    
}

proc Numa::xml::CleanConditions { } {
    set NodalConditions [list ]
    foreach nc [Model::GetNodalConditions] {
        if {[$nc getName] in [list DISPLACEMENT VELOCITY ACCELERATION INITIALTEMPERATURE BOFANGTEMPERATURE]} {lappend NodalConditions $nc}
    }
    set Model::NodalConditions $NodalConditions
    
    set Conditions [list ]
    foreach c [Model::GetConditions] {
        if {[$c getName] in [list SelfWeight3D SelfWeight2D ThermalParameters3D ThermalParameters2D HydroLinePressure2D HydroSurfacePressure3D StraightUpliftLinePressure2D StraightUpliftSurfacePressure3D CircularUpliftSurfacePressure3D]} {lappend Conditions $c}
    }
    set Model::Conditions $Conditions
}
Numa::xml::Init
