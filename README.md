# Pharos


| master | Code Climate |
|--------|------|--------------|
| [![Build Status](https://travis-ci.org/SUSE/pharos.svg?branch=master)](https://travis-ci.org/SUSE/pharos) | [![Code Climate](https://codeclimate.com/github/SUSE/pharos/badges/gpa.svg)](https://codeclimate.com/github/SUSE/pharos) [![Test Coverage](https://codeclimate.com/github/SUSE/pharos/badges/coverage.svg)](https://codeclimate.com/github/SUSE/pharos/coverage) |

From an existing Kubernetes application, set the following environment variables
and start the server:

- `PHAROS_SALT_HOST`: IP of the Salt API server.
- `PHAROS_SALT_PORT`: Port of the Salt API server.
- `PHAROS_SALT_USER`: The user allowed to access the Salt API.
- `PHAROS_KUBERNETES_HOST`: IP of the Kubernetes API server.
- `PHAROS_KUBERNETES_PORT`: port of the Kubernetes API server.
- `PHAROS_KUBERNETES_CERT_DIRECTORY`: directory where the Kubernetes
  certificates are located.

## Licensing

Pharos is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/SUSE/Pharos/blob/master/LICENSE) for the full
license text.
