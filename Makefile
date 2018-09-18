# import deploy config
# You can change the default deploy config with `make dpl="deploy_special.env" release`
dpl ?= deploy.env
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

# grep the version from the mix file
VERSION=$(shell ./version.sh)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


# DOCKER TASKS
# Build the container
image: ## Build the image using cache
	docker build -t $(APP_NAME) $(BUILD_ARGS) .

build-nc: ## Build the image without caching
	docker build --no-cache -t $(APP_NAME) $(BUILD_ARGS) .

shell: image ## run a shell in a new container created from image
	docker run -a stdin -a stdout -i -t --entrypoint=/bin/sh $(APP_NAME)	

release: build-nc publish ## Make a release by building and publishing the `{version}` and `latest` tagged containers to repository

# Docker publish
publish: publish-latest publish-version ## Publish the `{version}` ans `latest` tagged containers to repository

publish-latest: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):latest

publish-version: tag-version ## Publish the `{version}` taged container to ECR
	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

tag-latest: ## Generate container `{version}` tag
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

tag-version: ## Generate container `latest` tag
	@echo 'create tag $(VERSION)'
	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

version: ## Output the current version
	@echo $(VERSION)

test: image ## run a test container with the image
	docker run -i -t -v $(pwd)/test/index.php:/app/html/index.php -p 10080:80 $(APP_NAME):latest

##------------- old
#shell: image
#	docker run -a stdin -a stdout -i -t --entrypoint=/bin/sh $(TEMPLATE_NAME)
#
#image:
#	docker build -t $(TEMPLATE_NAME) .
#
#stop:
#	docker ps | grep $(TEMPLATE_NAME) | cut -f1 -d' ' | xargs docker stop
#
#container: image
#	docker docker create --name $(CONTANER_NAME)  $(TEMPLATE_NAME):latest
