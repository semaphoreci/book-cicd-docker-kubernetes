\newpage

# 2 Deploying to Kubernetes

When getting started with Kubernetes, one of the first commands that you learn and use is generally `kubectl run`. Folks who have experience with Docker tend to compare it to `docker run` and think: "Ah, this is how I can simply run a container!"

As it turns out, when you use Kubernetes, you don't simply run a container.

The way in which Kubernetes handles containers depends heavily on which version you are running [^book-versions]. You can check the server version with:

```
$ kubectl version
```

[^book-versions]: At the time of writing, all major cloud vendors provide managed Kubernetes at versions 1.19 and 1.20. This book is based on and has been tested with those versions.

**Kubernetes containers on versions 1.17 and lower**

When using a version *lower* than 1.18, look at what happens after running a very basic `kubectl run` command:

```
$ kubectl run web --image=nginx
deployment.apps/web created
```

Alright! Then you check what was created on the cluster, and ...

```
$ kubectl get all
NAME                      READY STATUS  RESTARTS AGE
pod/web-65899c769f-dhtdx  1/1   Running 0        11s

NAME                TYPE      CLUSTER-IP  EXTERNAL-IP PORT(S) AGE
service/kubernetes  ClusterIP 10.96.0.1   1.2.3.4     443/TCP 46s

NAME                 DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
deployment.apps/web  1       1       1          1         11s

NAME                            DESIRED CURRENT READY AGE
replicaset.apps/web-65899c769f  1       1       1     11s
```

_"I just wanted a container! Why do I get three different objects?"_

Instead of getting a container, you got a whole zoo of unknown beasts:

- a *deployment* (called `web` in this example),
- a *replicaset* (`web-65899c769f`),
- a *pod* (`web-65899c769f-dhtdx`).

Note: you can ignore the *service* named `kubernetes` in the example above; that one already existed before the `kubectl run` command.

**Kubernetes containers in versions 1.18 and higher**

When you are running version 1.18 or *higher*, Kubernetes does indeed create a single pod. Look how different Kubernetes acts on newer versions:

```
$ kubectl run web --image=nginx
pod/web created
```

As you can see, more recent Kubernetes versions behave pretty much in line with what seasoned Docker users would expect. Notice that no deployments or replicasets are created:

```
$ kubectl get all
NAME      READY STATUS  RESTARTS AGE
pod/web   1/1   Running 0        3m14s

NAME                 TYPE      CLUSTER-IP EXTERNAL-IP PORT(S) AGE
service/kubernetes   ClusterIP 10.96.0.1  1.2.3.4     443/TCP 4m16s
```

So, if we want to create a deployment we must be more explicit. This command works as expected on all Kubernetes versions:

```
$ kubectl create deployment web --image=nginx
deployment.apps/web created
```

The bottom line is that we should always use the most explicit command available in order to future proof our deployments.

Next, you'll learn the roles of these different objects and how they are essential to zero-downtime deployments in Kubernetes.

Continuous integration gives you confidence that your code works. To extend that confidence to the release process, your deployment operations need to come with a safety belt too.

## 2.1 Containers and Pods

In Kubernetes, the smallest unit of deployment is not a container;
it's a **pod**. A pod is just a group of containers (which can also be a group
of *one* container) that runs on the same machine and shares a few
things together.

For instance, the containers within a pod can communicate with each
other over `localhost`. From a network perspective, all the processes
in these containers are local.

But you can never create a standalone container: the closest you can do
is create a pod with a single container in it.

That's what happens here: when you tell Kubernetes, "create me an
NGINX!", you're really saying, _"I would like a pod, in which there
should be a single container, using the `nginx` image."_

```yaml
# pod-nginx.yml
# Create it with:
#    kubectl apply -f pod-nginx.yml
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
    - image: nginx
      name: nginx
      ports:
        - containerPort: 80
          name: http
```

Alright, then, why doesn't it just have a pod? Why the replica set and
deployment?

## 2.2 Declarative vs Imperative Systems

Kubernetes is a **declarative system** (which is the opposite of an imperative systems).
This means that you can't give it orders.
You can't say, "Run this container." All you can do is describe
what you want to have and wait for Kubernetes to take action to reconcile
what you have, with what you want to have.

