# Velum

| master | Code Climate |
|--------|--------------|
| [![Build Status](https://travis-ci.org/kubic-project/velum.svg?branch=master)](https://travis-ci.org/kubic-project/velum) | [![Code Climate](https://codeclimate.com/github/kubic-project/velum/badges/gpa.svg)](https://codeclimate.com/github/kubic-project/velum) [![Test Coverage](https://codeclimate.com/github/kubic-project/velum/badges/coverage.svg)](https://codeclimate.com/github/kubic-project/velum/coverage) |

Velum is a dashboard that manages your Kubic/SUSE CaaS Platform cluster. With Velum, you will
be able to:

- Bootstrap a Kubernetes cluster with a simple click.
- Manage your Kubernetes cluster: adding and removing nodes from your cluster,
  monitoring faulty nodes, configuring the cluster, etc.
- Setup an update policy that suits your needs. Kubic/SUSE CaaS Platform already provides a
  transparent and sensible procedure for updates that guarantees no downtime,
  but with Velum you will be able to further tune this.

The architecture of Kubic/CaaS Platform uses [Salt](https://saltstack.com/) quite heavily,
and worker nodes are supposed to run as
[Salt minions](https://docs.saltstack.com/en/latest/ref/cli/salt-minion.html). These
Salt minions should then register to Velum, which acts as a Salt master. As an
administrator, when setting up the cluster, you will see nodes popping up, and
then you will be able to provision all the nodes from your cluster with Kubernetes
in a single click.

Once you have bootstrapped your cluster, you will be presented with a web
application that allows you to manage your cluster, define your update policy,
and much more.

![Velum Dashboard](https://raw.githubusercontent.com/kubic-project/community/master/assets/velum-dashboard.png)
![Velum Settings](https://raw.githubusercontent.com/kubic-project/community/master/assets/velum-settings.png)

## Development

You can start a Velum development environment by following the instructions in [caasp-kvm](https://github.com/kubic-project/automation/caasp-kvm).

## Licensing

Velum is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/kubic-project/velum/blob/master/LICENSE) for the
full license text.
