# ocp-ansible-winworker
ansible scripts to maintain Windows worker nodes used by the Windows MachineConfig Operator


First step/task is to be able to take a vmware template convert to vm, patch it and then convert back to template. 
Need to see if we need to sysprep each time or not.

## Windows Configuration for winrm

On the template you need to have:

```powershell
winrm quickconfig
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
# Add a new firewall rule
port=5986
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=$port
```

## Windows Configuration for ssh

You can also use ssh (it would appear?)

## Using the script

1. `cp vars/var.yml.example vars/var.yml`
2. edit the `vars/vars.yml` file with your information
3. run `ansible-playbook update_template.yml -e "tempalte_name=<template_name>" -vvvv`