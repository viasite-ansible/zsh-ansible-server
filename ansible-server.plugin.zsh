# hosts/groups completion from https://github.com/zsh-users/zsh-completions/blob/master/src/_ansible-playbook

ANSIBLE_SERVER_PATH="${ANSIBLE_SERVER_PATH:-.}"

__as_not_found_msg () {
    echo 'Define $ANSIBLE_SERVER_PATH or use from ansible-server root'
}

__as_ll_group_list () {
    # parses the ini hostfile for groups only: [...]
    HOST_FILE="${ANSIBLE_SERVER_PATH}/hosts_all"
    if [ ! -e "$HOST_FILE" ]; then
        return
    fi

    local -a group_list
    group_list=$(command \
        cat ${HOST_FILE} \
        | awk '$1 ~ /^\[.*\]$/ && !/=/ && !/:vars/ \
          { gsub(/[\[\]]/, "", $1); gsub(/:children/, "", $1) ; print $1 }' \
        | uniq )

    echo ${group_list}
}

__as_host_list ()
{
    # parses the ini hostfile for hosts only
    # but then has to remove all group occurrences
    HOST_FILE="${ANSIBLE_SERVER_PATH}/hosts_all"
    if [ ! -e "$HOST_FILE" ]; then
        return
    fi
    
    # this will also contain groups if they are referenced in other groups
    local -a mixed_host_list
    mixed_host_list=$(command \
        cat ${HOST_FILE} \
        | awk 'NF && $1 !~ /[\[:=]/ { print $1 }' \
        | sort | uniq)
    
    # compute set difference h1 - h2
    local -a h1 h2 host_list
    h1=${mixed_host_list}
    h2=$(__as_ll_group_list)
    host_list=($(command \
        sort <(echo $h1) <(echo $h2) <(echo $h2) \
        | uniq -u \
        | paste -s -d ' ' - )
        )
    
    _wanted application expl 'hosts' compadd ${host_list}
}

__as_group_list ()
{
    gl=($(command echo $(__as_ll_group_list) | paste -s -d ' ' - )) # 'a\nb\nc' -> (a b c)
    _wanted application2 expl 'groups' compadd $gl
}

_ansible_deploy_complete () {
    _arguments -C \
    "1:first_arg:->deploy" \
    "(-l --limit)"{-l,--limit}"[SUBSET further limit selected hosts to an additional pattern]:subset pattern:->pattern"\

    case "$state" in
        pattern)
            _arguments '*:feature:__as_host_list'
            _arguments '*:feature:__as_group_list'
            ;;
        deploy)
            local -a results
            _message -r "$(__as_not_found_msg)"
            local playbooks_path="${ANSIBLE_SERVER_PATH}/playbooks/deploy"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path" -name '*.yml' | sed "s/$playbooks_path_sed//g" | sed 's/\.yml$//g') )
                _values 'results' $results
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_role_complete () {
    _arguments -C \
    "1:first_arg:->roles" \
    "(-l --limit)"{-l,--limit}"[SUBSET further limit selected hosts to an additional pattern]:subset pattern:->pattern"\

    case "$state" in
        pattern)
            _arguments '*:feature:__as_host_list'
            _arguments '*:feature:__as_group_list'
            _message -r "$(__as_not_found_msg)"
            ;;
        roles)
            local -a results
            local playbooks_path="${ANSIBLE_SERVER_PATH}/playbooks/roles"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path" -name '*.yml' | sed "s/$playbooks_path_sed//g" | sed 's/\.yml$//g') )
                _values 'results' $results
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_site_complete () {
    _arguments -C \
    "1:first_arg:->sites"

    case "$state" in
        sites)
            local -a results
            local playbooks_path="${ANSIBLE_SERVER_PATH}/vars/sites/hosts"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path" -name '*.yml' | sed "s/$playbooks_path_sed//g" | sed 's/\.yml$//g') )
                _values 'results' $results
                _multi_parts -i / results
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_sites_foreach_complete () {
    _arguments -C \
    "1:first_arg:->groups"

    case "$state" in
        groups)
            local -a results
            local playbooks_path="${ANSIBLE_SERVER_PATH}/vars/sites/hosts"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path" -type d -mindepth 2 | sed "s/$playbooks_path_sed//g") )
                _values 'results' $results
                _values 'results' all
                _multi_parts -i / results
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

compdef _ansible_deploy_complete ansible-deploy
compdef _ansible_role_complete ansible-role
compdef _ansible_site_complete ansible-site
compdef _ansible_sites_foreach_complete sites-foreach