In other words, you can say, _"I would like a 40-feet long blue container
with yellow doors"_, and Kubernetes will find such a container for you.
If it doesn't exist, it will build it; if there is already one but it's green
with red doors, it will paint it for you; if there is already a container
of the right size and color, Kubernetes will do nothing, since *what you have*
already matches *what you want*.

In software container terms, you can say, _"I would like a pod named `web`,
in which there should be a single container, that will run the `nginx` image."_

If that pod doesn't exist yet, Kubernetes will create it. If that pod
already exists and matches your spec, Kubernetes doesn't need to do anything.

With that in mind, how do you scale your `web` application, so that it runs
in multiple containers or pods?

## 2.3 Replica Sets Make Scaling Pods Easy

If all you have is a pod, and you want more identical pods, all you can do
is get back to Kubernetes and tell it, _"I would like a pod named `web2`,
with the following specification: ..."_ and re-use the same specification
as before. Then, repeat this as many times as you want to have pods.

This is rather inconvenient, because it is now your job to keep track of
all these pods, and to make sure that they are all in sync, using the
same specification.

To make things simpler, Kubernetes gives you a higher level construct:
the **replica set**. The specification of a replica set looks very much like
the specification of a pod, except that it carries a number indicating how
many *replicas*—i.e. pods with that particular specification—you want.

So you tell Kubernetes, _"I would like a replica set named `web`, which
should have 3 pods, all matching the following specification: ..."_ and
Kubernetes will accordingly make sure that there are exactly three matching pods.
If you start from scratch, the three pods will be created. If you already have three pods,
nothing is done because *what you have* already matches *what you want*.

```yaml
# pod-replicas.yml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-replicas
  labels:
    app: web
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        app: web
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

Replica sets are particularly relevant for scaling and high availability.

Scaling is relevant because you can update an existing replica set to change the
desired number of replicas. As a consequence, Kubernetes will create or
delete pods so it will be the exact desired number in the end.

For high availability, it is relevant because Kubernetes will continuously monitor
what's going on in the cluster. It will ensure that no matter what happens,
you still have the desired number.

If a node goes down, taking one of the `web` pods with it, Kubernetes creates
another pod to replace it. If it turns out that the
node wasn't down, but merely unreachable or unresponsive for a while, you may have one extra pod
when it comes back. Kubernetes will then terminate a pod
to make sure that you still have the exact requested number.

What happens, however, if you want to change the definition of a pod
within your replica set? For instance, what happens when you want to switch the image that you
are using with a newer version?

Remember: the mission of the replica set is, _"Make sure that there are N pods
matching this specification."_ What happens if you change that definition?
Suddenly, there are zero pods matching the new specification.

By now you know how a declarative system is supposed to work:
Kubernetes should immediately create N pods matching your new specification.
The old pods would just stay around until you clean them up manually.

It makes a lot of sense for these pods to be removed cleanly and automatically
in a CI/CD pipeline, as well as for the creation of new pods to happen in a more
gradual manner.

## 2.4 Deployments Drive Replica Sets

It would be nice if pods could be removed cleanly and automatically in a CI/CD
pipeline and if the creation of new pods could happen in a more gradual manner.

This is the exact role of **deployments** in Kubernetes.
At a first glance, the specification for a deployment looks very much like
the one for a replica set: it features a pod specification, a number of
replicas, and a few additional parameters that you'll read about later in this guide.

```yaml
# deployment-nginx.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

Deployments, however, don't create or delete pods directly.
They delegate that work to one or more replica sets.

When you create a deployment, it creates a replica set, using the exact
pod specification that you gave it.

When you update a deployment and adjust the number of replicas, it
passes that update down to the replica set.

### 2.4.1 What Happens When You Change Configuration

When you need to update the pod specification itself, things get interesting.
For instance, you might want to change the image you're using (because you're
releasing a new version), or the application's parameters (through
command-line arguments, environment variables, or configuration files).

When you update the pod specification, the deployment creates
a new replica set with the updated pod specification.
That replica set has an initial size of zero.
Then, the size of that replica set is progressively increased,
while decreasing the size of the other replica set.

