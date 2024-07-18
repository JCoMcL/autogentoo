# Autogentoo

A system for automating the installation of a highly configured operating system on all sorts of targets. This project is best described with the following diagram

![](diagram.drawio.svg)

The goal of this project is essentially to traverse this graph as effectively as possible, with a secondary goal being to practice and compare all the various technologies that try to solve pieces of this puzzle and to learn their strengths and weaknesses.

Currently we're passed the milestone of a full top-to-bottom traversal of the graph in its most basic form, starting with QEMU. Now the main focus is refactoring to accomodate multiple use cases. Other items on the docket include redoing the Ansible section, pursuing other IaC solutions, and developing custom solutions in places where some of the problems still aren't solved.

1. Formatting a disk without explicit instuctions from the user is not easy but I believe it's solvable in enough cases that it's worth pursuing. This is the most important step of almost any operating system install, so making it go away could be hugely valuable.
2. Extracting an archive file onto a remote machine is surprisingly not among Rsync's many features. A tool that could do this and also its inverse (creating an archive on a remote machine) would be very useful if it doesn't already exist.
3. In the long term, I think a system that leverages and builds upon Gentoo's own configuration management systems would do a better job at creating a living configuration that can stay up to date on all installations of all types.

# Tech

## QEMU

A Virtual Machine implementation. Surprisingly easy to set up, and the extra bits of software that supposedly make it more user friendly have (for my purposes) only solved problems I didn't have and made problems I didn't care to solve. It supports save-states, it can run in headed or headless mode and almost everything it does can be easily automated, though I needed an additional script to make `sendkey` actually useful.

## Make

A dead simple and really nice build system. Make is essentially shell script plus a dependency resolution algorithm, which is all that shell script was missing in order to be a great build system. At large scales it tends to over-rely on a huge number of variables. I would say I have a very firm understanding of Make at this point.

## Ansible

A configuration management system (though that may not be the exact jargon) that is built for scale by default and does a very respectable job of providing useful abstractions over the nuances and differences of various systems. I wish NixOS was more like this. It uses YAML, which sucks. The thing about YAML is, if you have a system that is programmed with YAML ~~you have be **extra** careful to ensure that~~ it is declarative and stateless. Programming in YAML is sort of like using a normal programming language except where the differences between parentheses(), brackets[], and braces{}, are mostly arbitrary, and also you can only have 2-3 symbols per line. It really sucks and it's a huge obstacle to learning. You can do an awful lot with just `ansible.builtin.script` though, and that's mostly what I've stuck to so far.

