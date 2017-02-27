# Salt usage

This is a technical document explaining how we use and take advantage of `Salt`.

Terminology:

- We use the term *minion* to refer to the salt minions, because that is the way they are called in
  Salt documentation.

# Salt API

We do use the [Salt API](https://docs.saltstack.com/en/latest/ref/netapi/all/salt.netapi.rest_cherrypy.html)
for almost all operations we perform on `Salt` from within `Velum`. There are some exceptions, that
we will describe in this document.

## Bootstrapping process

During the bootstrapping process, we do several tasks with `Salt`. Mainly:

1. Set grains on minions.
2. Add information to the pillar.
3. Run the orchestration.

### Grains

Grains are tiny amounts of information, automatically collected, or manually set.

During the bootstrapping process, we will set `roles` for all minions. Right now, from the UI it
will be possible to select which machine will take the kubernetes master role (that means, the
machine that will run the `apiserver`, `controller-manager`...).

This `role` is a grain, and is set through the `Salt API` from the `Velum` dashboard. The rest of
discovered minions will be set the `kubernetes-minion` `role` (that means, the machines that will
run the `kubelet`, `container runtime`...).

### Pillar

The pillar contains global information that is meant to be `static`. Some pillar settings are meant
to never change, and some other pillar settings are meant to be set during the bootstrapping
process, and never change again (at least in a long time).

The pillar cannot be modified using the `Salt API`. For this reason, we are using an [external
Pillar](https://docs.saltstack.com/en/latest/ref/pillar/all/salt.pillar.mysql.html), that
complements the static Pillar that we already have. You can find more information about the `mysql`
based external pillar [here](https://docs.saltstack.com/en/latest/ref/pillar/all/salt.pillar.sql_base.html).

#### External Pillar

Since SaltStack is highly modular, there are several ways to set up an external pillar. In our case,
we are setting an external pillar that will rely on our `mysql` instance running on the controller
node.

This external pillar will be merged with the static Pillar, allowing for certain configurable
settings to override the original ones, or to create completely new attributes that our salt states
might or will read.

This allows us to rely on our static Pillar with reasonable defaults, and choose what attributes
will be configurable during the bootstrapping process that will override those defaults.
