## Features
- completion for `ansible-deploy` (playbooks, `--limit`)
- completion for `ansible-role` (playbooks, `--limit`)
- completion for `ansible-site` (host/site)
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
