namespace eval Structural::write {
    variable validApps
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    variable writeCoordinatesByGroups
}

proc Structural::write::Init { } {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    set ConditionsDictGroupIterators [dict create]
    set NodalConditionsGroup [list ]
    
    variable validApps
    set validApps [list "Structural"]
    
    variable writeCoordinatesByGroups
    set writeCoordinatesByGroups 0
}


proc Structural::write::AddValidApps {appList} {
    variable validApps

    lappend validApps $appList
}

proc Structural::write::writeCustomFilesEvent { } {
    WriteMaterialsFile
    write::writePropertiesJsonFile
    
    write::CopyFileIntoModel "python/KratosStructural.py"
    set paralleltype [write::getValue ParallelType]
    set orig_name "KratosStructural.py"
    
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc Structural::write::SetCoordinatesByGroups {value} {
    variable writeCoordinatesByGroups
    set writeCoordinatesByGroups $value
}

# MDPA Blocks

proc Structural::write::writeModelPartEvent { } {
    variable writeCoordinatesByGroups
    variable validApps
    variable ConditionsDictGroupIterators
    write::initWriteData "STParts" "STMaterials"
    
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::writeMaterials $validApps
    #write::writeTables
    if {$writeCoordinatesByGroups} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}
    write::writeElementConnectivities
    writeConditions
    writeMeshes
    set basicConds [write::writeBasicSubmodelParts [getLastConditionId]]
    set ConditionsDictGroupIterators [dict merge $ConditionsDictGroupIterators $basicConds]
    # W $ConditionsDictGroupIterators
    #writeCustomBlock
}


proc Structural::write::writeConditions { } {
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [write::writeConditions "STLoads"]
}

proc Structural::write::writeMeshes { } {
    
    write::writePartMeshes
    
    # Solo Malla , no en conditions
    write::writeNodalConditions "STNodalConditions"
    
    # A Condition y a meshes-> salvo lo que no tenga topologia
    writeLoads
}

proc Structural::write::writeLoads { } {
    variable ConditionsDictGroupIterators
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "STLoads"]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        #W "Writing mesh of Load $groupid"
        if {$groupid in [dict keys $ConditionsDictGroupIterators]} {
            ::write::writeGroupMesh [[$group parent] @n] $groupid "Conditions" [dict get $ConditionsDictGroupIterators $groupid]
        } else {
            ::write::writeGroupMesh [[$group parent] @n] $groupid "nodal"
        }
    }
}


proc Structural::write::writeCustomBlock { } {
    write::WriteString "Begin Custom"
    write::WriteString "Custom write for Structural, any app can call me, so be careful!"
    write::WriteString "End Custom"
    write::WriteString ""
}

proc Structural::write::getLastConditionId { } { 
    variable ConditionsDictGroupIterators
    set top 1
    if {$ConditionsDictGroupIterators ne ""} {
        foreach {group iters} $ConditionsDictGroupIterators {
            set top [expr max($top,[lindex $iters 1])]
        }
    }
    return $top
}

# Custom files
proc Structural::write::WriteMaterialsFile { } {
    variable validApps
    
    write::OpenFile "materials.py"
    
    set str "
from __future__ import print_function, absolute_import, division #makes KratosMultiphysics backward compatible with python 2.6 and 2.7
# Importing the Kratos Library
from KratosMultiphysics import *
from KratosMultiphysics.SolidMechanicsApplication import *
#from beam_sections_python_utility import SetProperties
#from beam_sections_python_utility import SetMaterialProperties

def AssignMaterial(Properties):
    # material for solid material
"
    foreach {part mat} [write::getMatDict] {
        if {[dict get $mat APPID] in $validApps} {
            append str "
    prop_id = [dict get $mat MID];
    prop = Properties\[prop_id\]
    mat = [dict get $mat ConstitutiveLaw]()
    prop.SetValue(CONSTITUTIVE_LAW, mat.Clone())
        "
        }
    }
    
    write::WriteString $str
    write::CloseFile
    
}

proc Structural::write::GetUsedElements { {get "Objects"} } {
    set xp1 "[spdAux::getRoute STParts]/group"
    set lista [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem_name [get_domnode_attribute [$gNode selectNodes ".//value\[@n='Element']"] v]
        set e [Model::getElement $elem_name]
        if {$get eq "Name"} { set e [$e getName] }
        lappend lista $e
    }
    return $lista
}



Structural::write::Init
