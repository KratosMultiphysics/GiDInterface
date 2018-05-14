namespace eval Solid::write {
    variable mat_dict
    variable validApps
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    variable writeCoordinatesByGroups
}

proc Solid::write::Init { } {
    # Namespace variables inicialization
    variable mat_dict
    set mat_dict ""
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    set ConditionsDictGroupIterators [dict create]
    set NodalConditionsGroup [list ]
    
    variable validApps
    set validApps [list "Solid"]
    
    variable writeCoordinatesByGroups
    set writeCoordinatesByGroups 0
}

proc Solid::write::AddValidApps {appList} {
    variable validApps
    
    lappend validApps $appList
}

proc Solid::write::writeCustomFilesEvent { } {
    WriteMaterialsFile
    
    write::CopyFileIntoModel "python/RunMainSolid.py"
    set paralleltype [write::getValue ParallelType]
    set orig_name "RunMainSolid.py"
    
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc Solid::write::SetCoordinatesByGroups {value} {
    variable writeCoordinatesByGroups
    set writeCoordinatesByGroups $value
}

# MDPA Blocks

proc Solid::write::writeModelPartEvent { } {
    variable writeCoordinatesByGroups
    variable validApps
    variable ConditionsDictGroupIterators
    write::initWriteData "SLParts" "SLMaterials"
    
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


proc Solid::write::writeConditions { } {
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [write::writeConditions "SLLoads"]
}

proc Solid::write::writeMeshes { } {
    
    write::writePartSubModelPart
    
    # Solo Malla , no en conditions
    write::writeNodalConditions "SLNodalConditions"
    
    # A Condition y a meshes-> salvo lo que no tenga topologia
    writeLoads
}

proc Solid::write::writeLoads { } {
    variable ConditionsDictGroupIterators
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute "SLLoads"]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        #W "Writing mesh of Load $groupid"
        if {$groupid in [dict keys $ConditionsDictGroupIterators]} {
            ::write::writeGroupSubModelPart [[$group parent] @n] $groupid "Conditions" [dict get $ConditionsDictGroupIterators $groupid]
        } else {
            ::write::writeGroupSubModelPart [[$group parent] @n] $groupid "nodal"
        }
    }
}


proc Solid::write::writeCustomBlock { } {
    write::WriteString "Begin Custom"
    write::WriteString "Custom write for Solid, any app can call me, so be careful!"
    write::WriteString "End Custom"
    write::WriteString ""
}

