##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

# Deprecated methods that have a new signature
# If you are using one of this old methods, change to the new one or die!

# Deprecation date: 9/03/2018
# Estimated deletion version: 5.3.0
proc write::getMeshId {cid group} {
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        W "Deprecated method write::getMeshId\nUse write::getSubModelPartId\n"
    }
    write::getSubModelPartId $cid $group
}

# Deprecation date: 9/03/2018
# Estimated deletion version: 5.3.0
proc write::writeGroupMesh { cid group {what "Elements"} {iniend ""} {tableid_list ""} } {
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        W "Deprecated method write::writeGroupMesh\nUse write::writeGroupSubModelPart\n"
    }
    write::writeGroupSubModelPart $cid $group $what $iniend $tableid_list
}

# Deprecation date: 9/03/2018
# Estimated deletion version: 5.3.0
proc write::writePartMeshes { } {
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        W "Deprecated method write::writePartMeshes\nUse write::writePartSubModelPart\n"
    }
    write::writePartSubModelPart
}

# Deprecation date: 9/03/2018
# Estimated deletion version: 5.3.0
proc write::GetMeshFromCondition { base_UN condition_id } {
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        W "Deprecated method write::GetMeshFromCondition\nUse write::GetSubModelPartFromCondition\n"
    }
    write::GetSubModelPartFromCondition $base_UN $condition_id
}

# Deprecation date: 9/03/2018
# Estimated deletion version: 5.3.0
proc write::getPartsMeshId {} {
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        W "Deprecated method write::getPartsMeshId\nUse write::getPartsSubModelPartId\n"
    }
    write::getPartsSubModelPartId
}

# Deprecation date: 13/03/2018
# Estimated deletion version: 5.3.0
proc spdAux::AddConditionGroupOnXPath {xpath groupid} {
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        W "Deprecated method spdAux::AddConditionGroupOnXPath\nUse customlib::AddConditionGroupOnXPath\n"
    }
    return [customlib::AddConditionGroupOnXPath $xpath $groupid]
}

# Deprecation date: 13/03/2018
# Estimated deletion version: 5.3.0
proc spdAux::AddConditionGroupOnNode {basenode groupid} {
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        W "Deprecated method spdAux::AddConditionGroupOnNode\nUse customlib::AddConditionGroupOnNode\n"
    }
    return [customlib::AddConditionGroupOnNode $basenode $groupid]
}

# Deprecation date: 24/04/2018
# Estimated deletion version: 6.0.0
# proc spdAux::MergeGroups {basenode groupid} {
#     if {$::Kratos::kratos_private(DevMode) eq "dev"} {
#         #W "Deprecated method spdAux::MergeGroups\nUse GidUtils::MergeGroups\n"
#     }
#     return [GidUtils::MergeGroups $basenode $groupid]
# }