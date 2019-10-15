namespace eval Pfem::write {
    variable remesh_domains_dict
    variable bodies_list
    variable writeAttributes
}

proc Pfem::write::Init { } {
    variable remesh_domains_dict
    set remesh_domains [dict create ]
    variable bodies_list
    set bodies_list [list ]
    Solid::write::AddValidApps "Pfem"

    SetAttribute parts_un PFEM_Parts
    SetAttribute nodal_conditions_un PFEM_NodalConditions
    SetAttribute conditions_un PFEM_Loads
    SetAttribute materials_un PFEM_Materials
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute validApps [list "Pfem"]
    SetAttribute materials_file "Materials.json"
    SetAttribute properties_location "json"
}

proc Pfem::write::writeParametersEvent { } {
    write::WriteJSON [getParametersDict]
    write::SetParallelismConfiguration
}

# Model Part Blocks
proc Pfem::write::writeModelPartEvent { } {
    # Init data
    SetAttribute main_script_file [Pfem::write::GetMainScriptFilename]
    write::initWriteConfiguration [GetAttributes]

    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::writeMaterials "Pfem"

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (Groups on FLParts)
    write::writeElementConnectivities

    # Nodal conditions and conditions
    Solid::write::writeConditions

    # SubmodelParts
    Pfem::write::writeSubmodelParts
}

proc Pfem::write::writeSubmodelParts { } {
    # Submodelparts for Parts
    write::writePartSubModelPart

    # Solo Malla , no en conditions
    writeNodalConditions [GetAttribute nodal_conditions_un]

    # A Condition y a meshes-> salvo lo que no tenga topologia
    Solid::write::writeLoads
}


proc Pfem::write::writeNodalConditions { keyword } {
    write::writeNodalConditions $keyword
    return ""

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $keyword]/container/blockdata"
    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set cid [[$group parent] @n]
        set groupid [$group @name]
        set groupid [write::GetWriteGroupName $groupid]
        # TODO: Aqui hay que gestionar la escritura de los bodies
        # Una opcion es crear un megagrupo temporal con esa informacion, mandar a pintar, y luego borrar el grupo.
        # Otra opcion es no escribir el submodelpart. Ya tienen las parts y el project parameters tiene el conformado de los bodies
        ::write::writeGroupSubModelPart $cid $groupid "nodal"
    }
}

# Custom files (Copy python scripts, write materials file...)
proc Pfem::write::writeCustomFilesEvent { } {
    Pfem::write::WriteMaterialsFile

    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name]
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc Pfem::write::WriteMaterialsFile { } {
    variable validApps

    set mats_json [Pfem::write::getPropertiesList [GetAttribute parts_un]]

    write::OpenFile [GetAttribute materials_file]
    write::WriteJSON $mats_json
    write::CloseFile
}

proc Pfem::write::getPropertiesList {parts_un} {
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
		if { $law_name ne "None" } {

		    set law_type [[Model::getConstitutiveLaw $law_name] getAttribute "Type"]
		    set mat_name [dict get $mat_dict $group Material]
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

		    set law_full_name [join [list "KratosMultiphysics" $kratos_module $law_name] "."]
		    dict set material_dict constitutive_law [dict create name $law_full_name]
		    dict set material_dict variables $variables_list
		    dict set material_dict tables dictnull
		    dict set prop_dict Parameters $material_dict

		    lappend props $prop_dict
		}
	    }

	}


    dict set props_dict material_models_list $props

    return $props_dict
}



proc Pfem::write::GetDefaultOutputDict { {appid ""} } {
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

    set nodal_results [write::GetResultsList $results_UN OnNodes]

    set problemtype [write::getValue PFEM_DomainType]
    set contact_active False
    if {$problemtype ne "Fluid"} {
        set root [customlib::GetBaseRoot]
        set xp1 "[spdAux::getRoute "PFEM_Bodies"]/blockdata"
        foreach body_node [$root selectNodes $xp1] {
            set contact [get_domnode_attribute [$body_node selectNodes ".//value\[@n='ContactStrategy'\]"] v]
            if {$contact eq "Yes"} { set contact_active True }
        }
        if {$contact_active eq True} {
            lappend nodal_results "CONTACT_FORCE"
            lappend nodal_results "NORMAL"
        }
    }

    if {$problemtype ne "Solid"} {
        if {$contact_active ne True} {
            lappend nodal_results "NORMAL"
        }
        set nodal_flags_results [list]
        lappend nodal_flags_results "FREE_SURFACE" "INLET"
        dict set resultDict nodal_flags_results $nodal_flags_results
    }

    dict set resultDict nodal_results $nodal_results
    dict set resultDict gauss_point_results [write::GetResultsList $results_UN OnElement]

    dict set outputDict "result_file_configuration" $resultDict
    #dict set outputDict "point_data_configuration" [write::GetEmptyList]
    return $outputDict
}

proc Pfem::write::GetMainScriptFilename { } {
    set problemtype [write::getValue PFEM_DomainType]
    return "RunPfem.py"
}

# Functions to use the write attribute system
proc Pfem::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Pfem::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Pfem::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc Pfem::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc Pfem::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc Pfem::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

Pfem::write::Init
