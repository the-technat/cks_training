# Hardening the kube-apiserver

## Using an OIDC provider to authenticate users

Problem: client-certificates are secure but extremely dangerous since everyone that has acess to my local unprotected file could access the K8s cluster as admin.

Solution: leave the admin kubeconfig on the master node itself and don't copy it everywhere. Configure the kube-apiserver as OIDC client for an IDP and authenticate your users throuth the IDP generating tokens that can be used as valid Bearer tokens to authenticate against the kube-apiserver.

This behaviour is documented [here](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens).

I'm going to configure this here using a in-kubernetes running dex as IDP that uses Github as it's IDP in the back. This has the advantage that you can configure multiple K8s apps using CRDs to use Dex as it's IDP and only use one-time config on github's side.

My doc is based on this [this](https://dexidp.io/docs/kubernetes/).

### Step 1: Prerequisites

We are running dex on K8s. You need:

- a Cloud Controller Manager for HCLOUD
- cert-manager using a ClusterIssuer
- ingress-nginx to expose dex

See the [lab_env](../lab_env/) for how those are setup.

### Step 2: Install Dex

Since there is a lot of config required, we install dex using helm.

So first create a secret for Github oauth creds (register a new app [here](https://github.com/settings/applications/new)) and create some secrets:

```bash
kubectl create ns dex
kubectl -n dex create secret \
    generic github-client \
    --from-literal=client-id=$GITHUB_CLIENT_ID \
    --from-literal=client-secret=$GITHUB_CLIENT_SECRET
```

Then get dex:

```
helm repo add dex https://charts.dexidp.io
helm upgrade -i dex -n dex dex/dex -f dex-values.yaml
```

See the [dex-values.yaml](./dex-values.yaml) for my custom config.
Note: change the Issuer in the values file accordingly and also the secret for the static client.

### Step 3: Configure the kube-apiserver oidc connect token auth plugin

On the master node, edit the file `/etc/kubernetes/manifests/kube-apiserver.yaml` and add the following to the `command` field:

```yaml
command:
- kube-apiserver
- --oidc-issuer-url=https://dex.alleaffengaffen.ch
- --oidc-client-id=kubernetes
```

### Step 4: Configure your local kubeconfig

Now that the apiserver is configured and dex is configured, we need to configure our local kubectl. The problem to solve is that kubernetes doesn't have a web interface and we therefore need to authenticate to the IDP first.
But we can solve this using tools like [kubelogin](https://github.com/int128/kubelogin).

So start by getting kubelogin as a binary to your path. Name it `kubectl-oidc_login` so that it's recognized a a kubectl plugin.

Check with `kubectl oidc-login` and make sure that the help gets printed.

The rest of the setup can be generated for you if you run:

```bash
kubectl oidc-login setup \ 
  --oidc-issuer-url=https://dex.alleaffengaffen.ch \
  --oidc-client-id=kubernetes \
  --oidc-client-secret=KkEHL61EJtr8ssmnqfzh
```

Just follow the printed commands to add a clusterrolebinding and configure your kubeconfig.