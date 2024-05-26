# hosts/groups completion from https://github.com/zsh-users/zsh-completions/blob/master/src/_ansible-playbook

ANSIBLE_SERVER_PATH="${ANSIBLE_SERVER_PATH:-.}"

exclude_regexp="(_examples|_old|_disabled)"

__as_not_found_msg () {
    echo 'Define $ANSIBLE_SERVER_PATH or use from ansible-server root'
}

__as_path () {
    if [ -d "$ANSIBLE_SERVER_PATH/build" ]; then
        echo "$ANSIBLE_SERVER_PATH/build"
    else
        echo "$ANSIBLE_SERVER_PATH"
    fi
}

__as_ll_group_list () {
    # parses the ini hostfile for groups only: [...]
    HOST_FILE="$(__as_path)/hosts_all"
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

__as_asite_tags_list () {
    _values  -s , apache,nginx,php apache cron dns letsencrypt nginx php ssh-keys sync sync_files sync_mysql
}

__as_aproject_tags_list () {
    _values  -s , config,deploy cron dns ssl nginx ssh-keys docker deploy config
}

__as_host_list ()
{
    # parses the ini hostfile for hosts only
    # but then has to remove all group occurrences
    HOST_FILE="$(__as_path)/hosts_all"
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
    
    _wanted application expl 'hosts' _values -s , ${host_list}
}

__as_group_list ()
{
    gl=($(command echo $(__as_ll_group_list) | paste -s -d ' ' - )) # 'a\nb\nc' -> (a b c)
    _wanted application2 expl 'groups' _values -s , $gl
}

# completion of playbooks/hosts/*
_ansible_host_complete () {
    _arguments -C \
    "1:first_arg:->hosts" \
    "--changed[only changed or ANSIBLE_STDOUT_CALLBACK=actionable]" \
    "--check[dry-run]" \

    case "$state" in
        hosts)
            local -a results
            #_message -r "$(__as_not_found_msg)" # always show
            local playbooks_path="$(__as_path)/playbooks/hosts"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path/" -name '*.yml' | sed "s/$playbooks_path_sed//g" | sed 's/\.yml$//g' | sort) )
                _values 'results' $results
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_deploy_complete () {
    _arguments -C \
    "1:first_arg:->deploy" \
    "--limit[limit selected hosts to hosts/groups]:subset pattern:->pattern" \
    "--changed[only changed or ANSIBLE_STDOUT_CALLBACK=actionable]" \
    "--check[dry-run]" \

    case "$state" in
        pattern)
            _arguments '*:feature:__as_host_list'
            _arguments '*:feature:__as_group_list'
            ;;
        deploy)
            local -a results
            _message -r "$(__as_not_found_msg)"
            local playbooks_path="$(__as_path)/playbooks/deploy"
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
    "--limit[limit selected hosts to hosts/groups]:subset pattern:->pattern" \
    "--changed[only changed or ANSIBLE_STDOUT_CALLBACK=actionable]" \
    "--check[dry-run]" \
    "--fast[do not check tags]" \

    case "$state" in
        pattern)
            _arguments '*:feature:__as_host_list'
            _arguments '*:feature:__as_group_list'
            ;;
        roles)
            local -a results
            local playbooks_path="$(__as_path)/playbooks/roles"
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
    "1:first_arg:->sites" \
    "--tags[SUBSET tags to an additional pattern]:subset pattern:->pattern" \
    "--changed[only changed or ANSIBLE_STDOUT_CALLBACK=actionable]" \
    "--check[dry-run]" \
    "--fast[do not check tags]" \
    '--force[force files and mysql or --extra-vars="site_sync_files_force=yes site_sync_mysql_force=yes"]' \
    '--force-files[force files or --extra-vars="site_sync_files_force=yes"]' \
    '--force-mysql[force mysql or --extra-vars="site_sync_mysql_force=yes"]'

    case "$state" in
        pattern)
            _arguments '*:feature:__as_asite_tags_list'
            ;;
        sites)
            local -a results
            local playbooks_path="$(__as_path)/vars/sites/hosts"
            # echo "playbooks_path: $playbooks_path"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path" -name '*.yml' | sed "s/$playbooks_path_sed//g" | sed 's/\.yml$//g') )
                _values 'results' $results
                #_multi_parts -i / results # buggy
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_env_complete () {
    _arguments -C \
    "1:first_arg:->env" \

    case "$state" in
        env)
            local -a results
            local config_path="${HOME}/.ansible-server.yml"
            if [ -e "$config_path" ]; then
                results=( $(cat "$config_path" | yq '.env[].name') )
                _values 'results' $results
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_list_complete () {
    _arguments -C \
    "1:first_arg:->list" \

    case "$state" in
        list)
            local -a results
            results=( host project site )
            _values 'results' $results
            ;;
    esac
}

