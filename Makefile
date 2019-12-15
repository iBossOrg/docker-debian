### BASE_IMAGE #################################################################

BASE_IMAGE_NAME		?= ${DOCKER_NAME}
BASE_IMAGE_TAG		?= ${DOCKER_IMAGE_TAG}-slim

### DOCKER_IMAGE ###############################################################

DOCKER_VENDOR		?= iboss
DOCKER_NAME		?= debian
DOCKER_IMAGE_TAG	?= 10
DOCKER_IMAGE_TAGS	?= buster latest
DOCKER_IMAGE_DESC	?= Debian base image modified for Docker-friendliness
DOCKER_IMAGE_URL	?= https://debian.org

### ENTRYPOINT_OVERLAY #########################################################

ENTRYPOINT_IMAGE_TAG	?= 1.0.0
ENTRYPOINT_IMAGE	?= $(DOCKER_VENDOR)/entrypoint-overlay:$(ENTRYPOINT_IMAGE_TAG)
DOCKER_IMAGE_DEPENDENCIES += $(ENTRYPOINT_IMAGE)
BUILD_VARS		+= ENTRYPOINT_IMAGE

### MAKE_TARGETS ###############################################################

# Build a new image and run the tests
.PHONY: all
all: clean build start wait logs test

# Build a new image, run the tests and clean environment
.PHONY: ci
ci: all
	@$(MAKE) clean

### BUILD_TARGETS ##############################################################

# Build a new image with using the Docker layer caching
.PHONY: build
build: docker-build

# Build a new image without using the Docker layer caching
.PHONY: rebuild
rebuild: docker-rebuild

### EXECUTOR_TARGETS ###########################################################

# Display the make variables
.PHONY: vars
vars: docker-makevars

# Remove the containers and then run them fresh
.PHONY: run up
run up: docker-up

# Create the containers
.PHONY: create
create: docker-create

# Start the containers
.PHONY: start
start: docker-start

# Wait for the start of the containers
.PHONY: wait
wait: docker-wait

# Display running containers
.PHONY: ps
ps: docker-ps

# Display the container logs
.PHONY: logs
logs: docker-logs

# Follow the container logs
.PHONY: logs-tail tail
logs-tail tail: docker-logs-tail

# Run shell in the container
.PHONY: shell sh
shell sh: docker-shell

# Run the tests
.PHONY: test
test: docker-test

# Run the shell in the test container
.PHONY: test-shell tsh
test-shell tsh:
	@$(MAKE) test TEST_CMD=/bin/bash RSPEC_FORMAT=documentation

# Restart the containers
.PHONY: restart
restart: docker-restart

# Stop the containers
.PHONY: stop
stop: docker-stop

# Delete the containers
.PHONY: down rm
down rm: docker-rm

# Delete all containers and work files
.PHONY: clean
clean: docker-clean

### MK_DOCKER_IMAGE ############################################################

PROJECT_DIR		?= $(CURDIR)
MK_DIR			?= $(PROJECT_DIR)/../Mk
include $(MK_DIR)/docker.image.mk

################################################################################
