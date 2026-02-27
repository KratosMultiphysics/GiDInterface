proc MPM::write::WriteBodyMDPA { } {
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Nodal coordinates
    ::write::writeNodalCoordinatesOnGroups [MPM::write::GetPartsGroupsNames Body]

    # Body element connectivities
    ::write::writeGeometryConnectivities [MPM::write::GetPartsGroups body] 

    # Write Submodelparts
    writeSubmodelparts particles
}

proc MPM::write::writeConditionsSubmodelparts { } {
    foreach group [MPM::write::GetConditionsGroups] {
        write::writeGroupSubModelPartAsGeometry $group
    }
}

