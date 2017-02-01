# CASP Dashboard Stack

This is the technical analysis of the system to be implemented. It defines the
technologies and tools used and the interactions between them. The justification
for each choice is also included where needed.

Terminology:

 - We use the term *minion* to refer to the salt minions because that is the way
   they are called in Salt documentation.
 - We use the term *node* to refer to k8s nodes.
 - We don't use the term *worker* in this document. We will use this term only
   in the GUI because we don't want to expose Salt terminology to our users
   since this is internal to our system.

## Framework

The application will be based on [Ruby on Rails](http://rubyonrails.org/). There
are 2 main reasons for this choice:

- It is a very mature web framework with great community and support for various
  3rd party services/products (through 3rd party gems mostly).
- Our team has extensive combined experience in Rails so it will make things
  easier and quicker for development and maintenance.

We also use Rails in [other projects](https://github.com/SUSE/Portus).

At the time of writing this document the latest stable version of Rails is 5.
Version 5 is not yet packaged as RPMs and it requires a newer version of ruby.
Hence we will use Rails 4.x to create the dashboard and later we will migrate
the application to Rails 5. The migration path from 4 to 5 seems straightforward.

## Database/Storage

The application will need to store various information. Possible candidates for
persistence are:

- Users and credentials (for dashboard). If we use LDAP for authentication then
  we will use the same configuration as we did with
  [Portus](https://github.com/SUSE/Portus).
- Nodes, their current "role" in the k8s cluster, their IP/hostname, their
  salt ID etc.
- Node Roles (e.g. k8s-master, k8s-node). These will map to some state file on
  the file system which, when applied, will setup the specified role on the
  selected node.

In order to recover from failure (database corruption, hardware failure etc), we need to provide the means for the user to connect a new dashboard container to an existing salt-master without loosing any information.
For this we have the following options:

- Good old backups (automated). If crucial information doesn't change too often, this solution might be adequate.
- Information retrieval from the stack. Most of the vital information can be retrieved through salt and kubernetes themselves. For example:
  - Nodes: Since they are registered on salt-master, we can run any command on
    them and get any information we need.
  - Node Roles: these were created automatically during bootstrapping so we can
    simply create them again from scratch (and map them to Nodes, see the
    previous). Recovering by querying the nodes can take quite some time
    depending on the number of nodes in the cluster, the information that needs
    to be extracted etc.

For this reason our storage for Dashboard will be MariaDB, because it has L3
support, it integrates well with Rails (ActiveRecord) and supports complicated
queries (joins and the rest).

## UI

Some of the required features will need us to update the UI dynamically without
the need for the user to refresh the page. For example, when new nodes are added
they should show up in the dashboard or other relevant pages. Also, while
setting up the cluster (or applying a template) we should provide feedback to
the user (like a progress bar) in order to visualize what is going on.

All these can be better achieved with some kind of push mechanism (like Server
Sent Events or Websockets) in combination with some JavaScript framework to
manipulate the DOM (ReactJS, Vue.js, AngularJS etc). We will avoid taking
decisions about JS frameworks until it becomes necessary.

## Interacting with Salt

The Rails application is the interface we provide to the user in order to assign
roles and manage available resources. It can be seen as a layer
above [Salt](https://saltstack.com/) which passes commands to the salt-master.

In order for our application to interact with salt we decided to use
the
[Salt REST API](https://docs.saltstack.com/en/latest/ref/netapi/all/salt.netapi.rest_cherrypy.html)

**Pros:**

- Modular architecture.
- Easier maintenance and separation of concerns. The dashboard docker image
  only contains a web app. Salt-master lives in an other container.
- We can try different frontends/dashboards based on the same CASP image.

**Cons:**

- The salt API might change in the future and we will need to adapt to the
  changes. To be honest, this is a common problem of all APIs.

### Reacting on events

Sending commands to salt is one side of the coin. Some of these commands might
take long to complete. Also, after they complete, we might need to take actions
which can also take some time. For this reason doing this synchronously is not
an option. When we send a command to the minions, a job is created inside
salt. We can get the job's id by using the "local_async" client in the API
request as this:

```
 >> curl -sSi http://localhost:8000 -H 'X-Auth-Token: a49d98d1aa3f72e2fa201ce42ca4402fbb98c06d' -H 'Content-type: application/json' -d '[{"client": "local_async", "tgt": "*", "fun": "state.apply", "arg": ["k8s_master"]}]'

{"return": [{"jid": "20161222113725508635", "minions": ["4c0669a7dcfa"]}]}
```

The above command returns immediately with the job id. When this job is
complete, we will need to update the minions data in our database to reflect the
change. In this case the minions were applied the k8s_master state. Salt
provides the information of job completion through the event system. One would
simply have to run this command to see the events
(more
[here](https://docs.saltstack.com/en/2015.8/topics/event/index.html#from-the-cli)):

```
salt-run state.event pretty=True
```

So, we have the job id and a stream of events that notifies us when this job is
complete. We simply have to monitor for events and act accordingly.

We decided to configure the salt-master to log all the events inside of MariaDB.
This is a native feature of salt
called
[master-side returner](https://docs.saltstack.com/en/latest/topics/jobs/external_cache.html#master-job-cache-master-side-returner).

All the events (jobs completions, new minions who want to register against the
salt master,...) are going to be stored inside of the MariaDB instance used by
the dashboard application.

A long running process is going to pick them up and process them. This program
is going to be written in Ruby and it will use the same models defined by the
Ruby on Rails application. This will eliminate code duplication between the
dashboard and the worker.

It will be possible to run multiple instances of the worker to speed up the
processing of the salt events.

## Summary

These are the components being used on the controller node:

- Web stack: vanilla Rails 4, no fancy JS framework is going to be used in the
  beginning. Later we can use less intrusive ones like ReactJS or VueJS if
  needed.
- Application server: [puma](https://github.com/puma/puma). Used also by the
  cloud team and soon by Portus.
- Web server: Not needed at all.
- Database: MariaDB
- Background Jobs: no need right now, just a long running job processing the
  salt events.
- Configuration management: salt. We will interact with it via the salt API.

The deployment of all these components (dashboard, database and salt) is going
to be done through Docker images. The containers are going to be managed by
kubelet as [static-pod](http://kubernetes.io/docs/admin/static-pods/). This
setup is not to be confused with the kubernetes cluster managed by the Dashboard
itself).

The following containers will be running on the control node:

- salt-master: used to manage the nodes
- salt-api: used by the dashboard to communicate with salt
- salt-minion-ca: used to implement the PKI infrastructure through salt
- MariaDB: used to store the dashboard data and the salt-master events
- dashboard: Ruby on Rails web application used by operators to deploy and
  maintain the cluster
- 1+ worker(s): used to process the salt events. Written in Ruby, will share
  some code with the Ruby on Rails application to avoid code duplication.
