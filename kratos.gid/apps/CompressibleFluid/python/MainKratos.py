import sys
import time

import KratosMultiphysics
from KratosMultiphysics.FluidDynamicsApplication.fluid_dynamics_analysis import FluidDynamicsAnalysis


class FluidDynamicsAnalysisWithFlush(FluidDynamicsAnalysis):
    def __init__(self, model, project_parameters, flush_frequency=10.0):
        super().__init__(model, project_parameters)
        self.flush_frequency = flush_frequency
        self.last_flush = time.time()
        sys.stdout.flush()

    def Initialize(self):
        super().Initialize()
        sys.stdout.flush()

    def FinalizeSolutionStep(self):
        super().FinalizeSolutionStep()

        if self.parallel_type == "OpenMP":
            now = time.time()
            if now - self.last_flush > self.flush_frequency:
                sys.stdout.flush()
                self.last_flush = now


def has_constrained_array(params):
    return params.Has("constrained") \
        and params["constrained"].IsArray()


def cleanup_project_parameters(parameters):
    # Unconstraining initial conditions
    initial_processes = parameters["processes"]["initial_conditions_process_list"]
    for process in initial_processes:
        params = process["Parameters"]
        if has_constrained_array(params):
            params["value"][2].SetDouble(0.0)

            for i in range(3):
                params["constrained"][i].SetBool(False)

    # Unconstraining Z-axis in boundary conditions
    boundary_processes = parameters["processes"]["boundary_conditions_process_list"]
    for process in boundary_processes:
        params = process["Parameters"]
        if has_constrained_array(params):
            params["value"][2].SetDouble(0.0)
            params["constrained"][2].SetBool(False)


def print_parameters_final(parameters):
    try:
        with open("ProjectParameters_as_executed.json", "w+") as f:
            f.write(parameters.PrettyPrintJsonString())
    except Exception:
        print("WARINING: Failed to print ProjectParameters_as_executed.json")


if __name__ == "__main__":

    with open("ProjectParameters.json", 'r') as parameter_file:
        parameters = KratosMultiphysics.Parameters(parameter_file.read())

    cleanup_project_parameters(parameters)

    try:
        global_model = KratosMultiphysics.Model()
        simulation = FluidDynamicsAnalysisWithFlush(global_model, parameters)
        simulation.Run()
        # Printing project parameters even if the run failed (to help debug)
        print_parameters_final(parameters)
    except Exception as e:
        print_parameters_final(parameters)
        raise e
    finally:
        print_parameters_final(parameters)
