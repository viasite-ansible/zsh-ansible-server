## Features
- completion for `ansible-deploy` or `adeploy` (playbooks, `--limit`)
- completion for `ansible-role` or `arole` (playbooks, `--limit`)
- completion for `ansible-site` or `asite` (host/site) - expands `se/gr/si` to `server/group/site`
- completion for `sites-foreach` or `aforeach` (group/site) - expands `se/gr` to `server/group` 
- completion for groups and hosts from inventory `hosts_all`



## Install

#### Antigen
```
antigen bundle viasite-ansible/zsh-ansible-server
```

#### oh-my-zsh
```
git clone https://github.com/viasite-ansible/zsh-ansible-server.git ~/.oh-my-zsh/custom/plugins/ansible-server
```
And add `ansible-server` to `plugins` in `.zshrc`.



## Configure
By default you should execute scripts from `ansible-server` root:
```
scripts/ansible-deploy zsh
```

If you want to execute scripts from anywhere, you must define `ANSIBLE_SERVER_PATH` variable:
```
export ANSIBLE_SERVER_PATH="/path/to/ansible-server"
```
