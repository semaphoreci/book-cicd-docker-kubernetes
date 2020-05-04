\newpage

# 4 Implementing a CI/CD Pipeline

Going to a restaurant and looking at the menu with all those delicious dishes is undoubtedly fun. But in the end, we have to pick something and eat it—the whole point of going out is to have a nice meal. So far, this book has been like a menu, showing you all the possibilities and their ingredients. In this chapter, you are ready to order. *Bon appétit*.

Our goal is to get an application running on Kubernetes using CI/CD best practices.

![High Level Flow](./figures/05-high-level-steps.png){ width=95% }

Our process will include the following steps:

- **Build**: Package the application into a Docker image.

- **Run end-to-end tests**: Run end-to-end tests inside the image.

- **Canary deploy**: Deploy the image as a canary to a fraction of the users.

- **Run functional tests**: Verify the canary in production to decide if we should go ahead.

- **Deploy**: If the canary passes the test, deploy the image to all users.

- **Rollback**: If it fails, undo all changes, so we can fix a problem and try again later.

## 4.1 Docker and Kubernetes Commands

In previous chapters we’ve learned most of the Docker and Kubernetes commands that we’ll need in this chapter. Here are a few that we haven’t seen yet.

### 4.1.1 Docker Commands

A Docker *registry* stores Docker images. Docker CLI provides the following commands for managing images:

- `push` and `pull`: these commands work like in Git. We can use them to transfer images to and from the registry.

- `login`: we need to log in before we can push images. Takes a username, password, and an optional registry URL.

- `build`: creates a custom image from a `Dockerfile`.

- `tag`: renames an image or changes its tag.

- `exec`: starts a process in an already-running container. Compare it with `docker run` which starts a new container instead.

### 4.1.2 Kubectl Commands

*Kubectl* is the primary admin CLI for Kubernetes. We’ll use the following commands during deployments:

- `get service`: in chapter 2, we learned about services in Kubernetes; this shows what services are running in a cluster. For instance, we can check the status and external IP of a load balancer.

- `get events`: shows recent cluster events.

- `describe`: shows detailed information about services, deployments, nodes, and pods.

- `logs`: dumps a container’s stdout messages.

- `apply`: starts a declarative deployment. Kubernetes compares the current and target states and takes the necessary steps to reconcile them.

- `rollout status`: shows the deployment progress and waits until the deployment finishes.

- `exec`: works like `docker exec`, executes a command in an already-running pod.

- `delete`: stops and removes pods, deployments, and services.

## 4.2 Setting Up The Demo Project

It’s time to put the book down and get our hands busy for a few minutes. In this section, you’ll fork a demo repository and install some tools.

### 4.2.1 Install Prerequisites

You’ll need to the following tools installed on your computer:

