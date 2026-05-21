namespace eval MPM::xml {
    namespace path ::MPM
    Kratos::AddNamespace [namespace current]

}

proc MPM::xml::Init { } {
    # Namespace variables inicialization
    Model::InitVariables dir $::MPM::dir

    # Import our elements
    Model::ForgetElements
    Model::getElements Elements.xml

    Model::ForgetSolutionStrategies
    Model::getSolutionStrategies Strategies.xml

    # Modify the schemes so more elements are filtered
    foreach strategy $::Model::SolutionStrategies {
        $strategy setAttribute NeedElements false
        foreach scheme [$strategy getSchemes] {
            $scheme addElementFilter ImplementedInApplication MPMApplication
        }
    }

    # Add some parameters
    set implicit_solution_strategy [Model::GetSolutionStrategy implicit]

    # Import our Constitutive Laws
    Model::ForgetConstitutiveLaws
    Model::getConstitutiveLaws ConstitutiveLaws.xml


    # Import our Materials
    Model::ForgetMaterials
    Model::getMaterials Materials.xml

    # Import our Nodal conditions
    Model::getProcesses Processes.xml
    Model::ForgetNodalConditions
    Model::getNodalConditions NodalConditions.xml

    # Import our conditions
    Model::ForgetConditions
    Model::getConditions Conditions.xml

}

proc ::MPM::xml::ProcGetSolutionStrategiesMPM { domNode args } {
    set names ""
    set pnames ""
    set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute STSoluType]] v]
    set Sols [::Model::GetSolutionStrategies [list "SolutionType" $solutionType] ]
    set ids [list ]
    foreach ss $Sols {
        lappend ids [$ss getName]
        append names [$ss getName] ","
        append pnames [$ss getName] "," [$ss getPublicName] ","
    }
    set names [string range $names 0 end-1]
    set pnames [string range $pnames 0 end-1]

    $domNode setAttribute values $names
    set dv [lindex $ids 0]
    if {[$domNode getAttribute v] eq ""} {$domNode setAttribute v $dv}
    if {[$domNode getAttribute v] ni $ids} {$domNode setAttribute v $dv}
    #spdAux::RequestRefresh
    return $pnames
}


proc ::MPM::xml::ProcCheckNodalConditionStateMPM {domNode args} {
    return [MPM::xml::CheckNodalConditionStateById [$domNode @n] $domNode]
}

proc MPM::xml::CheckNodalConditionStateById {conditionId domNode} {
    set parts_un STParts
    if {[spdAux::getRoute $parts_un] ne ""} {
        set condition [Model::getNodalConditionbyId $conditionId]
        set cnd_dim [$condition getAttribute WorkingSpaceDimension]
        if {$cnd_dim ne "" && $cnd_dim ne $Model::SpatialDimension} {
            return "hidden"
        }
        set elems [$domNode selectNodes "[spdAux::getRoute $parts_un]/condition/group/value\[@n='Element'\]"]
        set elemnames [list]
        foreach elem $elems {
            lappend elemnames [$elem @v]
        }
        set elemnames [lsort -unique $elemnames]

        set solutionType [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute STSoluType]] v]
        set params [list analysis_type $solutionType]
        if {[::Model::CheckElementsNodalCondition $conditionId $elemnames $params]} {
            return "normal"
        }
        return "hidden"
    }
    return "normal"
}

proc MPM::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
     spdAux::parseRoutes
     spdAux::ConvertAllUniqueNames ST MPM
   }
}

proc MPM::xml::getUniqueName {name} {
    return MPM${name}
}

