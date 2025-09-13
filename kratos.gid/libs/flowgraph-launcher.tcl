#########################################################
################### Javi Garate #########################
###################### CIMNE ############################
#########################################################

# if namespace exists, destroy it
if {[namespace exists ::Flowgraph]} {
    namespace delete ::Flowgraph
}
namespace eval Flowgraph {
    Kratos::AddNamespace [namespace current]

    variable docker_image
    variable flowgraph_internal_port
    set flowgraph_internal_port 8182
    variable flowgraph_external_port
    set flowgraph_external_port 8182

    variable mode

}

proc Flowgraph::Init { } {
    variable docker_image
    set docker_image "flowgraph"

    variable mode
    set mode [Kratos::ManagePreferences GetValue flowgraph_mode]
    if {$mode eq ""} {
        set mode "local"
        Kratos::ManagePreferences SetValue flowgraph_mode $mode
    }
    # W "Flowgraph launcher initialized for image: $docker_image"
}


proc Flowgraph::LaunchFlowgraph {} {
    variable mode
    set mode [Kratos::ManagePreferences GetValue flowgraph_mode]

    variable flowgraph_external_port
    set flowgraph_external_port [Kratos::ManagePreferences GetValue flowgraph_external_port]

    if {$mode eq "docker"} {
        Flowgraph::LaunchFlowgraphDocker
    } else {
        Flowgraph::LaunchFlowgraphLocal
    }
    
}


####################################################
################ PRIVATE METHODS ###################
####################################################


proc Flowgraph::LaunchFlowgraphLocal {} {
    variable flowgraph_external_port
    
    VisitWeb "http://localhost:$flowgraph_external_port"
}

proc Flowgraph::LaunchFlowgraphDocker {} {
    variable docker_image
    variable flowgraph_internal_port

    set modelname [GiD_Info Project ModelName]
    if {$modelname eq "UNNAMED"} {
        W "Please save the model before launching Flowgraph"
        return ""
    }
    set modelname $modelname.gid
    set status [Flowgraph::IsFlowgraphEnabled]
    switch $status {
        -2 {
            W "Docker is not installed. Please install Docker from https://www.docker.com/get-started"
        }
        -1 {
            W "Docker is not available. Make sure Docker is running."
        }
        0 {
            W "Flowgraph is already running. Stop the current instance to start a new one."
            W "You can do it by executing in a console: docker rm -f \$(docker ps -q --filter 'ancestor=$docker_image')"
            W "Or copy-paste this command in the GiD Terminal:"
            W "-np- Flowgraph::KillContainer"
        }
        default {
            W "Starting Flowgraph... We are going to execute `docker run --rm -p $flowgraph_external_port:$flowgraph_internal_port -v $modelname:/model $docker_image`"
            # Code to start Flowgraph
            W "Starting..."
            Kratos::StartContainerForImage $docker_image $flowgraph_external_port $flowgraph_internal_port $modelname
            # exec docker run --rm -p $flowgraph_external_port:$flowgraph_internal_port -v $modelname:/model $docker_image &
            W "Flowgraph started. Open your browser and go to http://localhost:$flowgraph_external_port"
            VisitWeb "http://localhost:$flowgraph_external_port"
            W "To stop Flowgraph, copy-paste this command in the GiD Terminal:"
            W "-np- Flowgraph::KillContainer"

        }
    }
}

# Will return -2 if docker is not installed
# Will return -1 if docker is not available
# Will return 1 if docker is available and no instance of flowgraph is running
# Will return 0 if docker is available and an instance of flowgraph is running

proc Flowgraph::IsFlowgraphEnabled {} {
    variable docker_image
    set docker_status [Kratos::IsDockerAvailable]
        
    W "Docker status: $docker_status"

    if {$docker_status == -1} {
        return -1
    } else {

        set running [::Kratos::IsDockerContainerRunningForImage $docker_image]
        W "Docker image $docker_image is available: running=$running"
        if {$running} {
            return 0
        } else {
            return 1
        }
    }
}

proc Flowgraph::KillContainer {} {
    variable docker_image
    variable flowgraph_external_port
    W "Stopping all running instances of $docker_image ..."
    Kratos::KillAllContainersForImage $docker_image $flowgraph_external_port
}

Flowgraph::Init

# print the list of methods od the namespace
# W [namespace children Flowgraph]

# -np- source {C:\Users\jgarate\Desktop\CODE\Other\GiDInterface\kratos.gid\libs\flowgraph-launcher.tcl}