- **git** (_[https://git-scm.com](https://git-scm.com)_) to manage the code.

- **docker** (_[https://www.docker.com](https://www.docker.com)_) to run containers.

- **kubectl** (_[https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)_) to control the Kubernetes cluster.

- **curl** (_[https://curl.haxx.se](https://curl.haxx.se)_) to test the application.

### 4.2.2 Download The Git Repository

We have prepared a demo project on GitHub with everything that you’ll need to set up a CI/CD pipeline:

- Visit _[https://github.com/semaphoreci-demos/semaphore-demo-cicd-kubernetes](https://github.com/semaphoreci-demos/semaphore-demo-cicd-kubernetes)_

- Click on the *Fork* button.

- Click on the *Clone or download* button and copy the URL.

- Clone the Git repository to your computer: `git clone YOUR_REPOSITORY_URL`.

The repository contains a microservice called “addressbook” that exposes a few API endpoints. It runs on Node.js and PostgreSQL.

You will see the following directories and files:

  - `.semaphore`: a directory with the CI/CD pipeline.
  - `docker-compose.yml`: Docker Compose file for the development environment.
  - `Dockerfile`: build file for Docker.
  - `manifests`: Kubernetes manifests.
  - `package.json`: the Node.js project file.
  - `src`: the microservice code and tests.

### 4.2.3 Running The Microservice Locally

Use `docker-compose` to start a development environment:

``` bash
$ docker-compose up --build
```

Docker Compose builds and runs the container image as required. It also downloads and starts a PostgreSQL database for you.

The included `Dockerfile` builds a container image from an official Node.js image:

``` dockerfile
FROM node:12.16.1-alpine3.10

ENV APP_USER node
ENV APP_HOME /app

RUN mkdir -p $APP_HOME && chown -R $APP_USER:$APP_USER $APP_HOME

USER $APP_USER
WORKDIR $APP_HOME

COPY package*.json .jshintrc $APP_HOME/
RUN npm install

COPY src $APP_HOME/src/

EXPOSE 3000
CMD ["node", "src/app.js"]
```

Based on this configuration, Docker performs the following steps:

- Pull the Node.js image.
- Copy the application files.
- Run `npm` inside the container to install the libraries.
- Set the starting command to serve on port 3000.

To verify that the microservice is running correctly, run the following command to create a new record:

``` bash
$ curl -w "\n" -X PUT -d "firstName=al&lastName=pacino" localhost:3000/person
{"id":1,"firstName":"al","lastName":"pacino", \
  "updatedAt":"2020-03-27T10:59:09.987Z", \
  "createdAt":"2020-03-27T10:59:09.987Z"}
```

To list all records:

``` bash
$ curl -w "\n" localhost:3000/all
[{"id":1,"firstName":"al","lastName":"pacino", \
  "createdAt":"2020-03-27T10:59:09.987Z", \
  "updatedAt":"2020-03-27T10:59:09.987Z"}]
```


### 4.2.4 Reviewing Kubernetes Manifests

In chapter 3, we learned that Kubernetes is a declarative system: instead of telling it what to do, we state what we want and trust it knows how to get there.

The `manifests` directory contains all the Kubernetes manifest files.

`service.yml` describes the LoadBalancer service. Forwards traffic from port 80 (HTTP) to port 3000.

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: addressbook-lb
spec:
  selector:
    app: addressbook
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3000
```

`deployment.yml` describes deployment. The directory also contains some AWS-specific manifests.

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $deployment
spec:
  replicas: $replicas
  selector:
    matchLabels:
      app: addressbook
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: addressbook
        deployment: $deployment
    spec:
      containers:
        - name: addressbook
          image: $img
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
          env:
            - name: NODE_ENV
              value: "production"
            - name: PORT
              value: "$PORT"
            - name: DB_SCHEMA
              value: "$DB_SCHEMA"
            - name: DB_USER
              value: "$DB_USER"
            - name: DB_PASSWORD
              value: "$DB_PASSWORD"
            - name: DB_HOST
              value: "$DB_HOST"
            - name: DB_PORT
              value: "$DB_PORT"
            - name: DB_SSL
              value: "$DB_SSL"
```

The deployment manifest combines several Kubernetes concepts we’ve discussed in chapter 3:

1.  A deployment called “addressbook” with rolling updates.
2.  Labels for the pods manage traffic and identify release channels.
3.  Environment variables for the containers in the pod.
4.  A readiness probe to detect when the pod is ready to accept connections.

Note that we’re using dollar ($) variables in the file. This gives us some flexibility to reuse the same manifest for deploying to multiple environments.

## 4.3 Overview of the CI/CD Workflow

A good CI/CD workflow takes planning as there are many moving parts: building, testing, and safely deploying code.

### 4.3.1 CI Pipeline: Building a Docker Image and Running Tests

Our CI/CD workflow begins with the mandatory continuous integration pipeline:

![Continuous Integration Flow](./figures/05-flow-docker-build.png)

The CI pipeline performs the following steps:

- **Git checkout**: Get the latest source code.

- **Docker pull**: Get the latest available application image, if it exists, from the CI Docker registry. This optional step decreases the build time in the following step.

- **Docker build**: Create a Docker image.

- **Test**: Start the container and run tests inside.

- **Docker push**: If all test pass, push the accepted image to the production registry.

In this process, we'll use Semaphore’s built-in Docker registry. This is faster and cheaper than using a registry from a cloud vendor to work with containers in the CI/CD context.

### 4.3.2 CD Pipelines: Canary and Stable Deployments

In chapter 3, we have talked about Continuous Delivery and Continuous Deployment. In chapter 2, we learned about canaries and rolling deployments. Our CI/CD workflow combines these two practices.

A canary deployment is a limited release of a new version. We’ll call it _canary release_, and the previous version that is still used by a majority of users the _stable release_.

We can do a canary deployment by connecting the canary pods to the same load balancer as the rest of the pods. As a result, a set fraction of user traffic goes to the canary. For example, if we have nine stable pods and one canary pod, 10% of the users would get the canary release.

![Canary release flow](./figures/05-flow-canary-deployment.png)

The canary release performs the following steps:

- **Copy** the image from the Semaphore registry to the production registry.
- **Canary deploy** a canary pod.
- **Test** the canary pod to ensure it’s working by running automate functional tests. We may optionally also perform manual QA.
- **Stable release**: if test passes, update the rest of the pods.

Let’s take a closer look at how the stable release works.

Imagine that this is your initial state: you have three pods running version **v1**.

![Stable release via rolling update](./figures/05-transition-canary.png)

When you deploy **v2** as a canary, you scale down the number of **v1** pods to 2, to keep the total amount of pods to 3.

Then, you can start a rolling update to version **v2** on the stable deployment. One at a time, all its pods are updated and restarted, until they are all running on **v2** and you can get rid of the canary.

![Completing a stable release](./figures/05-transition-stable.png)
