# Velum


| master | Code Climate |
|--------|------|--------------|
| [![Build Status](https://travis-ci.org/kubic-project/velum.svg?branch=master)](https://travis-ci.org/kubic-project/velum) | [![Code Climate](https://codeclimate.com/github/kubic-project/velum/badges/gpa.svg)](https://codeclimate.com/github/kubic-project/velum) [![Test Coverage](https://codeclimate.com/github/kubic-project/velum/badges/coverage.svg)](https://codeclimate.com/github/kubic-project/velum/coverage) |

From an existing Kubernetes application, set the following environment variables
and start the server:

- `VELUM_SALT_HOST`: IP of the Salt API server.
- `VELUM_SALT_PORT`: Port of the Salt API server.
- `VELUM_SALT_USER`: The user allowed to access the Salt API.
- `VELUM_KUBERNETES_HOST`: IP of the Kubernetes API server.
- `VELUM_KUBERNETES_PORT`: port of the Kubernetes API server.
- `VELUM_KUBERNETES_CERT_DIRECTORY`: directory where the Kubernetes
  certificates are located.

## Development

You can develop on velum with all its required dependencies right away using the `start` script
within the `kubernetes` folder. You will need a [standalone kubelet](https://kubernetes.io/docs/admin/kubelet/) running in your machine.

### Start the development container

`> cd kubernetes`
`> ./start`

This will start the velum container as well as other required containers.

If you want to use your own set of salt states you can provide `SALT_DIR` environment variable
to the start script, so that directory will be used as salt root.

Your velum folder will be mounted on the velum container, so any change you do locally to velum
will be seen inside the container. Once that the service is up, you should be able to see the
velum service at `http://localhost:3000/` on your local machine.

After any change that you have performed you can run any rails/rake task as if it was local, with
the docker prefix, like `docker exec -it $(docker ps | grep velum-dashboard | awk '{print $1}') bash -c "RAILS_ENV=test rspec"` or `docker exec -it $(docker ps | grep velum-dashboard | awk '{print $1}') bash -c "RAILS_ENV=test rubocop"`.

## Licensing

Velum is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/kubic-project/velum/blob/master/LICENSE) for the full
license text.
