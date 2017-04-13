function _ansible_deploy_complete {
    _arguments '1:first_arg:->deploy'
    case "$state" in
        deploy)
            local -a deploy
            deploy=$(find playbooks/deploy -name '*.yml' | sed 's/playbooks\/deploy\///g' | sed 's/\.yml$//g')
            compadd "$@" $(echo "$deploy")
            ;;
    esac
}

function _ansible_role_complete {
    _arguments '1:first_arg:->roles'
    case "$state" in
        roles)
            local -a roles
            roles=$(find playbooks/roles -name '*.yml' | sed 's/playbooks\/roles\///g' | sed 's/\.yml$//g')
            compadd "$@" $(echo "$roles")
            ;;
    esac
}

function _ansible_site_complete {
    _arguments '1:first_arg:->sites'
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
