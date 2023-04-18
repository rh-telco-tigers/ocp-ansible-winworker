# ocp-ansible-winworker
ansible scripts to maintain Windows worker nodes used by the Windows MachineConfig Operator


First step/task is to be able to take a vmware template convert to vm, patch it and then convert back to template. 
Need to see if we need to sysprep each time or not.

## Using the script

1. edit the `vars/vars.yml` file with your information
2. run `ansible-playbook update_template.yml -e "tempalte_name=<template_name>" -vvvv`