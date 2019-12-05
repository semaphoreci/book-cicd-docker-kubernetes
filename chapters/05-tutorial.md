# 5 Tutorial

When we go to a restaurant, we sit down and get the menu. As fun as it
is to read it, in the end, we have to pick something and eat it—the
whole point of going to a restaurant is to have a nice meal. This book
is like the menu; its purpose is for you to get a real-world application
going in Kubernetes using CI/CD best practices. In this chapter, you
will be able to put in practice all that you’ve learned.

The first step is to build a Docker image, which, following best
practices, will be submitted to a suite of tests. Next, once we are
confident about the release, we’ll do a canary deployment to expose a
portion of the users to the new version. At that point, we’ll have to
decide if we wish to carry on with the deployment or not. We’ll learn
how to go forward and how to go back in case of trouble—all thas without
causing any downtime.

![High Level Flow](./figures/05-high-level-steps.png){ width=70% }

## 5.1 Docker and Kubernetes

We’ve learned most of the Docker and Kubernetes commands we need to get
through this chapter. Here are a few that we haven’t seen yet.

### 5.1.1 Docker Commands

A *Docker repository* is similar to a Git repository; it provides a
place to store Docker images. A fully qualified image name consists of
three parts: the *repository*, the *image name* and the *tag*. The tag
is used to differentiate between versions of the same image. The default
tag is “latest”.

To manage images, Docker provides the following commands:

  - `push` and `pull`: these commands work like Git. We can use them to
    transfer images to and from repositories.

  - `login`: takes a username, password, and an optional URL. This
    command is required to push images and to get access to private
    repositories. We don’t need to login to pull from public
    repositories.

  - `build`: creates a custom Docker image from a Dockerfile.

  - `tag`: renames a Docker image.

  - `exec`: starts a process in an already-running container. Compare it
    with `docker run` which starts a new container instead.

### 5.1.2 Kubectl Commands

*Kubectl* is the primary administration mechanism in Kubernetes. By
default, the tool looks for its configuration file in
`$HOME/.kube/config`, although we can override it with the `KUBECONFIG`
environment variable or with the `--kubeconfig` switch.

We’ll use the following kubectl commands during deployments:

  - `get service`: in chapter 2, we learned about services. This command
    shows what services are running in the cluster. For instance, we can
    check the status and external IP of the Load Balancer.

  - `apply`: starts a declarative deployment. The command takes a
    manifest file and instructs the cluster to start the reconciliation
    process. Kubernetes will take the necessary steps to get to the
    desired state.

  - `rollout status`: shows the deployment progress. We can use this
    command to wait until the deployment finishes.

  - `exec`: similar to `docker exec`, this command runs a command in one
    already-running container in a specified pod.

  - `delete`: stops and deletes a deployment, a service or a pod.

## 5.2 Setting Up the Project

It’s time to put the book down and get our hands busy for a few minutes.
In this section, you’ll fork the demo repository and install some tools.

### 5.2.1 Install Prerequisites

We’ll need to the following tools installed in the workstation:

  - **git** (`git-scm.com`) to manage the code.
  - **kubectl** (`kubernetes.io`) to control the cluster.
  - **curl** (`curl.haxx.se`) to test the application.
  - **docker** (`docker.com`) if you wish to run the application
    locally.

Next, go to `https://semaphoreci.com` and sign up with your GitHub
account.

Install the Semaphore CLI on Linux or MacOS with:

``` bash
$ curl https://storage.googleapis.com/sem-cli-releases/get.sh | bash
```

To complete the setup, connect to the Semaphore account using:

``` bash
$ sem connect ORGANIZATION.semaphoreci.com ACCESS_TOKEN
```

The organization and token can be found by invoking the CLI widget in
the top-right corner of any screen on Semaphore.

### 5.2.1 Fork the Repository

We have prepared a demo repository on GitHub with everything that you’ll
need. The demo is located at:

`https://github.com/semaphoreci-demos/semaphore-demo-cicd-kubernetes`