_ansible_project_complete () {
    _arguments -C \
    "1:first_arg:->projects" \
    "--tags[SUBSET tags to an additional pattern]:subset pattern:->pattern" \
    "--changed[only changed or ANSIBLE_STDOUT_CALLBACK=actionable]" \
    "--check[dry-run]" \
    "--fast[do not check tags]" \

    case "$state" in
        pattern)
            _arguments '*:feature:__as_aproject_tags_list'
            ;;
        projects)
            local -a results
            local playbooks_path="$(__as_path)/vars/projects/hosts"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path" -name '*.yml' | sed "s/$playbooks_path_sed//g" | sed 's/\.yml$//g') )
                #_values  'results' $results
                _multi_parts -i / results # buggy
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_shell_complete () {
    _arguments -C \
        '(-): :->limit' \

    case "$state" in
        (limit)
            _arguments '*:feature:__as_host_list'
            _arguments '*:feature:__as_group_list'
            ;;
    esac
}

_ansible_sites_foreach_complete () {
    _arguments -C \
    "1:first_arg:->groups"

    case "$state" in
        groups)
            local -a results
            local playbooks_path="$(__as_path)/vars/sites/hosts"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path" -mindepth 1 -type d | grep -vE "$exclude_regexp" | sed "s/$playbooks_path_sed//g") )
                _values 'results' $results
                _values 'results' all
                #_multi_parts -i / results # buggy
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_projects_foreach_complete () {
    _arguments -C \
    "1:first_arg:->groups"

    case "$state" in
        groups)
            local -a results
            local playbooks_path="$(__as_path)/vars/projects/hosts"
            if [ -d "$playbooks_path" ]; then
                local playbooks_path_sed="$(echo "$playbooks_path/" | sed 's|\/|\\\/|g')"
                results=( $(find "$playbooks_path" -mindepth 1 -type d | grep -vE "$exclude_regexp" | sed "s/$playbooks_path_sed//g") )
                _values 'results' $results
                _values 'results' all
                #_multi_parts -i / results # buggy
            else
                _message -r "$(__as_not_found_msg)"
            fi
            ;;
    esac
}

_ansible_server_complete () {
    _arguments -C \
        '(-): :->command' \
        '(-)*:: :->option-or-argument'

    case "$state" in
        (command)
            _values 'results' role deploy host site project env link list
            ;;
        (option-or-argument)
            curcontext=${curcontext%:*:*}:ansible-server-$words[1]:
            _ansible_server_subcommand
            ;;
    esac
}

_ansible_server_subcommand () {
    case "$words[1]" in
        (role)
            _ansible_role_complete
            ;;
        (deploy)
            _ansible_deploy_complete
            ;;
        (host)
            _ansible_host_complete
            ;;
        (project)
            _ansible_project_complete
            ;;
        (site)
            _ansible_site_complete
            ;;
        (env)
            _ansible_env_complete
            ;;
        (list)
            _ansible_list_complete
            ;;
    esac
}

compdef _ansible_server_complete ansible-server
compdef _ansible_host_complete ansible-host
compdef _ansible_deploy_complete ansible-deploy
compdef _ansible_role_complete ansible-role
compdef _ansible_site_complete ansible-site
compdef _ansible_project_complete ansible-project
compdef _ansible_env_complete ansible-env
compdef _ansible_list_complete ansible-list
compdef _ansible_shell_complete ansible-shell
compdef _ansible_sites_foreach_complete sites-foreach
compdef _ansible_projects_foreach_complete projects-foreach

alias ahost='ansible-server host'
alias adeploy='ansible-server deploy'
alias arole='ansible-server role'
alias asite='ansible-server site'
alias aproject='ansible-server project'
alias aenv='ansible-server env'
alias alink='ansible-server link'
alias aforeach=sites-foreach
alias asites=sites-foreach
alias aprojects=projects-foreach
alias ashell=ansible-shell
