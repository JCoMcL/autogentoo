# what belongs in global makefile:
- choosing the target
- ssh key and password

# What belongs in target-specific makefiles:
- initial setup before a shell
- any incidental setup or starting and stopping a daemon. Or maybe runit should be used for that.
- stages? I thought they would generalize better when I was originally planning but perhaps they don't
# What belongs in target-specific scripts:
- saving (if applicable)
- loading (if applicable)
- running a command
- ssh wrapper
- sending a file
