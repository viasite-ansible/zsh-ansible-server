# hosts/groups completion from https://github.com/zsh-users/zsh-completions/blob/master/src/_ansible-playbook

__as_ll_group_list () {
  # parses the ini hostfile for groups only: [...]
  HOST_FILE=hosts_all

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
    HOST_FILE=hosts_all
    
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
    
    # method that delegates to ansible (slow)
    # _wanted application expl 'hosts' compadd $(command ansible \
    #                                             all --list-hosts\
    #                                             2>/dev/null)
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
            local -a deploy
            deploy=$(find playbooks/deploy -name '*.yml' | sed 's/playbooks\/deploy\///g' | sed 's/\.yml$//g')
            compadd "$@" $(echo "$deploy")
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
            ;;
        roles)
            local -a roles
            roles=$(find playbooks/roles -name '*.yml' | sed 's/playbooks\/roles\///g' | sed 's/\.yml$//g')
            compadd "$@" $(echo "$roles")
            ;;
    esac
}

_ansible_site_complete () {
    _arguments -C \
    "1:first_arg:->sites"

    case "$state" in
        sites)
            local -a sites
            sites=$(find vars/sites/hosts -name '*.yml' | sed 's/vars\/sites\/hosts\///g' | sed 's/\.yml$//g')
            #_multi_parts / sites
            compadd "$@" $(echo "$sites")
            ;;
    esac
}

compdef _ansible_deploy_complete ansible-deploy
compdef _ansible_role_complete ansible-role
compdef _ansible_site_complete ansible-site
