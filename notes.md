The project has been influenced quite a lot by implementation details of QEMU. Specifically, all the snapshots that I needed to make during development and before I figured out how to use KVM. A more meaningful way to define stages would be around the interfaces that can abstract away the differences, especially if these interfaces are meaninful to a user.
| milestone | artefact |
|-|-|
| SSH | ssh/config |



So if we want to build on a local disk, we can skip the first 4 steps" Linux Machine, Kayboard Acess, SSH Shell, and Passwordless SSH. We can assume to already have those.
That said, it wouldn't hurt to check that we have all that stuff