Get yourself a copy of the code by clicking on the *Fork* button. Click
on the *Clone or download* button and copy the URL. Clone the repository
to the workstation with Git:

``` bash
$ git clone YOUR_REPOSITORY_URL
```

The project includes the application, Docker, Kubernetes, and CI/CD
files to test and deploy to Kubernetes:

  - .semaphore: the CI/CD pipeline files
  - docker-compose.yml: compose file to start a dev environment.
  - Dockerfile: build file for Docker.
  - manifests: Kubernetes manifests.
  - package.json: node.js project file.
  - src: application code and tests.

The application is written in JavaScript and is called “addressbook”.
It’s micro-service with a few API endpoints to store contact info on a
PostgreSQL database.

### 5.2.2 Dockerfile and Compose

The included Dockerfile builds an image from an official Node.js image.
It copies the application files and runs `npm` inside the container to
install the libraries. When the container is started, a Node.js server
process starts listening on port 3000.

``` dockerfile
FROM node:10.16.0-alpine

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY .nvmrc .jshintrc $APP_HOME/
COPY package*.json $APP_HOME/
RUN npm install

RUN mkdir ./src
COPY src $APP_HOME/src/

EXPOSE 3000
CMD [ "npm", "run", "start" ]
```

To run a development image locally, you can use `docker-compose`:

``` bash
$ docker-compose up --build
```

Docker Compose will build and run the image as required. It will also
download and start a PostgreSQL database for us.

### 5.2.3 Kubernetes Manifests

In chapter 3, we learned why Kubernetes is a declarative system. Instead
of telling it what to do, we state what we want and trust it knows how
to get there. The repository includes all the manifests we’ll need in
the `manifests` directory.

The `service.yml` manifest describes a *LoadBalancer* **service**. It
forwards traffic from port 80 (HTTP) to port 3000 (where the app is
listening). The service connects itself with the pods labeled as `app:
addressbook`.

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

The `deployment.yml` file describes the **deployment**:

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
            - name: DB_USER
              value: "$DB_USER"
            - name: DB_PASSWORD
              value: "$DB_PASSWORD"
. . .
```

The file combines many of the Kubernetes concepts we’ve discussed in
chapter 3, namely:

1.  A deployment called “addressbook” with rolling updates.
2.  Labels for the pods manage traffic and identify release channels.
3.  Environment variables for the containers in the pod.
4.  A readiness probe to know when the pod is ready to accept
    connections.

Note that we’re using dollar ($) variables in the file. This gives us
some flexibility and allows us to reuse it the same manifest for several
deployments.

## 5.3 Planning the Deployment

How are we going to build, test, and deploy the application?

### 5.3.1 Building and Testing

**How do we build and test the image?** The first step is to build the
image. Semaphore provides a private Docker registry that is fully
integrated into the CI/CD environment. We can use it to store previous
versions of the image and to speed up the build process.

The build job makes the Docker images with `docker build`. Then, it
starts the process and runs some test scripts. If any of these fail, the
workflow stops with an error. If all pass, the image is pushed to the
registry to be reused in future builds.

![CI Flow](./figures/05-flow-docker-build.png){ width=40% }

### 5.3.2 Deployments

In chapter 3, we have talked about Continuous Delivery and Continuous
Deployment. In chapter 2, we learned about canary and rolling
deployments. Our next CI/CD pipeline combines these two practices.

As mentioned before, a canary deployment is a limited release of a newer
version. We’ll call the **new** version the “canary release” and the
**old** version “stable release”.

In Kubernetes, there are multiple ways of doing a canary deployment. The
native method consists of creating a new canary-only deployment and
connecting it to the same load balancer. Thus, a set fraction of user
traffic is sent to the canary. For example, if we have nine stable pods
and one canary pod, about 10% of the users would meet the canary
release.

![Canary Flow](./figures/05-flow-canary-deployment.png){ width=60% }

The Docker image is copied over to the production cloud registry, and
then, using the manifest, the declarative deployment takes place. After
doing that, a functional test takes place to ensure it’s working.

Imagine this is the stable state for our deployment. We have three pods
running the **v1** version:

![Initial state](./figures/05-stable-stable-v1.png){ width=50% }

The **v2** version is released as a canary. To keep the total count of
pods at three, we scale down the stable deployment:

![Canary deployed](./figures/05-stable-canary-1.png){ width=50% }

Finally, we start a rolling update to version **v2** on the stable
deployment. One at a time, its pods are updated and restarted, until
they are all running on **v2**:

![Stable rolling update](./figures/05-stable-canary-2and3.png){ width=100% }

At this point we can get rid off the canary:

![Stable deployment complete](./figures/05-stable-stable-v2.png){ width=50% }

## 5.4 Semaphore Pipelines

We talked about the benefits of CI/CD in chapter 3. Our demo includes a
full-fledged CI and CD pipelines. Open the file from the demo located at
`.semaphore/semaphore.yml` to learn how we can build and test the Docker
image.

A Semaphore pipeline consists of the following elements \[1\]:

**name, version, and agent**: These describe, respectively, the name,
syntax version, and the type of machine that executes the commands.
Semaphore automatically provisions virtual machines\[fn::To see all the
available machines, go to
`https://docs.semaphoreci.com/article/20-machine-types~] to run our
jobs. There are various machines to choose from. For most jobs, we can
use the ~e1-standard-2` (2 CPUs 4 GB RAM) along with an Ubuntu 18.04 OS.

``` yaml
version: v1.0
name: Semaphore CI/CD Kubernetes Demo
```

``` yaml
agent:
  machine:
    type: e1-standard-2
    os_image: ubuntu1804
