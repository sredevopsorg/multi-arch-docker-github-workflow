# Simple Dockerfile to demonstrate the use of the `uname` command.
# This Dockerfile is based on the latest Alpine Linux image.
# The `uname` command is used to display system information.
FROM alpine:latest
# Set the default command to run when the container starts
# This command will echo the system information using `uname -a`, a hello world message, and the current date and time to stdout, then exit cleanly.
CMD ["sh", "-c", "uname -a; echo 'Hello, World!'; date"]
# The `uname -a` command prints all system information, including the kernel name, version, and architecture.