proc MPM::xml::CustomTree { args } {

#     spdAux::SetValueOnTreeItem v "time" Results OutputControlType
#     spdAux::SetValueOnTreeItem values "time" Results OutputControlType
    spdAux::SetValueOnTreeItem v No NodalResults PARTITION_INDEX
    spdAux::SetValueOnTreeItem v No NodalResults REACTION
    spdAux::SetValueOnTreeItem state {[CheckNodalConditionOutputStateMPM DISPLACEMENT]} NodalResults REACTION
    if {[MPM::xml::UsesMixedUPElements]} {
        spdAux::SetValueOnTreeItem v Yes NodalResults PRESSURE
    } else {
        spdAux::SetValueOnTreeItem v No NodalResults PRESSURE
    }
    spdAux::SetValueOnTreeItem state {[CheckNodalConditionOutputStateMPM DISPLACEMENT]} NodalResults PRESSURE
    spdAux::SetValueOnTreeItem v "LinearSolversApplication.sparse_lu" MPMimplicitlinear_solver_settings Solver
}


proc MPM::xml::ProcCheckGeometry {domNode args} {
    set ret "surface"
    if {$::Model::SpatialDimension eq "3D"} {
        set ret "volume"
    }
    return $ret
}

proc MPM::xml::ProcCheckActivateStabilizationState {domNode args} {
    set ret "hidden"
    set up_mixed MPMUpdatedLagrangianUP$::Model::SpatialDimension
    set used_elements [::MPM::write::GetUsedElements Name]
    if {$up_mixed in $used_elements} {
        set ret "normal"
    }
    return $ret
}

proc MPM::xml::ProcCheckStabilizationState {domNode args} {
    set ret "hidden"
    set first_check [MPM::xml::ProcCheckActivateStabilizationState domNode args]
    if {$first_check eq "normal"} {
        set second_check [write::getValueByNode [$domNode selectNodes "..//value\[@n='ActivateStabilization']"] ]
        if {$second_check eq "On"} {set ret "normal"}
    }
    return $ret
}

proc MPM::xml::ProcCheckGridTrackingPressureState {domNode args} {
    set tracking_state [write::getValue GridTracking ActivateTrackingGrid]
    if {$tracking_state ne "On"} {
        return "hidden"
    }

    set used_elements [::MPM::write::GetUsedElements Name]
    foreach up_mixed [list MPMUpdatedLagrangianUP2D MPMUpdatedLagrangianUP3D] {
        if {$up_mixed in $used_elements} {
            return "normal"
        }
    }
    return "hidden"
}

proc MPM::xml::ProcCheckMPTrackingPressureState {domNode args} {
    set tracking_state [write::getValue MPTracking ActivateTracking]
    if {$tracking_state ne "On"} {
        return "hidden"
    }

    set used_elements [::MPM::write::GetUsedElements Name]
    foreach up_mixed [list MPMUpdatedLagrangianUP2D MPMUpdatedLagrangianUP3D] {
        if {$up_mixed in $used_elements} {
            return "normal"
        }
    }
    return "hidden"
}

proc MPM::xml::UsesMixedUPElements { } {
    foreach elem [::MPM::write::GetUsedElements Name] {
        if {$elem in [list MPMUpdatedLagrangianUP2D MPMUpdatedLagrangianUP3D]} {
            return 1
        }
    }
    return 0
}

proc MPM::xml::ProcCheckNodalConditionOutputState {domNode args} {
    set conditionId [lindex $args 0]
    set outputId [$domNode @n]

    if {![::Model::CheckNodalConditionOutputState $conditionId $outputId]} {
        return "hidden"
    }

    if {$outputId eq "PRESSURE"} {
        if {[MPM::xml::UsesMixedUPElements]} {
            $domNode setAttribute v Yes
            return "normal"
        }
        return "hidden"
    }

    if {$outputId eq "REACTION"} {
        $domNode setAttribute v No
    }

    return [MPM::xml::CheckNodalConditionStateById $conditionId $domNode]
}

proc MPM::xml::ProcElementOutputState {domNode args} {
    set outputId [$domNode @n]
    if {$outputId eq "MP_PRESSURE"} {
        if {[MPM::xml::UsesMixedUPElements]} {
            $domNode setAttribute v Yes
            return "normal"
        }
        return "hidden"
    }

    return [spdAux::ProcElementOutputState $domNode $args]
}