```

**blocks and jobs**: Blocks and jobs organize the execution flow. Each
block can have one or more jobs. All jobs in a block run in parallel,
each one in an isolated environment. Semaphore waits for all jobs in a
block to pass before starting the next one. Additionally, we can define
environment variables at the block level, and we can import secrets.
We’ll talk about secrets in the next section. Commands in the
*prologue* section are executed before each job in the block. It’s a
convenient place for setup commands.

``` yaml
blocks:
  - name: Docker Build
    task:
      prologue:
        commands:
          - checkout
          - docker login \
              -u $SEMAPHORE_REGISTRY_USERNAME \
              -p $SEMAPHORE_REGISTRY_PASSWORD \
              $SEMAPHORE_REGISTRY_URL
```

The first job builds the Docker image, tags it with the
`$SEMAPHORE_WORKFLOW_ID` unique value (so each image has a distinct
tag), and pushes it to private Semaphore Docker registry.

``` yaml
jobs:
  - name: Build
    commands:
      - docker pull \
          $SEMAPHORE_REGISTRY_URL/addressbook:latest || true
      - docker build \
          --cache-from $SEMAPHORE_REGISTRY_URL/addressbook:latest \
          -t $SEMAPHORE_REGISTRY_URL/addressbook:$SEMAPHORE_WORKFLOW_ID .
      - docker push $SEMAPHORE_REGISTRY_URL/addressbook:$SEMAPHORE_WORKFLOW_ID
```

**promotions**: We can connect pipelines using promotions. These let us
create complex, multi-branch workflows with user-defined conditions. A
promotion can start the deployment automatically if all tests pass, and
the push corresponds to the master branch or is tagged as “hotfix”.

``` yaml
promotions:
  - name: Canary Deployment (DigitalOcean)
    pipeline_file: deploy-canary-digitalocean.yml
    auto_promote:
      when: "result = 'passed' and (branch = 'master' or tag =~ '^hotfix*')"