You could imagine that
you have a sound mixing board in front of you, and you are going to fade in
(turn up the volume) on the new replica set while fading out (turn down
the volume) on the old one.

During the whole process, requests are sent to pods of both the old and new
replica sets, without any downtime for your users.

That's the big picture, but there are many little details that make
this process even more robust.

## 2.5 Detecting Broken Deployments with Readiness Probes

If you roll out a broken version, it could bring the entire application down,
as Kubernetes will steadily replace your old pods with the new (broken) version,
one at a time.

Unless you use **readiness probes**.

A readiness probe is a test that you can add to a container specification.
It's a binary test that can only say "IT WORKS" or "IT DOESN'T," and
will be executed at regular intervals. By default, it executes every 10 seconds.

Kubernetes supports three ways of implementing readiness probes:

1. Running a command inside a container;
2. Making an HTTP(S) request against a container; or
3. Opening a TCP socket against a container.

Kubernetes uses the result of that test to know if the container and the
pod that it's a part of is ready to receive traffic. When you roll out
a new version, Kubernetes will wait for the new pod to mark itself as
"ready" before moving on to the next one.

If a pod never reaches the ready state because the readiness probe keeps
failing, Kubernetes will never move on to the next. The deployment stops,
and your application keeps running with the old version until you address
the issue.

**Note**: if there is no readiness probe, then the container is
considered as ready, as long as it could be started. So make sure
that you define a readiness probe if you want to leverage that feature!


## 2.6 Rollbacks for Quick Recovery from Bad Deploys

At any point in time, during the rolling update or even later, you
can tell Kubernetes: _"Hey, I changed my mind; please go back to the
previous version of that deployment."_ It will immediately switch
the roles of the "old" and "new" replica sets. From that point, it
will increase the size of the old replica set (up to the nominal
size of the deployment), while decreasing the size of the other one.

Generally speaking, this is not limited to two "old" and "new"
replica sets. Under the hood, there is one replica set that is
considered "up-to-date" and that you can think of as the "target"
replica set. That's the one that you're trying to move to; that's
the one that Kubernetes will progressively scale up. Simultaneously,
there can be any number of other replica sets, corresponding to older versions.

