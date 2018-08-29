# Docker image for a generic Nginx-PHP-NodeJS web application server

A set of docker images to use for PHP web applications with NGINX and NodeJS.

- npn_webserver - Nginx-PHP-Nodejs webserver with a set of tools and configurations for production grade PHP and NodeJS web applications
- npn_webserver-dev - Nginx-PHP-Nodejs webserver with a set of tools and configurations for development and testing of PHP and NodeJS web applications

## Requirements

To build this container you need to have docker installed. A makefile is provided along with the project to facilitate 
building and publishing of the images.

To deploy a PHP web application using this image the following is required:

- Create an application specific Dockerfile using this image as base and import the application code.
- The application code needs to be placed under /app and the static web content (html pages, javascripts, css's and othre) under /app/html
- The application and webserver processes run with non-root user **application**
- If application specific Nginx configurations are required, add them to a file and copy it to **/etc/nginx/90-webapp-settings.conf** in your Dockerfile.

## Configure and Install

Check the **deploy.env** file for build configurations on the production image and **deploy_dev.env** 
for build configurations on the development image.

## Building the docker image

To create the production image run:
```
make image
```

To create the development image run:
```
make dpl="deploy_dev.env" image
```

To create and publish a new version of the production image run:
```
make release
```

To create and publish a new version of the development image run:
```
make dpl="deploy_dev.env" release
```

For more information on what it is possible to do

```
make help
```

## Author

Paulo Costa

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/fccn/docker-npn-webapp-base/tags).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