```

Uncomment the lines corresponding to your cloud of choice and save the
file.

### 5.4.1 Continuous Deployment: Canary

Open one of the following files depending on the cloud you’re using to
review the canary deployment pipeline:

  - AWS: `.semaphore/deploy-canary-aws.yml`
  - GCP: `.semaphore/deploy-canary-gcp.yml`
  - DO: `.semaphore/deploy-canary-digitalocean.yml`

We’ll focus on the DO deployment, but overall the process is the same
for all clouds.

The pipeline consists of 3 blocks: *Push*, *Deploy*, and *Test*.

The “Push” block takes the docker image that we built earlier and
uploads it to a cloud Docker registry. The image must be placed in a
place accessible by the Kubernetes cluster. The block imports a secret
containing the credentials required to login the production Docker
registry:

``` yaml
. . .
- name: Push to Registry
  task:
    secrets:
      - name: dockerhub
. . .
```

The secrets and the login command will vary depending on the cloud we
are deploying. For DigitalOcean, we’re storing the images on Docker Hub.
For AWS, we use their private image service called ECR. Google Cloud
also has a private registry.

The job pulls the image from Semaphore’s registry, tags the image with
its final name, and pushes it to production registry:

``` yaml
. . .
jobs:
  - name: Push
    commands:
      - docker login \
          -u $SEMAPHORE_REGISTRY_USERNAME \
          -p $SEMAPHORE_REGISTRY_PASSWORD \
          $SEMAPHORE_REGISTRY_URL

      - docker pull \
          $SEMAPHORE_REGISTRY_URL/addressbook:$SEMAPHORE_WORKFLOW_ID

      - echo "${DOCKER_PASSWORD}" | \
          docker login -u "${DOCKER_USERNAME}" --password-stdin

      - docker tag \
          $SEMAPHORE_REGISTRY_URL/addressbook:$SEMAPHORE_WORKFLOW_ID \
          $DOCKER_USERNAME/addressbook:$SEMAPHORE_WORKFLOW_ID

      - docker push \
          $DOCKER_USERNAME/addressbook:$SEMAPHORE_WORKFLOW_ID
. . .
```

The “Deploy” block imports two additional secrets: “db-params” with the
DB connection credentials and cloud provides a programmatic access
token. For DO, the secret is called “do-key”. For AWS and GCP, they are
called “aws-key” and “gcp-key” respectively.

``` yaml
. . .
- name: Deploy
  task:
    secrets:
      - name: do-key
      - name: db-params
      - name: dockerhub
. . .
```

Later on, we define some environment variables. These will change
depending on the destination cloud. Check the comments on the file, as
you may need to fill in some values. For instance, GCP reads the region
from `$GCP_PROJECT_DEFAULT_ZONE`, and the AWS pipeline has a similar
value and the address of `ECR_REGISTRY`.

``` yaml
. . .
env_vars:
    - name: CLUSTER_NAME
      value: semaphore-demo-cicd-kubernetes
. . .
```

The prologue installs the cloud management CLI tool and creates an
authenticated session.

``` yaml
. . .
prologue:
  commands:
    - wget https://github.com/digitalocean/../doctl-1.20.0-linux-amd64.tar.gz
    - tar xf doctl-1.20.0-linux-amd64.tar.gz
    - sudo cp doctl /usr/local/bin
    - doctl auth init --access-token $DO_ACCESS_TOKEN
    - doctl kubernetes cluster kubeconfig save "${CLUSTER_NAME}"
    - checkout
. . .
```

The job creates the Load Balancer service with `kubectl apply` and
executes a convenience script that prepares the deployment manifest and
then uses `kubectl apply` and `kubectl rollout status` to perform the
deployment. The parameters of `apply.sh` are `manifest_file`,
`number_of_replicas` and `docker_image_name`.

``` bash
cat $manifest | envsubst | tee deploy.yml
kubectl apply -f deploy.yml
kubectl rollout status -f deploy.yml
```

The final command uses `kubectl scale` to reduce the number of stable
pods from three to two:

``` yaml
. . .
jobs:
  - name: Deploy
    commands:
      - kubectl apply -f manifests/service.yml

      - ./apply.sh manifests/deployment.yml \
           addressbook-canary \
           1 \
           $DOCKER_USERNAME/addressbook:$SEMAPHORE_WORKFLOW_ID

      - if kubectl get deployment addressbook-stable; then \
           kubectl scale --replicas=2 deployment/addressbook-stable; \
        fi