As an example, you might run version 1 of an application over 10
replicas. Then you'd start rolling out version 2. At some point, you
might have seven pods running version 1, and three pods running version 2.
You might then decide to release version 3 without waiting for
version 2 to be fully deployed (because it fixes an issue that wasn't noticed earlier).
And while version 3 is being deployed,
you might decide, after all, to go back to version 1. Kubernetes
will merely adjust the sizes of the replica sets (corresponding
to versions 1, 2, and 3 of the application) accordingly.

## 2.7 MaxSurge and MaxUnavailable

Kubernetes doesn't exactly update deployments one pod at a time.
Earlier, you learned that that deployments had "a few extra parameters": these
parameters include `MaxSurge` and `MaxUnavailable`, and they
indicate the pace at which the update should proceed.

You could imagine two strategies when rolling out new versions.
You could be conservative about your application availability,
and decide to start new pods before shutting down old ones.
Only after a new pod is up, running, and ready, can you terminate an old one.

This, however, implies that you have some spare capacity available on
our cluster. It might be the case that you can't afford to run any
extra pod, because your cluster is full to the brim, and that you
prefer to shutdown an old pod before starting a new one.

`MaxSurge` indicates how many extra pods you are willing to run
during a rolling update, while `MaxUnavailable` indicates how many
pods you can lose during the rolling update. Both parameters
are specific to a deployment: each deployment can
have different values for them. Both parameters can be expressed
as an absolute number of pods, or as a percentage of the deployment
size; and both parameters can be zero, but not at the same time.

Below, you'll find a few typical values for MaxSurge and MaxUnavailable
and what they mean.

Setting MaxUnavailable to 0 means, _"do not shutdown any old pod
before a new one is up and ready to serve traffic."_

Setting MaxSurge to 100% means, _"immediately start all the new
pods"_, implying that you have enough spare capacity on your cluster
and that you want to go as fast as possible.

The default values for both parameters are 25%,
meaning that when updating a deployment of size 100, 25 new pods
are immediately created, while 25 old pods are shutdown. Each time
a new pod comes up and is marked ready, another old pod can
be shutdown. Each time an old pod has completed its shutdown
and its resources have been freed, another new pod can be created.

## 2.8 Quick Demo

It's easy to see these parameters in action. You don't need to
write custom YAML, define readiness probes, or anything like that.

All you have to do is to tell a deployment to use an invalid
image; for instance an image that doesn't exist. The containers
will never be able to come up, and Kubernetes will never mark
them as "ready."

If you have a Kubernetes cluster (a one-node cluster like
minikube or Docker Desktop is fine), you can run the following commands
in different terminals to watch what is going to happen:

- `kubectl get pods -w`
- `kubectl get replicasets -w`
- `kubectl get deployments -w`
- `kubectl get events -w`

Then, create, scale, and update a deployment with the following commands:

```
$ kubectl create deployment web --image=nginx
$ kubectl scale deployment web --replicas=10
$ kubectl set image deployment web nginx=invalid-image
```

You can see that the deployment is stuck, but 80% of the application's capacity
is still available.

If you run `kubectl rollout undo deployment web`, Kubernetes will
go back to the initial version, running the `nginx` image.


## 2.9 Selectors and Labels

It turns out that the job of a replica set, as mentioned earlier,
is to make sure that there are exactly N pods matching the right
specification, that's not exactly what's going on.
Actually, the replica set doesn't look at
the pods' specifications, but only at their **labels**.

In other words, it
doesn't matter if the pods are running `nginx` or `redis` or whatever;
all that matters is that they have the right labels. In the examples
in the beginning of the chapter, these labels would look like `run=web` and `pod-template-hash=xxxyyyzzz`.

A replica set contains a *selector*, which is a logical expression
that "selects" a number of pods, just like a `SELECT` query in SQL.
The replica set makes sure that there is the right number of pods,
creating or deleting pods if necessary; but it doesn't change
existing pods.

Just in case you're wondering: yes, it is absolutely possible to manually
create pods with these labels, but running a different image or with
different settings, and fool your replica set.

At first, this could sound like a big potential problem. In practice
though, it is very unlikely that you would accidentally pick
the "right" (or "wrong", depending on the perspective) labels,
because they involve a hash function on the pod's specification
that is all but random.

### 2.9.1 Services as Load Balancers

Selectors are also used by **services**, which act as load balancers
of Kubernetes traffic, internal and external. You can create a service
for the `web` deployment with the following command:

```
$ kubectl expose deployment web --port=80
```

The service will have its own internal IP address
(denoted by the name `ClusterIP`) and an optional external IP,
and connections to these IP address on port 80 will be load-balanced
across all the pods of this deployment.

In fact, these connections will be load-balanced across all the pods
matching the service's selector. In that case, that selector will be
`run=web`.

When you edit the deployment and trigger a rolling update, a new
replica set is created. This replica set will create pods, whose
labels will include, among others, `run=web`. As such, these pods
will receive connections automatically.

This means that during a rollout, the deployment doesn't reconfigure
or inform the load balancer that pods are started and stopped.
It happens automatically through the selector of the service
associated to the load balancer.

If you're wondering how probes and healthchecks play into this,
a pod is added as a valid endpoint for a service only if all its
containers pass their readiness check. In other words, a pod starts
receiving traffic only once it's actually ready for it.

## 2.10 Advanced Kubernetes Deployment Strategies

Sometimes, you might want even more control when you roll out a new version.

Two popular techniques are
**blue/green deployment** and **canary deployment**.

### 2.10.1 Blue / Green Deployment

In blue/green deployment, you want to instantly switch over
all the traffic from the old version to the new, instead of doing it
progressively like explained previously. There could be a few
reasons to do that, including:

- You don't want a mix of old and new requests, and you want the
  break from one version to the next to be as clean as possible.
- You are updating multiple components (say, web frontend and API
  backend) together, and you don't want the new version of the
  web frontend to talk to the old version of the API backend or
  vice versa.
- If something goes wrong, you want the ability to revert as fast
  as possible, without even waiting for the old set of containers
  to restart.

![Blue/Green Deployment](figures/03-blue-green.png){ width=95% }

You can achieve blue/green deployment by creating multiple
deployments (in the Kubernetes sense), and then switching from
one to another by changing the selector of our service.

Let's see how this would work in a quick demo.

The following commands will create two deployments `blue` and
`green`, respectively using the `nginx` and `httpd` container
images:

```
$ kubectl create deployment blue --image=nginx
$ kubectl create deployment green --image=httpd
```

Then, you create a service called `web`, which initially won't
send traffic anywhere:

```
$ kubectl create service clusterip web --tcp=80
```

**Note**: when running a local development Kubernetes cluster, such as MiniKube[^minikube] or the one bundled with Docker Desktop, you'll wish to change the previous command to: `kubectl create service nodeport web --tcp=80`. The NodePort type of service is easier to access locally as the service ports are forwared to `localhost` automatically. To see this port mapping run `kubectl get services`.

Now, you can update the selector of service `web` by
running `kubectl edit service web`. This will retrieve the
definition of service `web` from the Kubernetes API, and open
it in a text editor. Look for the section that says:

```yaml
selector:
  app: web
```

Replace `web` with `blue` or `green`, to your liking.
Save and exit. `kubectl` will push your updated definition back
to the Kubernetes API, and voilà! Service `web` is now sending
traffic to the corresponding deployment.

You can verify for yourself by retrieving the IP address of
that service with `kubectl get svc web` and connecting to that
IP address with `curl`.

The modification that you did with a text editor can also be
done entirely from the command line, using for instance
`kubectl patch` as follows:

```
$ kubectl patch service web \
  -p '{"spec": {"selector": {"app": "green"}}}'
```

The advantage of blue/green deployment is that the traffic
switch is almost instantaneous, and you can roll back to the
previous version just as fast by updating the service
definition again.

[^minikube]: The official local Kubernetes cluster for macOS, Linux, and Windows for testing and development.
  _https://minikube.sigs.k8s.io/docs/_


### 2.10.2 Canary Deployment

Canary deployment alludes to the canaries that were used in
coal mines, to detect dangerous concentrations of toxic gas like
carbon monoxide. Canaries are more sensitive to toxic gas than humans.
The miners would carry a canary in a cage.
If the canary passed out, it meant that the miners had reached
a dangerous area and should head back before they would pass out too.

How does that map to software deployment?

Sometimes, you can't (or won't) afford to affect all your users
with a flawed version, even for a brief period of time. So instead,
you do a partial rollout of the new version. For instance, you could deploy
a couple of replicas running the new version, or you send 1% of your
users to that new version.

