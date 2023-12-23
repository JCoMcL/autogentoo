# Autogentoo

Build a fully customized Linux distribution with the bare minimum effort, and install or run it on almost anything.
The goal of this project is to address some of the disappointments I've had with Arch Linux and, later, NixOS, and to learn a wide variety of Dev-Ops and Sys-Admin tech in the process.
This document is for my own reference. Features described below are mostly TODOs

# Use Cases

1. Build AG distro on VM from scratch
   
   - A VM can boot an ISO image, which can prove reproducibility, and helps keep things from being messy.
   - A VM lets me use save states. Saves time during the development process, but of little use to an end user
   - Once the AG distro is built, the VM will hopefully no longer be necessary

2. install on disk

   2.1. Portable, bootable, AG distro and installation medium
   
   - can by flashed or dd'ed into a flash drive
   - broad support
   - able to perform an autogentoo installation without an internet connection
   - can boot in autoinstall mode, allowing completely unattended installation
     - play a tune using pcspkr when complete

4. Install over ssh

I guess that's it?

# Tech

## QEMU

A Virtual Machine implementation. Surprisingly easy to set up, and the extra bits of software that supposedly make it more user friendly have (for my purposes) only solved problems I didn't have and made problems I didn't care to solve. It supports save-states, it can run in headed or headless mode and almost everything it does can be easily automated, though I needed an additional script `sendkey` actually useful. I've found some instances of sub-par performance, and believe that containerization would perform much better than virtualization for a disk-intensive workload like this.

## Make

A dead simple and really nice build system. Make is essentially shell script plus a dependency resolution algorithm, which is all that shell script was missing in order to be a great build system. At large scales it tends to over-rely on a huge number of variables. I would say I have a very firm understanding of Make at this point.

## Ansible

A configuration management system (though that may not be the exact jargon) that is built for scale by default and does a very respectable job of providing useful abstractions over the nuances and differences of various systems. I wish NixOS was more like this. It uses YAML, which sucks. The thing about YAML is, if you have a system that is programmed with YAML ~~you have be **extra** careful to ensure that~~ it is declarative and stateless. Programming in YAML is sort of like using a normal programming language except where the differences between parentheses(), brackets[], and braces{}, are mostly arbitrary, and also you can only have 2-3 symbols per line. It really sucks and it's a huge obstacle to learning. You can do an awful lot with just `ansible.builtin.script` though, and that's mostly what I've stuck to so far.

## Puppet
