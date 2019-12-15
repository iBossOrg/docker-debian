# docker-debian

[![GitHub Actions Status](../../workflows/Build%20and%20Publish%20to%20Docker%20Hub/badge.svg)](../../actions)

Debian base image modified for Docker-friendliness:

* Official [Debian image](https://hub.docker.com/_/debian/) as a base system.
* [Modular Docker entrypoint](https://github.com/ibossorg/docker-entrypoint-overlay).
* `bash` as a shell.
* `ca-certificates` contains common CA certificates.
* `curl` for data transfers using various protocols.
* `opensslssl` for PKI and TLS.
* `nmap-ncat` for bulk data transfers using various protocols.
* `su_exec` for process impersonation.
* `tini` as an init process.
* `tzdata` time zone database.

## Usage

This Docker image is intended to serve as a base for other images.

You can start with this sample `Dockerfile` file:

```Dockerfile
FROM iboss/debian
RUN adduser -D -H -u 1000 MY_USER
#...
COPY rootfs /
CMD ["--OPTION", "VALUE"]
```

and overwrite entrypoint defaults in file `rootfs/entrypoint/10.default-config.sh`, for example:

```bash
DEFAULT_COMMAND="MY_COMMAND"
EXEC_USER="MY_USER"
LOG_FILE="/var/log/docker.log"
ERR_FILE="/var/log/docker.err"
```

## Reporting Issues

Issues can be reported by using [GitHub Issues](/../../issues). Full details on how to report issues can be found in the [Contribution Guidelines](CONTRIBUTING.md).

## Contributing

Clone the GitHub repository into your working directory:

```bash
git clone https://github.com/ibossorg/docker-debian
```

Use the command `make` in the project directory:

```bash
make all                      # Build a new image and run the tests
make ci                       # Build a new image and run the tests
make build                    # Build a new image
make rebuild                  # Build a new image without using the Docker layer caching
make vars                     # Display the make variables
make up                       # Remove the containers and then run them fresh
make create                   # Create the containers
make start                    # Start the containers
make wait                     # Wait for the start of the containers
make ps                       # Display running containers
make logs                     # Display the container logs
make logs-tail                # Follow the container logs
make shell                    # Run the shell in the container
make test                     # Run the tests
make test-shell               # Run the shell in the test container
make restart                  # Restart the containers
make stop                     # Stop the containers
make down                     # Remove the containers
make clean                    # Remove all containers and work files
make docker-pull              # Pull all images from the Docker Registry
make docker-pull-baseimage    # Pull the base image from the Docker Registry
make docker-pull-dependencies # Pull the project image dependencies from the Docker Registry
make docker-pull-image        # Pull the project image from the Docker Registry
make docker-pull-testimage    # Pull the test image from the Docker Registry
make docker-push              # Push the project image into the Docker Registry
```

Please read the [Contribution Guidelines](CONTRIBUTING.md), and ensure you are signing all your commits with [DCO sign-off](CONTRIBUTING.md#developer-certification-of-origin-dco).

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](/../../tags).

## Authors

* [Petr Řehoř](https://github.com/prehor) - Initial work.

See also the list of [contributors](../../contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](LICENSE) file for details.
