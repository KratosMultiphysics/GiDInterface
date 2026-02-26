proc MPM::write::WriteBodyMDPA { } {
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Nodal coordinates
    writeBodyNodalCoordinates

    # Body element connectivities
    writeBodyElementConnectivities

    # Write Submodelparts
    writeSubmodelparts particles
}