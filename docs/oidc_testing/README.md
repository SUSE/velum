# Bring up a cluster
1. Set up dev environment
   ```
   git clone git@github.com:kubic-project/automation
   cd automation
   ./caasp-devenv --setup
   ```
1. `cd ../automation && ./caasp-devenv --build --bootstrap` (with whatever other options, like `-L provo`)

# Bring up the stand-alone dex OIDC Provider (OP)
1. `cd ../velum/docs/oidc_testing`
1. `cp examples/config-dev.yaml{.example,}`
1. edit `examples/config-dev.yaml` as needed, paying special attention to the two places marked `NOTE`:
   * set the `issuer:` URL to match the DNS host name of your development machine.  Note that this hostname must resolve _via DNS_ from the master and worker nodes running the dex_dex container.  You can check this via: `docker exec _container_id_ ping -c 1 _host_name_`.  You should get a response back, and it should show the IP address of the host.  The URL used as the issuer _must_ be exactly the URL you use in the OIDC provider URL field in Vellum".
   * If you do not have a DNS-resolvable name, there are a variety of ways to fix that.  The easiest is to add an entry to the libvirt DNS resolver, which will make the hostname/IP mapping work from the VMs and containers within, but won't affect anything outside the cluster.  Say you're using `dexhost.do.main` as your issuer name, and it's listening on `192.168.0.213`.  Do this, and then retry the ping test above:
     ```
     virsh net-update caasp-dev-net add dns-host '<host ip="192.168.0.213"><hostname>dexhost.do.main</hostname></host>' --live --config
     ```
     Note that you can add multiple hostnames within the host, should that be necessary.
1. still in the directory where docker-compose.yml is, run `docker-compose up -d`
   * output should look roughly like this:
     ```
     sauer@lightning:~/dev/dex$ docker-compose up -d
     Starting dex_base_1 ... done
     Starting dex_dex_1  ... done
     sauer@lightning:~/dev/dex$ 
     ```
   * logs can be accessed using `docker-compose logs` in the same directory; append `-f` to equivocate `tail -f` on the log
1. it should be possible to use WebFinger to fetch the important data from Dex now, using `curl http://dexhost.do.main:5556/dex/.well-known/openid-configuration` on the admin node.  You should get back a JSON document listing the expected issuer, some endpoints, supported scopes, etc.  Note specifically that if the issuer URL is broken (`http:/host:5556/dex`, for example -- note the wrong number of slashes), dex may start up without emitting a warning, but the curl check will return a 404. Do not skip this test. :)

# Configure and test the OIDC provider in velum
1. log in to admin.devenv.caasp.suse.net
1. under settings, click `new oidc provider`
1. put an "x" in all the fields, and hit save (these values are currently not saved)
1. click on the "edit" button next to the newly-created "oidc_provider_1"
1. fill in the values correctly
   * name is arbitrary (will be the string the user generally sees)
   * Endpoint URL is the is the same as the issuer from the config file
   * callback URL should be Kubernetes callback URL: `https://kube-api-x1.devenv.caasp.suse.net:32000/callback` (in config file's static client list)
   * leave basic auth on (turning it off is for rare non-compliant OPs)
   * client id is `example-app` (from the static clients in config file)
   * client secret is `ZXhhbXBsZS1hcHAtc2VjcmV0` (from the static clients in config file)
1. save and apply changes
1. wait for orchestration to complete
1. Go to https://admin.devenv.caasp.suse.net/oidc/
1. Select the "Log in with X" button which matches the name you provided in the setup
1. Select either option
   * Log in with email: use the email and password from the example config (defaults are admin@example.com/password)
   * Log in with Example: use the "mock" provider in dex, which doesn't prompt for anything, just returns success
1. You should be redirected to Velum and be presented with a kubeconfig for the user you selected in the previous step
1. You should also see a log message logged (use `docker-compose logs`); success with the mock option looks like this:
   `dex_1   | time="2018-08-24T19:15:15Z" level=info msg="login successful: connector \"mock\", username=\"Kilgore Trout\", email=\"kilgore@kilgore.trout\", groups=[\"authors\"]"`

# Clean up testing environment
1. Tear down the dex container
   * In the velum directory containing the docker-compose.yml: `docker-compose down`
   * should look like this:
     ```
     sauer@lightning:~/dev/dex$ docker-compose down
     Stopping dex_dex_1 ... done
     Removing dex_base_1 ... done
     Removing dex_dex_1  ... done
     Removing network dex_default
     ```
1. Tear down the cluster
   * In the automation directory:`./caasp-devenv --destroy`
