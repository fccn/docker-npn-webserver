# INSTALL
# - copy the files deploy.env, config.env, version.sh and Makefile to your repo
# - replace the vars in deploy.env
# - define the version script

# Build the container
make build

# Build and publish the container
make release

# Publish a container to local repo.
# This includes the login to the repo
make publish

# Build the container with differnt deploy file
make dpl=another_deploy.env build
