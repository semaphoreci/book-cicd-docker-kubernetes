# Chapter 5

## Introduction

*What we want to achieve in this chapter. Briefly describe demo and how
are we going to deploy it* *Introduce what we want want to achieve in
this chapter. High-level overview of the deployment workflow*

![High Level Flow](./figures/05-high-level-steps.png){ width=70% }

## Kubernetes & Docker

*Overview of the Docker and Kubectl commands we’ll need, review commands
that were not yet mentioned or explained in previous chapters. Show
manifests and Dockerfiles when appropiate*

*Docker*

  - docker login

  - docker build

<!-- end list -->

  - docker tag

  - docker push

  - docker pull

*Kubernetes*

*Briefly explain the not-yet-seen kubectl commands we’re going to use*

  - kubectl get service

<!-- end list -->

  - kubectl apply

<!-- end list -->

  - kubectl rollout status

## Kubernetes on the Cloud

*Introduce the Cloud options we’ll be discussing in this tutorial: AWS,
DO, GCP.*

*Explain what services the reader will need to provision on their cloud
of choice: postgres and cluster.*

## Setting up CI/CD

*Fork, clone and initialize the project in Semaphore*

*Review prerequisites and tools: Semaphore, GitHub, Git, Curl, kubectl,
etc*

### Continuous Integration

*The first pipeline, Dockerize and test, just works. No reader
intervention is required (no secrets, etc). Forking and adding the
project is enough. Instead of showing the pipeline put a flow chart and
briefly explain what it does.*

![CI Pipeline Flowchart](./figures/05-flow-docker-build.png){ width=70% }

*Explain promotions. Instruct reader to open .semaphore.yml" and
uncomment the promotion for their cloud of choice*

### Continuous Deployment - Push and Canary Deployment

*We’ll show mainly the DigitalOcean blocks. Remarking differences with
GCP and AWS when appropiate*

*Explain how we’re going to implement the canary deployment*

*Explain pull-push block.*

*Explain how to create appropiate secret. show variants for GCP and DO*
z *Explain canary deployment block*

*Explain transitions using figures*

![Initial state](./figures/05-stable-stable-v1.png){ width=70% }

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           8m38s
addressbook-stable   2/3     3            2           7s
```

![Canary deployed](./figures/05-stable-canary-1.png){ width=70% }

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-stable   3/3     3            3           17s
```

*Explain functional test block*

### Continuous Deployment - Stable Deployment

*at this point there is a manual go-no go decision*

*should we continue with deployment, explains how it works*

*Explain deployment block*

*Explain transitions with figures*

![Stable rolling update 1](./figures/05-stable-canary-2.png){ width=70% }

![Stable rolling update 2](./figures/05-stable-canary-3.png){ width=70% }

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           18m38s
addressbook-stable   3/3     3            3           20m23s
```

![Stable deployment complete](./figures/05-stable-stable-v2.png){ width=70% }

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-stable   3/3     3            3           20m45s

```

## Test App

*instruct reader to push to github and test the API endpoints*

``` bash
$ touch any_file
$ git add any_file
$ git commit -m "first deployment"
$ git push origin master
```

``` bash
$ kubectl get service
NAME             TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
addressbook-lb   LoadBalancer   10.44.6.242   34.68.150.168   80:30478/TCP   35m
kubernetes       ClusterIP      10.44.0.1     <none>          443/TCP        38h

```

``` bash
$ curl -w "\n" -X PUT -d "firstName=Sammy&lastName=the Shark" 34.68.150.168/person
{"id":2,"firstName":"Sammy","lastName":"the Shark","updatedAt":"2019-11-10T16:48:15.900Z","createdAt":"2019-11-10T16:48:15.900Z"}

```

``` bash
$ curl -w "\n" 34.68.150.168/all                                                  
[{"id":1,"firstName":"Sammy","lastName":"the Shark","createdAt":"2019-11-10T16:47:59.504Z","updatedAt":"2019-11-10T16:47:59.504Z"},{"id":2,"firstName":"Sammy","lastName":"the Shark","createdAt":"2019-11-10T16:48:15.900Z","updatedAt":"2019-11-10T16:48:15.900Z"}]
```

## Conclusion

*Final words, recap lessons learned*