. . .
```

The “Test” block is the last one. It runs some tests on the newly
deployed canary. We use `kubectl get pod` to find the pod name of the
canary deployment, and then `kubectl exec` to run a command inside the
pod’s container. The test script pings the database to check that it is
reachable from the cluster.

Once the test run successfully, the next command runs a database
migration script. If the new version requires some database
modifications, the script will update the database tables accordingly
\[2\].

``` yaml
. . .
jobs:
  - name: Test and migrate db
    commands:
      - kubectl exec -it \
          $(kubectl get pod -l deployment=addressbook-canary -o name | head -n 1) \
          -- npm run ping

      - kubectl exec -it \
          $(kubectl get pod -l deployment=addressbook-canary -o name | head -n 1) \
          -- npm run migrate
. . .
```

### 5.4.2 Continuous Deployment: Stable

So far, so good. Let's see where we are: we built the Docker image, and,
after testing it, we released it as one-pod canary deployment. We still
have two pods running the previous version of the application (unless
this is the first time, in which case there is only a canary running).

The stable deployment pipeline is the last one in the workflow, for
instance, `.sempahore/deploy-stable-digitalocean.yml` This pipeline does
not introduce anything new. We use the `apply.sh` script to start a
rolling update and `kubectl delete` to clean the canary deployment.

``` yaml
. . .
jobs:
  - name: Deploy
    commands:
      - ./apply.sh manifests/deployment.yml \
          addressbook-stable \
          3 \
          $DOCKER_USERNAME/addressbook:$SEMAPHORE_WORKFLOW_ID

      - if kubectl get deployment addressbook-canary; then \
           kubectl delete deployment/addressbook-canary; \
        fi
. . .
```

## 5.5 Preparing the Cloud Services

In this section, we’ll create the Kubernetes cluster and database
service to run the application.

### 5.5.1 Provision a Kubernetes Cluster

In this chapter, we’ll be covering three clouds: Amazon AWS, Google
Cloud Platform (GCP), and DigitalOcean (DO). AWS is the most popular
cloud but likely the most expensive to run Kubernetes in, while
DigitalOcean is the easiest to use. Google Cloud sits comfortably in the
middle.

In this tutorial, we’ll use a three-node Kubernetes cluster; you can
pick a different size, though. You’ll need at least 3 nodes to
effectively run a canary deployment with rolling updates.

**DigitalOcean Cluster**

DO calls its service simply *Kubernetes*. Since DigitalOcean doesn’t
have a private registry\[3\], we’ll use a public Docker Hub repository.

1.  Sign up for an account on `digitalocean.com`.
2.  Create a *New Project*.
3.  Create a *Kubernetes* cluster: select the latest version and choose
    one of the available regions. Name your cluster
    “semaphore-demo-cicd-kubernetes”.
4.  Sign up for a free Docker Hub account in `hub.docker.com` and create
    a public repository called “addressbook”.

Create a secret to store the DigitalOcean Access Token:

``` bash
$ sem create secret do-key -e DO_ACCESS_TOKEN=YOUR_ACCESS_TOKEN
```

And a second secret for the Docker Hub credentials:

``` bash
$ sem create secret dockerhub \
    -e DOCKER_USERNAME=YOUR_DOCKER_USERNAME \
    -e DOCKER_PASSWORD=YOUR_DOCKER_PASSWORD
```

**GCP Cluster**

GCP calls the service *Kubernetes Engine*. Google also offers a private
*Container Registry*, but there is no need to activate it manually.

1.  Sign up for a GCP account on `cloud.google.com`.
2.  Create a *New Project*.
3.  Go to *Kubernetes Engine* \> *Clusters* and create a cluster. Select
    “Zonal” in *Location Type* and select one of the available zones.
    Choose the default Kubernetes version. Name your cluster
    “semaphore-demo-cicd-kubernetes”.

Create a secret for your GCP Access Key file:

``` bash
$ sem create secret gcp-key \
    -f /path/to/your/gcp-access-file.json:/home/semaphore/gcp-key.json
