# Simple Dockerfile to demonstrate the use of the multiarch on native architecture.
# This Dockerfile is based on the latest Alpine Linux image.
# The `uname` command is used to display system information.
FROM alpine:latest
RUN echo "Building a multiarch image for the latest Alpine Linux version" \
    && echo "This image will run on any architecture supported by Alpine Linux" \
    && echo "The default command will display system information using the `uname` command" \
    && echo "The `uname` command is used to print system information, including the kernel name, version, and architecture"

RUN echo 'System Information:' \
    && uname -a \
    && echo 'Hello, World!' \
    && echo 'Current Date and Time:' \
    && date

# Set the default command to run when the container starts
# This command will echo the system information using `uname -a`, a hello world message, and the current date and time to stdout, then exit cleanly.
CMD ["sh", "-c", "echo 'System Information:' && uname -a && echo 'Hello, World!' && echo 'Current Date and Time:' && date"]
# The `uname -a` command prints all system information, including the kernel name, version, and architecture.
