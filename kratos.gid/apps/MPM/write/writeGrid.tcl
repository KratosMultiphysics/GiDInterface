proc MPM::write::WriteGridMDPA { } {
    # Headers
    ::write::writeModelPartData
    ::write::WriteString "Begin Properties 0"
    ::write::WriteString "End Properties"

    # Nodal coordinates
    set list_of_groups [concat [MPM::write::GetPartsGroupsNames grid] [MPM::write::GetConditionsGroups] [MPM::write::GetNodalConditionsGroups]]
    ::write::writeNodalCoordinatesOnGroups $list_of_groups

    # Grid element connectivities
    ::write::writeGeometryConnectivities [MPM::write::GetPartsGroups grid] 

    # Write conditions
    ::write::writeGeometryConnectivities [::write::GetGroupsAssignedIn [GetAttribute conditions_un]]

    # Write Submodelparts
    writeSubmodelparts grid
}
