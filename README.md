# Velum

| master | Code Climate |
|--------|------|--------------|
| [![Build Status](https://travis-ci.org/kubic-project/velum.svg?branch=master)](https://travis-ci.org/kubic-project/velum) | [![Code Climate](https://codeclimate.com/github/kubic-project/velum/badges/gpa.svg)](https://codeclimate.com/github/kubic-project/velum) [![Test Coverage](https://codeclimate.com/github/kubic-project/velum/badges/coverage.svg)](https://codeclimate.com/github/kubic-project/velum/coverage) |

Velum is a dashboard that manages your SUSE CaaSP cluster. With Velum, you will
be able to:

- Bootstrap a Kubernetes cluster with a simple click.
- Manage your Kubernetes cluster: adding and removing nodes from your cluster,
  monitoring faulty nodes, etc.
- Setup an update policy that suits your needs. SUSE CaaSP already provides a
  transparent and sensible procedure for updates that guarantees no downtime,
  but with Velum you will be able to further tune this.

The architecture of CaaSP uses [Salt](https://saltstack.com/) quite heavily,
and worker nodes are supposed to run as
[Salt minions](https://docs.saltstack.com/en/latest/ref/cli/salt-minion.html). These
Salt minions should then register to Velum, which acts as a Salt master. As an
administrator, when setting up the cluster, you will see nodes popping up, and
then you will be able to provision all the nodes from your cluster with Kubernetes
in a single click.

Once you have bootstrapped your cluster, you will be presented with a web
application that allows you to manage your cluster, define your update policy,
and much more.

## Configuration

From an existing Kubernetes application, set the following environment variables
and start the server:

- `VELUM_SALT_HOST`: IP of the Salt API server.
- `VELUM_SALT_PORT`: Port of the Salt API server.
- `VELUM_SALT_USER`: The user allowed to access the Salt API.
- `VELUM_KUBERNETES_HOST`: IP of the Kubernetes API server.
- `VELUM_KUBERNETES_PORT`: port of the Kubernetes API server.
- `VELUM_KUBERNETES_CERT_DIRECTORY`: directory where the Kubernetes
  certificates are located.

Note that the development environment already sets all these values for you.

## Development

You can develop on Velum with all its required dependencies right away using the
`start` script within the `kubernetes` folder. You will need a
[standalone kubelet](https://kubernetes.io/docs/admin/kubelet/) running in your
machine.

### Start the development containers

```sh
$ cd kubernetes
$ ./start
```

This will start the Velum container as well as other required containers.

You can use the `--non-interactive` flag if you prefer to run in non interactive mode.
In that case you will be asked before old containers are removed.

E.g.

```sh
$ ./start --non-interactive
```

If you want to use your own set of Salt states you can provide the `SALT_DIR`
environment variable to the start script, so that directory will be used as Salt
root. For example, you could set this variable to a local clone of
[kubic-project/salt](https://github.com/kubic-project/salt).

Your Velum folder will be mounted on the Velum container, so any change you do
locally to Velum will be seen inside the container. Once that the service is up,
you should be able to see the Velum service at `http://localhost:3000/` on your
local machine.

After any change that you have performed you can run any rails/rake task as if
it was local, with the Docker prefix, like:

```sh
$ docker exec -it $(docker ps | grep velum-dashboard | awk '{print $1}') bash -c "RAILS_ENV=test rspec"
$ docker exec -it $(docker ps | grep velum-dashboard | awk '{print $1}') bash -c "RAILS_ENV=test rubocop".
```

### Spawning test workers

You can spawn new test workers with
our [terraform](https://github.com/kubic-project/terraform) setup. In there you
will notice that there are quite some options, but bear in mind that in order
to work with this repository you should:

- Set the `DASHBOARD_HOST` environment variable with the IP of your host.
- Set the `SKIP_DASHBOARD` to 1, since Velum already provides that.

So, for example, if the IP of your host is `192.168.1.33`, then you should
perform the following command on the `terraform` directory:

```sh
$ DASHBOARD_HOST=192.168.1.33 SKIP_DASHBOARD=1 FLAVOUR=opensuse MINIONS_SIZE=2 contrib/libvirt/k8s-libvirt.sh apply
```

This will create 2 openSUSE minion workers that will register themselves to
Velum. After that, you should be able to see these nodes in the web
application and click the "Bootstrap" button to provision your cluster.

### Tips & tricks

If you want to debug the provisioning phase, you could run the following
command:

```sh
$ docker exec -it $(docker ps | grep salt-master | awk '{print $1}') salt-run state.event pretty=True
```

This will give you the output of Salt events as they come. Moreover, you can
also bootstrap your cluster programmatically instead of doing it from the web
application:

```sh
$ docker exec -it $(docker ps | grep velum-dashboard | awk '{print $1}') rails runner 'require "velum/salt"; Minion.assign_roles!(roles: { "minion0.k8s.local" => ["master"] }, default_role: :minion); Velum::Salt.orchestrate'
```

### Cleaning things up

To clean things up, you can first remove your minion nodes created by terraform:

```sh
$ contrib/libvirt/k8s-libvirt.sh destroy
```

And then in Velum:

```sh
$ cd kubernetes
$ ./cleanup
```

And that should be all!

## Licensing

Velum is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/kubic-project/velum/blob/master/LICENSE) for the
full license text.
