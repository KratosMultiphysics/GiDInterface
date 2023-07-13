import os
import tohil

# To create functions and variables for all tcl available ones
tcl=tohil.import_tcl()


def import_plaxis_procedure(directory):

    tcl.W(f"Importing Plaxi model from: {directory}")

    # Print evertying that is known by the tcl object
    # object_info  = tcl.__dict__
    # for object_function in object_info:
    #     tcl.W(object_function)

    tcl.W("Found files to import")
    for filename in os.listdir(directory):
        file = os.path.join(directory, filename)
        tcl.W(file)

    p1  = tcl.GiD_Geometry("create", "point", "append", "Layer0", "-8.87755","3.26531","0")
    tcl.W(p1)
    p2  = tcl.GiD_Geometry("create", "point", "append", "Layer0", "4.95465","3.44671","0")
    result  = tcl.GiD_Geometry("create", "line", "append", "stline", "Layer0", p1, p2)

    # Force redraw otherwise it triggers much later than end of script
    tcl.GiD_Redraw()

    return "Done importing model"