Then, you compare metrics between the current version and the canary
that you just deployed. If the metrics are similar, you can proceed.
If latency, error rates, or anything else looks wrong, you roll back.

![Canary Deployment](figures/03-canary.png){ width=95% }

This technique, which would be fairly involved to set up, ends up
being relatively straightforward thanks to Kubernetes' native
mechanisms of labels and selectors.

It's worth noting that in the previous example, we changed
the service's selector, but it is also possible to change the pods'
labels.

For instance, is a service's selector is set to look for pods
with the label `status=enabled`, you can apply such a label
to a specific pod with:

```
$ kubectl label pod fronted-aabbccdd-xyz status=enabled
```

You can apply labels *en masse* as well, for instance:

```
$ kubectl label pods -l app=blue,version=v1.5 status=enabled
```

And you can remove them just as easily:

```
$ kubectl label pods -l app=blue,version=v1.4 status-
```


## 2.11 Summary

You now know a few techniques that can be used to deploy with more confidence.
Some of these techniques simply reduce the downtime caused by the deployment
itself, meaning that you can deploy more often, without being afraid of
affecting your users.

Some of these techniques give you a safety belt, preventing
a bad version from taking down your service. And some others
give you an extra peace of mind, like hitting the "SAVE" button
in a video game before trying a particularly difficult sequence,
knowing that if something goes wrong, you can always go back where
you were.

Kubernetes makes it possible for developers and operation teams
to leverage these techniques, which leads to safer deployments.
If the risk associated with deployments is lower, it means that
you can deploy more often, incrementally, and see more easily
the results of your changes as we implement them; instead of
deploying once a week or month, for instance.

The end result is a higher development velocity, lower time-to-market
for fixes and new features, as well as better availability of your
applications. Which is the whole point of implementing containers
in the first place.
