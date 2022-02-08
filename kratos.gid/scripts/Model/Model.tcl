##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval ::Model {
    variable SpatialDimension
    variable ValidSpatialDimensions
    variable SolutionStrategies
    variable Materials
    variable Elements
    variable Conditions
    variable NodalConditions
    variable ConstitutiveLaws
    variable Solvers
    variable Processes
    
    variable dir
}

proc Model::Init { } {
    variable SpatialDimension
    variable ValidSpatialDimensions
    variable dir
    variable SolutionStrategies
    variable Elements
    variable Materials
    variable Conditions
    variable NodalConditions
    variable ConstitutiveLaws
    variable Solvers
    variable Processes
        
    set SolutionStrategies [list ]
    set Elements [list ]
    set Materials [list ]
    set Conditions [list ]
    set NodalConditions [list ]
    set ConstitutiveLaws [list ]
    set Solvers [list ]
    set Processes [list ]
    
    set SpatialDimension "3D"
    set ValidSpatialDimensions [list 2D 3D]
}

proc Model::InitVariables {varName varValue} {
    catch {
        set ::Model::$varName $varValue
    }
}

proc Model::getSolutionStrategies { SolutionStrategyFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $SolutionStrategyFileName]] doc
    ParseSolutionStrategies $doc
}

proc Model::getElements { ElementsFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $ElementsFileName]] doc
    ParseElements $doc
}
proc Model::getConditions { ConditionsFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $ConditionsFileName]] doc
    ParseConditions $doc
}
proc Model::getNodalConditions { NodalConditionsFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $NodalConditionsFileName]] doc
    ParseNodalConditions $doc
}

proc Model::getConstitutiveLaws { ConstitutiveLawsFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $ConstitutiveLawsFileName]] doc
    ParseConstitutiveLaws $doc
}

proc Model::getSolvers { SolversFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $SolversFileName]] doc
    ParseSolvers $doc
}

proc Model::getProcesses { ProcessesFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $ProcessesFileName]] doc
    ParseProcesses $doc
}
proc Model::getMaterials { MaterialsFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $MaterialsFileName]] doc
    ParseMaterials $doc
}

proc Model::DestroyEverything { } {
    Init
}

proc Model::Clone {orig} {
    set new [oo::copy ::$orig]
    return $new
}

Model::Init