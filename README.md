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

## Using the scripts

As of right now these scripts are run and tested from within a Container Image. To build the container image, run the following commands:

1. `cp vars/var.yml.example vars/var.yml`
2. edit the `vars/vars.yml` file with your information
3. `cp ~/.kube/config config` to copy your kubeconfig auth file into the current directory
4. `cp ~/.ssh/<windows private key> .` to copy your private ssh key used for SSH authentication into the current directory
5. run `podman build -t ocp-ansible-windows .` to build your container
6. run `podman run -it ocp-ansible-windows:latest /bin/bash` to run the container

### Upgrading a Windows Template in VMWare

If you are creating Windows Worker nodes from a VMWare Template, you will need to keep that template up to date with current patches. The `update_vm_template.yml` can be used to take a VM template, convert it to a VM, update it, and then convert back to a template.

1. run `podman run -it ocp-ansible-windows:latest /bin/bash` to run the container
2. run `ansible-playbook update_vm_template.yml -e "vm_template_name=<template_name>"`

### Update Scenarios

There are two options for upgrading your Windows Worker Nodes:

* **Update In Place** - With the Update in place option, the script will Cordon and Drain the Windows node, and then run the patching process, applying current Microsoft patches, rebooting and then putting the nodes back in service. If you are using "Bring Your Own Host" instances as nodes. This is the process you will want to use.
* **Replace the Nodes** - If you are using a Cloud Provider that supplies a patched OS image to build from on a monthly basis, you can use the Windows Machine Config Operator to automatically re-create nodes in your cluster. The process targets one node at a time, Cordoning and Draining the node, then deleting the node from the system. For those machines built with the Windows Machine Config Operator, this will delete the node from the hosting platform and then create a new one from the Cloud Platforms base image.

#### Upgrading WIndows Worker Nodes in place

If you want to update your Windows Worker nodes in place, you will want to use the `update_worker_nodes.yml` playbook. This playbook will follow the following flow:

1. Query the cluster for all nodes with _kubernetes.io/os=windows_ set on the node.
2. Take ONE node collected from step one and "Cordon" node to keep new pods from being scheduled on it
3. On that node, "Drain" the node to remove all the workloads from the node
4. Run the Windows patching script against the node
5. Reboot the node
6. Validate there are no more patches to install
7. Un-cordon the node
8. Repeat steps 2-7 on the next node in the list

To run this procedure do the following:

1. run `podman run -it ocp-ansible-windows:latest /bin/bash` to run the container
2. from in the container run `ansible-playbook update_worker_nodes.yml`


#### Upgrading Windows Worker Nodes by replacing them

If you want to replace your Windows Worker nodes, you will want to use the `replace_worker_nodes.yml` playbook. This playbook will follow the following flow:

1. Query the cluster for all nodes with _kubernetes.io/os=windows_ set on the node.
2. Take ONE node collected from step one and "Cordon" node to keep new pods from being scheduled on it
3. On that node, "Drain" the node to remove all the workloads from the node
4. Delete the Machine Object from the cluster
   1. This will trigger the creation of 1 NEW node
5. The script will then wait until the number of availableReplicas on the associated machineSet match the target number of replicas
6. Repeat steps 2-7 on the next node in the list

To run this procedure do the following:

1. run `podman run -it ocp-ansible-windows:latest /bin/bash` to run the container
2. from in the container run `ansible-playbook replace_worker_nodes.yml`
   
## Validating Windows Release

You can validate which Windows nodes have been updated and which have not based on the information that is available from `oc describe node`

Specifically, the SystemInfo section.

```
System Info:
  Machine ID:                 win22-wk-qmp9b
  System UUID:                BB980642-88C2-83C1-6F45-17D8E65777A5
  Boot ID:                    9
  Kernel Version:             10.0.20348.1668
  OS Image:                   Windows Server 2022 Standard
  Operating System:           windows
  Architecture:               amd64
  Container Runtime Version:  containerd://1.19
  Kubelet Version:            v1.25.0-2653+a34b9e9499e6c3
  Kube-Proxy Version:         v1.25.0-2653+a34b9e9499e6c3
```

Note the Kernel version. This can be used to find the current build of Windows and can be compared against the following web page:

* [Windows Server 2022 Update History](https://support.microsoft.com/en-gb/topic/windows-server-2022-update-history-e1caa597-00c5-4ab9-9f3e-8212fe80b2ee)
* [Windows Server 2019 Update History](https://support.microsoft.com/en-us/topic/windows-10-and-windows-server-2019-update-history-725fc2e1-4443-6831-a5ca-51ff5cbcb059)

For example, in the above output, the Kernel Version is *10.0.20348.1688* which shows as "April 11, 2023" on the Windows Server 2022 Update History page. This gives you an idea of which monthly patch release your worker nodes are up to.