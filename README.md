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

You can also use ssh, and for our purposes this seems to work better. If you are using SSH and running from the container image, you need to copy your SSH private key into the src directory with the name `private_key.pem` and it will be copied into the container when you build it.

## Using the script

1. `cp vars/var.yml.example vars/var.yml`
2. edit the `vars/vars.yml` file with your information
3. run `podman build -t ocp-ansible-windows .` to build your container
4. run `podman run -it ocp-ansible-windows:latest /bin/bash` to run the container
5. run `ansible-playbook update_template.yml -e "vm_template_name=<template_name>" -vvvv`