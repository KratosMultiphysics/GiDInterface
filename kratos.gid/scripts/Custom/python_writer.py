import numpy as np
import tohil
from objarray_numpy_tools import objarray_to_nparray,nparray_to_objarray
from pathlib import Path

#to create functions and variables for all tcl available ones
tcl=tohil.import_tcl()


def my_meshio_write_mesh2(filename):
    # Gets the nodes in the GID Mesh
    info_nodes=tuple(tcl.GiD_Info('mesh','nodes','-array2'))
    node_ids,node_xyzs=info_nodes    
    #tcl.W(node_xyzs)
    
    for element_type in ['line','triangle','quadrilateral','tetrahedra','pyramid','prism','hexahedra']:
        info_elements=tuple(tcl.GiD_Info('mesh','elements',element_type,'-array2'))
        if (len(info_elements)):            
            elements_data=info_elements[0]
            element_type_ret,element_ids_original,connectivities_original,materials=elements_data
            element_ids=objarray_to_nparray(element_ids_original)
            connectivities=objarray_to_nparray(connectivities_original)
            tcl.W(element_type_ret)
            tcl.W(element_ids)

    group_names=tcl.GiD_Groups("list")
    for group_name in group_names:
        group_name=str(group_name)  # convert from tohil.tclobj to Python str
        # get nodes of the group (returns "" when empty, so convert first then check length)
        group_node_ids=objarray_to_nparray(tcl.GiD_EntitiesGroups("get", group_name, "nodes"))
        
        
        # get elements of the group (returns "" when empty, so convert first then check length)
        group_element_ids=objarray_to_nparray(tcl.GiD_EntitiesGroups("get", group_name, "elements"))
        
    return 0

# main
def start(filename):
    return my_meshio_write_mesh2(filename)