```

**AWS Cluster**

AWS calls its service *Elastic Kubernetes Service* (EKS). The Docker
private registry is called *Elastic Container Registry* (ECR).

Creating a cluster on AWS is, unequivocally, a complex, multi-step
affair. So complex, that a specialized tool was created to automate the
process:

1.  Sign up for an AWS account at `aws.amazon.com`.
2.  Select one of the available regions.
3.  Find and go to the *ECR* service. Create a new repository called
    “addressbook”. Copy the address of the repository: e.g.
    “221701302357.dkr.ecr.us-east-2.amazonaws.com”
4.  Install *eksctl* from `eksctl.io` and *awscli* from
    `aws.amazon.com/cli` in your machine.
5.  Find the IAM console in AWS and create a user with Administrator
    permissions. Get its “Access Key Id” and “Secret Access Key” values.

Sign in to AWS:

``` bash
$ aws configure
AWS Access Key ID: TYPE YOUR ACCESS KEY ID
AWS Secret Access Key: TYPE YOUR SECRET ACCESS KEY
Default region name: TYPE A REGION
```

To create a three-node cluster of the most inexpensive machine type use:

``` bash
$ eksctl create cluster \
    -t t2.nano -N 3 \
    --region YOUR_REGION \
    --name semaphore-demo-cicd-kubernetes
```

**Note**: Select the same region for all AWS services.

Once ready, the cluster should be online, and the kubeconfig file should
have been created on `$HOME/.kube/config`. Check the output from eksctl
for more details.

Create a secret to store the Secret Access Key and the kubeconfig:

``` bash
$ sem create secret aws-key \
    -e AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY \
    -f $HOME/.kube/config:/home/semaphore/aws-key.yml
```

### 5.5.2 Provision a Database

We’ll need a database to store our data. We’ll use one of the managed
PostgreSQL database services offered by the clouds. The only precaution
is that you need to ensure that the database is connected to the same
region, network, and VPC.

**DigitalOcean Database**

1.  Go to *Databases*.
2.  Create a PostgreSQL database.
3.  In the *Connectivity* tab, whitelist the `0.0.0.0/0` network, so the
    database is always reachable. Later, when everything is working, you
    can restrict access to the Kubernetes nodes to increase security.
4.  Go to the *Users & Databases* tab and create a database called
    “demo” and a user named “demouser”.
5.  In the *Overview* tab, take note of the PostgreSQL IP address and
    port.

**GCP Database**

1.  Navigate to the *SQL* menu.
2.  Create a new PostgreSQL database instance.
3.  Select the same region and zone where the Kubernetes cluster is
    running.
4.  Choose the highest PostgreSQL version available.
5.  Enable the *Private IP* networking. If you wish to connect to the DB
    remotely, also enable a *Public IP* networking and whitelist the
    `0.0.0.0/0` network.
6.  Go to the *Users* tab and create a new user called “demouser”
7.  Go to the *Databases* tab and create a new DB called “demo”.
8.  In the *Overview* tab, take note of the database IP address and
    port.

**AWS Database**

1.  Find the service called *RDS*.
2.  Create a PostgreSQL database called “demo” and type in a secure
    password. Select one of the available *templates*. The free tier is
    just perfect for demoing the application. Under *Connectivity*
    select all the VPCs and subnets where the Kubernetes cluster is
    running (they are shown in the eksctl’s output), and select the same
    region where the cluster is running.
3.  Under *Connectivity & Security* take note of the Endpoint address
    and port.

**Create the Database Secret**

The database secret is the same for all clouds. For GCP and DO, the
database user is “demouser”, while for AWS, the user is called
“postgres” instead. Create a secret to store the database
credentials:

``` bash
$ sem create secret db-params \
    -e DB_HOST=YOUR_DB_HOST \
    -e DB_PORT=YOUR_DB_PORT \
    -e DB_SCHEMA=demo \
    -e DB_USER=YOUR_DB_USERNAME \
    -e DB_PASSWORD=YOUR_DB_PASSWORD \
    -e DB_SSL=true or false
