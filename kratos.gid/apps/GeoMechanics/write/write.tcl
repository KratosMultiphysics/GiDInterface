namespace eval ::GeoMechanics::write {
    namespace path ::GeoMechanics
    Kratos::AddNamespace [namespace current]

    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    variable writeAttributes
    variable ContactsDict

    variable mdpa_list 
}

proc ::GeoMechanics::write::Init { } {
    variable ConditionsDictGroupIterators
    variable NodalConditionsGroup
    set ConditionsDictGroupIterators [dict create]
    set NodalConditionsGroup [list ]

    variable ContactsDict
    set ContactsDict [dict create]

    variable writeAttributes
    set writeAttributes [dict create]

    variable mdpa_list 
    set mdpa_list [list ]
    
    SetAttribute validApps [list "GeoMechanics"]
    SetAttribute writeCoordinatesByGroups [::GeoMechanics::GetWriteProperty coordinates]
    SetAttribute properties_location [::GeoMechanics::GetWriteProperty properties_location]

    SetAttribute parts_un [::GeoMechanics::GetUniqueName parts]
    SetAttribute time_parameters_un [::GeoMechanics::GetUniqueName time_parameters]
    SetAttribute results_un [::GeoMechanics::GetUniqueName results]
    SetAttribute materials_un [::GeoMechanics::GetUniqueName materials]
    SetAttribute initial_conditions_un [::GeoMechanics::GetUniqueName initial_conditions]
    SetAttribute nodal_conditions_un [::GeoMechanics::GetUniqueName nodal_conditions]
    SetAttribute conditions_un [::GeoMechanics::GetUniqueName conditions]

    SetAttribute nodal_conditions_no_submodelpart [list CONDENSED_DOF_LIST CONDENSED_DOF_LIST_2D CONTACT CONTACT_SLAVE]
    SetAttribute materials_file [::GeoMechanics::GetWriteProperty materials_file]
    SetAttribute main_launch_file [::GeoMechanics::GetAttribute main_launch_file]
    SetAttribute model_part_name [::GeoMechanics::GetWriteProperty model_part_name]
    SetAttribute output_model_part_name [::GeoMechanics::GetWriteProperty output_model_part_name]

    # multistage_write_mdpa_file_mode can be single_file or multiple_files
    SetAttribute multistage_write_mdpa_file_mode [::GeoMechanics::GetWriteProperty multistage_write_mdpa_file_mode]
    SetAttribute multistage_write_json_mode [::GeoMechanics::GetWriteProperty multistage_write_json_mode]

    # mdpa mode can be geometries or elements
    SetAttribute write_mdpa_mode geometries
}

proc ::GeoMechanics::write::writeModelPartEvent { } {

    variable mdpa_list 
    set mdpa_list [list ]

    ::Structural::write::Init
    write::initWriteConfiguration [GetAttributes]

    if { [GetAttribute write_mdpa_mode] == "geometries" } {  
        write::writeModelPartFileAsGeometries
    } else {
        write::writeModelPartFileOld
    }
    
}

proc ::GeoMechanics::write::writeModelPartFileAsGeometries { } {
    if { [GetAttribute multistage_write_mdpa_file_mode] == "single_file" } {  

        # Headers
        write::writeModelPartData
        write::WriteString "Begin Properties 0"
        write::WriteString "End Properties"

        write::writeNodalCoordinates

        # Write geometries
        # Get the list of groups in the spd
        set lista [::GeoMechanics::xml::GetListOfSubModelParts]

        # Write the geometries
        set ret [::write::writeGeometryConnectivities $lista]
        
        # Write the submodelparts
        set what "nodal"
        append what "&Geometries"
        
        foreach group $lista {
            ::write::writeGroupSubModelPart "GENERIC" [$group @n] $what
        }

    } else {
        variable mdpa_list 
        write::CloseFile

        set stages [::GeoMechanics::xml::GetStages]
        foreach stage $stages {
            write::OpenFile "[$stage @name].mdpa"
            lappend mdpa_list "[$stage @name].mdpa"

            # Headers
            write::writeModelPartData
            write::WriteString "Begin Properties 0"
            write::WriteString "End Properties"

            write::writeNodalCoordinatesOnParts $stage

            # Element connectivities (Groups on STParts)
            ::GeoMechanics::write::writeElementConnectivities $stage
            
            # Local Axes
            Structural::write::writeLocalAxes

            # Hinges special section
            Structural::write::writeHinges
            
            # # Custom SubmodelParts
            # set basicConds [write::writeBasicSubmodelParts [::Structural::write::getLastConditionId]]
            # set ::Structural::write::ConditionsDictGroupIterators [dict merge $::Structural::write::ConditionsDictGroupIterators $basicConds]

            # SubmodelParts
            write::WriteString "// Stage [$stage @name]"

            # Write Conditions section
            Structural::write::writeConditions $stage
            
            # Custom SubmodelParts
            set basicConds [write::writeBasicSubmodelParts [::Structural::write::getLastConditionId]]
            set ::Structural::write::ConditionsDictGroupIterators [dict merge $::Structural::write::ConditionsDictGroupIterators $basicConds]

            Structural::write::writeMeshes $stage
            write::CloseFile
        }
    }
}


