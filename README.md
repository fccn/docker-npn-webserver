# Docker image for a generic Nginx-PHP-NodeJS web application server

[![Build Status](https://dev.azure.com/pcosta-fccn/Docker%20base%20images/_apis/build/status/fccn.docker-npn-webserver)](https://dev.azure.com/pcosta-fccn/Docker%20base%20images/_build/latest?definitionId=2)

A set of docker images to use for PHP web applications with NGINX and NodeJS.

- npn_webserver - Nginx-PHP-Nodejs webserver with a set of tools and configurations for production grade PHP and NodeJS web applications
- npn_webserver-dev - Nginx-PHP-Nodejs webserver with a set of tools and configurations for development and testing of PHP and NodeJS web applications

The following libraries are used:
- NPM 6.4.1
- NodeJs v10.15.3
- PHP 7.3.6
- Nginx 1.14.2

Using Alpine 3.9.4

## Requirements

To build this container you need to have docker installed. A makefile is provided along with the project to facilitate
building and publishing of the images.

## Configure and Install

Check the **deploy.env** file for build configurations for both the production and development images. To publish the image you will
need to change the **DOCKER_REPO** var to your repository location. This can also be a private repository location.

## Building the docker image

To create the production image run:
```
make image
```

To create the development image run:
```
make dev-image
```

To create and publish a new version of the production image run:
```
make release
```

To create and publish a new version of the development image run:
```
make dev-release
```

For more information on what it is possible to do

```
make help
```

## Usage

To correctly use this image as a PHP web application the following is required:

- You can use this image directly to serve static php content or you can generate a new image.
- The application code needs to be placed under /app and the static web content (html pages, javascripts, css's and othre) under /app/html
- The container entrypoint script needs to be executed by root. The entrypoint script starts and monitors the required processes for the webserver.
- The application and webserver processes run with non-root user **application** (UID - 1000, GID - 1000)
- If application specific Nginx configurations are required, add them to a file and copy it to **/etc/nginx/90-webapp-settings.conf**.

To use the image directly run:

```
$ docker run --name my-npm-app -v /some/content:/app/html:ro -d

```

Alternatively, create an application specific Dockerfile to generate a new image that includes the necessary content and additional configurations:

```
FROM stvfccn/npn_webserver

#--- additional NGINX configurations
COPY config/my-nginx-webapp-settings.conf $NGINX_ROOT/90-webapp-settings.conf


USER application

#--- copy application contents
WORKDIR $APP_ROOT
COPY my-app-contents .

#--- prepare application
RUN composer install --no-dev
RUN npm install --production
RUN grunt dist

# run this container as root because of entrypoint script or replace with new entrypoint
USER root

```

## Author

Paulo Costa

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/fccn/docker-npn-webapp-base/tags).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