```

## 5.6 Your First Deployment

We’ve created all the services and corresponding secrets, we’ve reviewed
all the workflows and pipelines. It’s time to see if all the hard work
we did so far pays off. All that remains is making a push and seeing
Semaphore in action:

``` bash
$ touch any_file
$ git add any_file
$ git add .semaphore
$ git commit -m "first deployment"
$ git push origin master
```

The CI/CD pipelines start automatically, you can check the progress of
the pipeline from your Semaphore account:

![CI Pipeline](./figures/05-sem-ci-pipeline.png){ width=80% }

Since you are on the master branch, if all goes well the canary
deployment pipeline will start automatically:

![Canary Pipeline](./figures/05-sem-canary-pipeline.png){ width=80% }

Once the deployment is complete, the workflow stops and waits for the
manual promotion. Here is where we check how the canary is doing.

Once you have run the whole workflow more than once, you’ll see a stable
deployment with two pods:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           8m22s
```

To check the running pods:

``` bash
$ kubectl get pod
```

### 5.6.1 Stable Release

The level of confidence in the release will be proportional to the
amount of testing the code must have passed. Let’s recap what we did so
far to test the application. First, we did a lot of testing in the CI
pipeline. Then, we released the canary and did run some test scripts on
the live pod.

In tandem with the deployment, we should have a dashboard to monitor
errors, user incidents, and performance metrics to compare against the
baseline. After some pre-determined amount of time, a go vs. no-go would
be taken. Is the canaried version good enough to be promoted to stable?
If so, the deployment continues. If not, after collecting the necessary
error reports and stack traces, we rollback and regroup.

Let’s say we decide to go ahead. So go on and hit that *Promote* button.

![Stable Pipeline](./figures/05-sem-stable-pipeline.png){ width=60% }

The stable pods will start to get upgraded and restarted one at a time
with the new version:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           8m38s
addressbook-stable   2/3     3            2           7s
```

Until we have three replicas:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           18m38s
addressbook-stable   3/3     3            3           20m23s
```

With that completed, the canary is no longer needed, so it goes away:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-stable   3/3     3            3           17s
```

Check the service status to see the external IP:

``` bash
$ kubectl get service
NAME             TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
addressbook-lb   LoadBalancer   10.44.6.242   34.68.150.168   80:30478/TCP   35m
kubernetes       ClusterIP      10.44.0.1     <none>          443/TCP        38h

```

We can use curl to test the API endpoint directly. For example, to
create a person in the addressbook:

``` bash
$ curl -w "\n" -X PUT -d "firstName=Sammy&lastName=David Jr" 34.68.150.168/person
{
    "id": 1,
    "firstName": "Sammy",
    "lastName": "David Jr",
    "updatedAt": "2019-11-10T16:48:15.900Z",
    "createdAt": "2019-11-10T16:48:15.900Z"
}