proc ::GeoMechanics::write::writeModelPartFileOld { } {
    if { [GetAttribute multistage_write_mdpa_file_mode] == "single_file" } {  

        # Headers
        write::writeModelPartData
        write::WriteString "Begin Properties 0"
        write::WriteString "End Properties"

        write::writeNodalCoordinates

        # Element connectivities (Groups on STParts)
        ::GeoMechanics::write::writeElementConnectivities
        
        # Local Axes
        Structural::write::writeLocalAxes

        # Hinges special section
        Structural::write::writeHinges
        
        # # Custom SubmodelParts
        # set basicConds [write::writeBasicSubmodelParts [::Structural::write::getLastConditionId]]
        # set ::Structural::write::ConditionsDictGroupIterators [dict merge $::Structural::write::ConditionsDictGroupIterators $basicConds]

        # SubmodelParts
        set stages [::GeoMechanics::xml::GetStages]
        foreach stage $stages {

            write::WriteString "// Stage [$stage @name]"

            # Write Conditions section
            Structural::write::writeConditions $stage
            
            # Custom SubmodelParts
            set basicConds [write::writeBasicSubmodelParts [::Structural::write::getLastConditionId]]
            set ::Structural::write::ConditionsDictGroupIterators [dict merge $::Structural::write::ConditionsDictGroupIterators $basicConds]

            Structural::write::writeMeshes $stage
        }
    } else {
        variable mdpa_list 
        write::CloseFile

        set stages [::GeoMechanics::xml::GetStages]
        foreach stage $stages {
            write::OpenFile "[$stage @name].mdpa"
            lappend mdpa_list "[$stage @name].mdpa"

            # Headers
            write::writeModelPartData
            write::WriteString "Begin Properties 0"
            write::WriteString "End Properties"

            write::writeNodalCoordinatesOnParts $stage

            # Element connectivities (Groups on STParts)
            ::GeoMechanics::write::writeElementConnectivities $stage
            
            # Local Axes
            Structural::write::writeLocalAxes

            # Hinges special section
            Structural::write::writeHinges
            
            # # Custom SubmodelParts
            # set basicConds [write::writeBasicSubmodelParts [::Structural::write::getLastConditionId]]
            # set ::Structural::write::ConditionsDictGroupIterators [dict merge $::Structural::write::ConditionsDictGroupIterators $basicConds]

            # SubmodelParts
            write::WriteString "// Stage [$stage @name]"

            # Write Conditions section
            Structural::write::writeConditions $stage
            
            # Custom SubmodelParts
            set basicConds [write::writeBasicSubmodelParts [::Structural::write::getLastConditionId]]
            set ::Structural::write::ConditionsDictGroupIterators [dict merge $::Structural::write::ConditionsDictGroupIterators $basicConds]

            Structural::write::writeMeshes $stage
            write::CloseFile
        }
    }
}


proc ::GeoMechanics::write::writeElementConnectivities { {stage ""} } {
    set root [customlib::GetBaseRoot]
    set xp1 "//container\[@n = 'Parts'\]/condition/group"
    if { $stage != "" } {
        set root $stage
        set xp1 "./container\[@n = 'Parts'\]/condition/group"
    }
    foreach gNode [$root selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element']"] ]
        write::writeGroupElementConnectivities $gNode $elem
    }
}

proc ::GeoMechanics::write::writeCustomFilesEvent { } {
    ::Structural::write::WriteMaterialsFile

    # TODO: How are we going to handle the parallelism in stages?
    # write::SetParallelismConfiguration
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]

}

proc ::GeoMechanics::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

proc ::GeoMechanics::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::GeoMechanics::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::GeoMechanics::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ::GeoMechanics::write::AddAttribute {att val} {
    variable writeAttributes
    dict append writeAttributes $att $val]
}

proc ::GeoMechanics::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::GeoMechanics::write::AddValidApps {appList} {
    AddAttribute validApps $appList
}

proc ::GeoMechanics::write::ApplyConfiguration { } {
    variable writeAttributes
    write::SetConfigurationAttributes $writeAttributes
}