proc Solid::write::getLastConditionId { } { 
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
proc Solid::write::WriteMaterialsFile { } {
    variable validApps
    
    set filename "Materials.json"
    set mats_json [Solid::write::getPropertiesList SLParts]

    write::OpenFile $filename
    write::WriteJSON $mats_json
    write::CloseFile
}

proc Solid::write::WriteMaterialsFileOld { } {
    variable validApps
    
    set filename "Materials.json"
    set mats_json [Solid::write::getPropertiesList SLParts]

    write::OpenFile $filename
    write::WriteJSON $mats_json
    write::CloseFile
    
    write::OpenFile "materials.py"
    
    set str "
from __future__ import print_function, absolute_import, division #makes KratosMultiphysics backward compatible with python 2.6 and 2.7
# Importing the Kratos Library
from KratosMultiphysics import *
from KratosMultiphysics.SolidMechanicsApplication import *
from beam_sections_python_utility import SetProperties
from beam_sections_python_utility import SetMaterialProperties

def AssignMaterial(Properties):
    # material for solid material"
    foreach {part mat} [write::getMatDict] {
        if {[dict get $mat APPID] in $validApps} {
	    set law_name [dict get $mat ConstitutiveLaw]
	    set law_type [[Model::getConstitutiveLaw $law_name] getAttribute "Type"]
	    set public_name [[Model::getConstitutiveLaw $law_name] getAttribute "pn"]
	    if {$law_type eq "1D_UR"} {
		append str "
    prop_id = [dict get $mat MID];
    prop = Properties\[prop_id\]
"
		if {$public_name eq "Circular"} {
		    append str "
    section_type = \"$public_name\"
    prop_list = \[\]	    
    prop_list.append([dict get $mat DIAMETER])
    prop = SetProperties(section_type,prop_list,prop)
"
		} elseif {$public_name eq "Tubular"} {
		    append str "		    
    section_type = \"$public_name\"
    prop_list = \[\]		    
    prop_list.append([dict get $mat DIAMETER])
    prop_list.append([dict get $mat THICKNESS])
    prop = SetProperties(section_type,prop_list,prop)
"
		} elseif {$public_name eq "Rectangular"} {
		    append str "		    
    section_type = \"$public_name\"
    prop_list = \[\]		    
    prop_list.append([dict get $mat HEIGHT])
    prop_list.append([dict get $mat WIDTH])
    prop = SetProperties(section_type,prop_list,prop)
" 
		} elseif {$public_name eq "UserDefined"} {
		    append str "	
    section_type = \"$public_name\"
    prop_list = \[\]		    
    prop_list.append([dict get $mat AREA])	    
    prop_list.append([dict get $mat INERTIA_X])
    prop_list.append([dict get $mat INERTIA_Y])
    prop = SetProperties(section_type,prop_list,prop)
" 		
		} elseif {$public_name eq "UserParameters"} {
		    append str "	
    section_type = \"UserDefined\"
    prop_list = \[\]		    
    prop_list.append([dict get $mat YOUNGxAREA])	    
    prop_list.append([dict get $mat SHEARxREDUCED_AREA])
    prop_list.append([dict get $mat YOUNGxINERTIA_X])
    prop_list.append([dict get $mat YOUNGxINERTIA_Y])
    prop_list.append([dict get $mat SHEARxPOLAR_INERTIA])
    prop = SetMaterialProperties(section_type,prop_list,prop)
"
		} else {
		    append str "	
    section_type = \"$public_name\"
    prop_list = \[\]		    
    prop_list.append([dict get $mat SIZE])
    prop = SetProperties(section_type,prop_list,prop)
"
		}
	    } {
		append str "
    prop_id = [dict get $mat MID];
    prop = Properties\[prop_id\]
    mat = [dict get $mat ConstitutiveLaw]()
    prop.SetValue(CONSTITUTIVE_LAW, mat.Clone())
"
		    
	    }
        }
    }
    
if 0 {
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
}    
    write::WriteString $str
    write::CloseFile

}

proc Solid::write::getPropertiesList {parts_un} {
    set mat_dict [write::getMatDict]
    set props_dict [dict create]
    set props [list ]
    set sections [list ]

    set python_module "assign_materials_process"
    set process_name  "AssignMaterialsProcess"
    set help  "This process creates a material and assigns its properties"
    
    #set doc $gid_groups_conds::doc
    #set root [$doc documentElement]
    set root [customlib::GetBaseRoot]

    set xp1 "[spdAux::getRoute $parts_un]/group"
    foreach gNode [$root selectNodes $xp1] {
        set group [get_domnode_attribute $gNode n]
        set sub_model_part [write::getSubModelPartId Parts $group]
        if { [dict exists $mat_dict $group] } {
            set law_id [dict get $mat_dict $group MID]
	    set law_name [dict get $mat_dict $group ConstitutiveLaw]
	    set law_type [[Model::getConstitutiveLaw $law_name] getAttribute "Type"]
	    set mat_name [dict get $mat_dict $group Material]
	    
	    if {$law_type eq "1D_UR"} {
		set python_module "assign_sections_process"
		set process_name  "AssignSectionsProcess"
		set help  "This process creates a section and assigns its properties"
	    }
	    
	    set prop_dict [dict create]		
	    set kratos_module [[Model::getConstitutiveLaw $law_name] getAttribute "kratos_module"]
	    dict set prop_dict "python_module" $python_module
	    dict set prop_dict "kratos_module" $kratos_module
	    dict set prop_dict "help" $help
	    dict set prop_dict "process_name" $process_name 
 
            set exclusionList [list "MID" "APPID" "ConstitutiveLaw" "Material" "Element"]
            set variables_dict [dict create]
            foreach prop [dict keys [dict get $mat_dict $group] ] {
                if {$prop ni $exclusionList} {
                    dict set variables_list $prop [write::getFormattedValue [dict get $mat_dict $group $prop]]
                }
            }

	    set material_dict [dict create]
	    dict set material_dict "model_part_name" $sub_model_part
            dict set material_dict "properties_id" $law_id
	    dict set material_dict "material_name" $mat_name
	    
	    if {$law_type eq "1D_UR"} {
		set public_name [[Model::getConstitutiveLaw $law_name] getAttribute "pn"]
		dict set material_dict "section_type" $public_name
	    } else { 
		set law_full_name [join [list "KratosMultiphysics" $kratos_module $law_name] "."]
		dict set material_dict constitutive_law [dict create name $law_full_name]
	    }
            dict set material_dict variables $variables_list
            dict set material_dict tables dictnull
            dict set prop_dict Parameters $material_dict
	    
	    lappend props $prop_dict
        }

    }

    dict set props_dict material_models_list $props
    
    return $props_dict
}

proc Solid::write::GetUsedElements { {get "Objects"} } {
    set xp1 "[spdAux::getRoute SLParts]/group"
    set lista [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem_name [get_domnode_attribute [$gNode selectNodes ".//value\[@n='Element']"] v]
        set e [Model::getElement $elem_name]
        if {$get eq "Name"} { set e [$e getName] }
        lappend lista $e
    }
    return $lista
}

proc Solid::write::GetDefaultOutputDict { {appid ""} } {
    set outputDict [dict create]
    set resultDict [dict create]
    
    if {$appid eq ""} {set results_UN Results } {set results_UN [apps::getAppUniqueName $appid Results]}
    set GiDPostDict [dict create]
    dict set GiDPostDict GiDPostMode                [write::getValue $results_UN GiDPostMode]
    dict set GiDPostDict WriteDeformedMeshFlag      [write::getValue $results_UN GiDWriteMeshFlag]
    dict set GiDPostDict WriteConditionsFlag        [write::getValue $results_UN GiDWriteConditionsFlag]
    dict set GiDPostDict MultiFileFlag              [write::getValue $results_UN GiDMultiFileFlag]
    dict set resultDict gidpost_flags $GiDPostDict
    
    dict set resultDict file_label                 [write::getValue $results_UN FileLabel]
    set outputCT [write::getValue $results_UN OutputControlType]
    dict set resultDict output_control_type $outputCT
    if {$outputCT eq "time"} {set frequency [write::getValue $results_UN OutputDeltaTime]} {set frequency [write::getValue $results_UN OutputDeltaStep]}
    dict set resultDict output_frequency $frequency
    
    dict set resultDict node_output           [write::getValue $results_UN NodeOutput]
    
    #dict set resultDict plane_output [write::GetCutPlanesList $results_UN]
    
    dict set resultDict nodal_results [write::GetResultsList $results_UN OnNodes]
    dict set resultDict gauss_point_results [write::GetResultsList $results_UN OnElement]
    
    dict set outputDict "result_file_configuration" $resultDict
    #dict set outputDict "point_data_configuration" [write::GetEmptyList]
    return $outputDict
}

Solid::write::Init