```

To retrieve all persons, use:

``` bash
$ curl -w "\n" 34.68.150.168/all                                                  
[
    {
        "id": 1,
        "firstName": "Sammy",
        "lastName": "David Jr",
        "updatedAt": "2019-11-10T16:48:15.900Z",
        "createdAt": "2019-11-10T16:48:15.900Z"
    }
]
```

The deployment was a success, that was no small feat. Congratulations\!

### 5.6.2 Troubleshooting

Even the best plans can fail; failure is certainly an option in the
software business. Maybe the canary is presented with some unexpected
errors, perhaps it has performance problems, or we merged the wrong
branch into master. The important thing is (1) learn something from
them, and (2) know how to go back to solid ground.

Kubectl can give us a lot of insights into what is happening. First, get
an overall picture of the resources on the cluster.

``` bash
$ kubectl get all --wide
```

Describe can show detailed information on the pods:

``` bash
$ kubectl describe pod canary-xyz 
```

The deployments:

``` bash
$ kubectl describe deployment addressbook-stable
$ kubectl describe deployment addressbook-canary
```

And the services:

``` bash
$ kubectl describe service addressbook-lb
```

We also see the events logged on the cluster with:

``` bash
$ kubectl get events
```

And the log output of the pods using:

``` bash
$ kubectl get logs addressbook-xyz
$ kubectl get logs --previous addressbook-xyz
```

If we need to jump in one of the containers, we can start a shell as
long as the pod is online with:

``` bash
$ kubectl exec -it canary-xyz -- bash
```

These are some common error messages that you might find when running
the demo:

  - Validation error: usually means that the manifest YAML syntax is
    incorrect. Use `kubectl apply --dry-run --validate -f file.yml` to
    validate the manifest.
  - `ImagePullBackOff` or `ErrImagePull`: the requested image is invalid
    or was not found. Check that the image is in the repository and that
    the reference on the manifest file is correct.
  - `CrashLoopBackOff`: the application is crashing, and the pod is
    shutting down. Check for application errors or missing environment
    variables.
  - Hangs in Pending status: this could mean that one of the Kubernetes
    secrets is missing. The AWS deployment relies on a secret to connect
    to the ECR.
  - Log message says that “container is unhealthy”: this message may
    show that the pod is not passing the readiness probe. Check that the
    probe definition is correct.
  - Log message says that there are “insufficient resources”: this may
    happen if you request too many replicas for the cluster size, or the
    pods use too much memory or CPU.

### 5.6.3 Rolling Back

Fortunately, Kubernetes and CI/CD make an exceptional team when it comes
to recovering from errors. Once you have enough information to diagnose
the problem, remove the failed canary with:

``` bash
$ kubectl delete deployment/addressbook-canary
```

Next, scale up again the stable deployment:

``` bash
$ kubectl get deployments
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           8m38s
addressbook-stable   2/2     2            2           10h20m

$ kubectl scale --replicas=3 deployment/addressbook-stable

$ kubectl get deployments
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           8m38s
addressbook-stable   3/3     3            3           10h22m

```

And we’re back to normal, phew\! Just remember to fix the issue on the
code before pushing into master again.

What if we have deployed all the way to stable, only to discover later
that it had a defect? It can happen, maybe some subtle bug that no one
found out until hours or days after the stable deployment? Can we go
back to a previous version?

The answer is yes—and quickly. Do you remember that we tagged each
Docker image with a unique ID? As long as it is in the Docker registry,
we can simply go back to the last good deployment in Semaphore and hit
its promote button again.

If the Docker image is no longer in the registry, we can just do the
same, but instead of doing a promotion, we can press the *rerun* button
on the top right corner to generate and test the corresponding image.

## 5.7 Summary

You have learned to put the puzzle pieces of CI/CD, Docker, and
Kubernetes together into working application. Each of the pieces has a
role: Docker brings portability, Kubernetes adds orchestration
(resilience), and Semaphore CI/CD joins everything together.

You have put in practice all the concepts introduced in previous
chapters.

  - You have learned how to setup pipelines in Semaphore CI/CD and use
    it to deploy to the cloud.
  - How to build Docker images and start a dev environment with the help
    of Docker Compose.
  - How to do canaried deployments and rolling updates with probes.
  - How to scale deployments and how to recover when things don’t go as
    planned.

## Footnotes

1.  The full pipeline reference can be fount at
    <https://docs.semaphoreci.com/article/50-pipeline-yaml>

2.  Database schema can be tricky. If the new schema is too different,
    the stable version may start failing errors. Our application is dead
    simple, and the chance of conflict is almost non-existent.

3.  At the time of writing, DigitalOcean announced a private registry
    offering. The new service is, however, released as a limited
    availability beta. For more information, consult the available
    documentation:
    <https://www.digitalocean.com/docs/kubernetes/how-to/set-up-registry>
