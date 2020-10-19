import KratosMultiphysics
import KratosMultiphysics.DelaunayMeshingApplication
import KratosMultiphysics.PfemFluidDynamicsApplication

from KratosMultiphysics.PfemFluidDynamicsApplication.pfem_fluid_dynamics_analysis import PfemFluidDynamicsAnalysis

if __name__ == "__main__":

  with open("ProjectParameters.json",'r') as parameter_file:
    parameters = KratosMultiphysics.Parameters(parameter_file.read())

  model = KratosMultiphysics.Model()

  simulation = PfemFluidDynamicsAnalysis(model,parameters)

  simulation.Run()
