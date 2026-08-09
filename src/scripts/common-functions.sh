function sanity_check(){
    container=$1
    id=$(docker inspect $container 2> /dev/null | jq -r '.[0].Id' )
    [[ "$id" == "null"  ]] && return 1 || return 0
}

function wait_to_finish(){
    container=$1
    app=$2
    echo "Waiting for $app to finish in container $container"
    while [ -n "$(docker container top $container | grep $app)" ]; do
        sleep 0.5
    done
}
