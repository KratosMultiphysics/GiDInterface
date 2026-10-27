# Project Parameters
proc ::FluidBiomedical::write::getParametersDict { } {
    set projectParametersDict [dict create]

    ::write::SetConfigurationAttribute model_part_name [::FluidBiomedical::write::GetModelPartName]

    # # Analysis stage field
    dict set projectParametersDict analysis_stage "KratosMultiphysics.FluidBiomedicalApplication.free_surface_analysis"

    # # problem data
    dict set projectParametersDict problem_data [::Fluid::write::GetProblemData_Dict]

    # # output configuration
    ::write::SetConfigurationAttribute output_model_part_name [::FluidBiomedical::GetWriteProperty output_model_part_name]
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict [::Fluid::GetAttribute id]]

    # # restart options
    #dict set projectParametersDict restart_options [Fluid::write::GetRestart_Dict]

    # # solver settings
    dict set projectParametersDict solver_settings [FluidBiomedical::write::getSolverSettingsDict]

    # # processes
    dict set projectParametersDict processes [::Fluid::write::GetProcesses_Dict]

    set projectParametersDict [::write::GetModelersDict $projectParametersDict]

    set projectParametersDict [::FluidBiomedical::write::ReplaceConditionsName $projectParametersDict "WallCondition2D2N" "LineCondition2D2N"]
    set projectParametersDict [::FluidBiomedical::write::ReplaceConditionsName $projectParametersDict "WallCondition3D3N" "LineCondition3D3N"]

    return $projectParametersDict
}

proc ::FluidBiomedical::write::getSolverSettingsDict { } {
    set solverSettingsDict [dict create]
    # model_part_name
    dict set solverSettingsDict model_part_name [::FluidBiomedical::write::GetModelPartName]

    # domain_size
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solverSettingsDict domain_size $nDim

    # solver_type
    set currentStrategyId [write::getValue FLSolStrat "" force]
    set strategy [::Model::GetSolutionStrategy $currentStrategyId]
    set strategy_write_name [$strategy getAttribute "ImplementedInPythonFile"]
    set strategy_type [$strategy getAttribute "Type"]
    dict set solverSettingsDict solver_type $strategy_write_name

    # model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    set model_name [Fluid::write::getFluidModelPartFilename]
    dict set modelDict input_filename $model_name
    dict set solverSettingsDict model_import_settings $modelDict

    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict FLSolStrat FLScheme FLStratParams] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Fluid] ]

    return $solverSettingsDict
}

proc ::FluidBiomedical::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

proc ::FluidBiomedical::write::ReplaceConditionsName { projectParametersDict old_cond_name new_cond_name } {

    # in the section 'modelers' we have this structure
    # [
        # {
            # "name": "Modelers.KratosMultiphysics.ImportMDPAModeler",
            # "parameters": {
                # "input_filename": "free",
                # "model_part_name": "free"
            # }
        # },
        # {
            # "name": "Modelers.KratosMultiphysics.CreateEntitiesFromGeometriesModeler",
            # "parameters": {
                # "elements_list": [
                    # {
                        # "model_part_name": "free.Fluid",
                        # "element_name": "Element2D3N"
                    # }
                # ],
                # "conditions_list": [
                    # {
                        # "model_part_name": "free.Outlet",
                        # "condition_name": "WallCondition2D2N"
                    # },
                    # {
                        # "model_part_name": "free._HIDDEN_Slip2D",
                        # "condition_name": "WallCondition2D2N"
                    # }
                # ]
            # }
        # }
    # ]
    # we need to replace all the occurrences of old_cond_name with new_cond_name

    set modelers [dict get $projectParametersDict modelers]
    set modelers_new [list]
    foreach modeler $modelers {
        set modeler_new [dict create]
        dict set modeler_new name [dict get $modeler name]
        set parameters [dict get $modeler parameters]
        set parameters_new [dict create]
        foreach {key value} $parameters {
            if { $key == "conditions_list" } {
                set conditions_list_new [list]
                foreach {condition} $value {
                    set condition_new [dict create]
                    dict set condition_new model_part_name [dict get $condition model_part_name]
                    dict set condition_new condition_name [expr {[dict get $condition condition_name] == $old_cond_name ? $new_cond_name : [dict get $condition condition_name]}]
                    lappend conditions_list_new $condition_new
                }
                dict set parameters_new $key $conditions_list_new
            } else {
                dict set parameters_new $key $value
            }
        }
        dict set modeler_new parameters $parameters_new
        lappend modelers_new $modeler_new
    }
    dict set projectParametersDict modelers $modelers_new

    return $projectParametersDict
}