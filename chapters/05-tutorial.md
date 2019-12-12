# 4 Tutorial

Going to a restaurant and reading the menu is fun, with all those
delicious dishes and tempting drinks. As enticing as it is to read it,
in the end, we have to pick something and eat it—the whole point of
going out is to have a nice meal.

So far, this book has been like a menu, showing you all the
possibilities and their ingredients. In this chapter, the food is
finally ready.

The goal is to get an application going in Kubernetes using CI/CD best
practices:

![High Level Flow](./figures/05-high-level-steps.png){ width=80% }

  - **Build**: package an application into a Docker image.
  - **End-to-end test**: run end-to-end tests on the image.
  - **Canary**: deploy the image to a part of our users with a canary
    deployment.
  - **Functional test**: verify the canary in production. Decide if we
    should go ahead with the deployment.
  - **Deploy**: if the canary passes the test, deploy the image to all
    users.
  - **Rollback**: if it fails, undo all changes so we can try again
    later.

## 4.1 Docker and Kubernetes

We’ve learned most of the Docker and Kubernetes commands we need to get
through this chapter. Here are a few that we haven’t seen yet.

### 4.1.1 Docker Commands

A *Docker registry* provides a place to store Docker images. The Docker
CLI provides the following commands to manage images:

  - `push` and `pull`: these commands work like Git. We can use them to
    transfer images to and from the registry.

  - `login`: takes a username, password, and an optional registry URL.
    We need to log in before we can push images.

  - `build`: creates a custom Docker image from a Dockerfile.

  - `tag`: renames an image.

  - `exec`: starts a process in an already-running container. Compare it
    with `docker run` which starts a new container instead.

### 4.1.2 Kubectl Commands

*Kubectl* is the primary admin tool for Kubernetes. It looks for its
config file at `$HOME/.kube/config`, although we can override it with
the `KUBECONFIG` variable or with the `--kubeconfig` switch.

We’ll use the following kubectl commands during deployments:

  - `get service`: in chapter 2, we learned about services. This command
    shows what services are running in the cluster. For instance, we can
    check the status and external IP of the Load Balancer.

  - `get events`: retrieves the recent cluster events.

  - `describe`: shows detailed information about a resource; works with
    services, deployments, nodes, and pods.

  - `logs`: dumps a container’s stdout messages.

  - `apply`: starts a declarative deployment. Kubernetes compares the
    expected state with the current state and takes the necessary steps
    to reconcile them.

  - `rollout status`: shows the deployment progress. We can use this
    command to wait until the deployment finishes.

  - `exec`: works like `docker exec`, this command runs a command in one
    already-running container in a specified pod.

  - `delete`: stops and removes a resource in a cluster; works with
    deployments and services.

## 4.2 Setting Up the Project

It’s time to put the book down and get our hands busy for a few minutes.
In this section, you’ll fork the demo repository and install some tools.

### 4.2.1 Install Prerequisites

We’ll need to the following tools installed in the workstation:

  - **git** (`git-scm.com`) to manage the code.
  - **kubectl** (`kubernetes.io`) to control the cluster.
  - **curl** (`curl.haxx.se`) to test the application.
  - **docker** (`docker.com`) to run a dev environment.

### 4.2.2 Create the Semaphore Project

We have prepared a demo repository on GitHub with everything that you’ll
need. Go to:

`https://github.com/semaphoreci-demos/semaphore-demo-cicd-kubernetes`

And get yourself a copy by clicking on the *Fork* button. Click on the
*Clone or download* button and copy the URL. Clone the repository to
your computer:

``` bash
$ git clone YOUR_REPOSITORY_URL
```

The project includes:

  - **.semaphore**: a directory with the CI/CD pipeline files
  - **docker-compose.yml**: compose file to start a dev environment.
  - **Dockerfile**: build file for Docker.
  - **manifests**: Kubernetes manifests.
  - **package.json**: the Node.js project file.
  - **src**: application code and tests.

The application is a microservice called “addressbook” that exposes a
few API endpoints. It runs on Node.js and a PostgreSQL database.

To add your project to Semaphore:

1.  Go to `https://semaphoreci.com`
2.  Sign up with your GitHub account. Once logged in,
3.  Click on the **+ (plus)** sign next to *PROJECTS* to see a list of
    your repositories.
4.  Use the *Choose* button next to “semaphore-demo-cicd-kubernetes”.

### 4.2.3 Dockerfile and Compose

The included Dockerfile builds an image from an official Node.js image:

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

What does this Dockerfile do?

  - Starts from the official Node.js image
  - Copies the application files.
  - Runs `npm` inside the container to install the libraries.
  - Sets the starting command to serve on port 3000.

To run a development image, you can use `docker-compose`:

``` bash
$ docker-compose up --build
```

Docker Compose will build and run the image as required. It will also
download and start a PostgreSQL database for us.

### 4.2.4 Kubernetes Manifests

In chapter 3, we learned why Kubernetes is a declarative system. Instead
of telling it what to do, we state what we want and trust it knows how
to get there.

The `manifests/service.yml` manifest file describes a LoadBalancer
**service**. It forwards traffic from port 80 (HTTP) to port 3000 (where
the app is listening). The service connects itself with the pods labeled
as `app: addressbook`.

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

The `deployment.yml` manifest describes the deployment:

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

This file combines many of the Kubernetes concepts we’ve discussed in
chapter 3:

1.  A deployment called “addressbook” with rolling updates.
2.  Labels for the pods manage traffic and identify release channels.
3.  Environment variables for the containers in the pod.
4.  A readiness probe to know when the pod is ready to accept
    connections.

Note that we’re using dollar ($) variables in the file. This gives us
some flexibility to reuse it the same manifest for several deployments.

## 4.3 Planning CI/CD Workflow

A good CI/CD workflow takes planning as there are a lot of moving parts
and requirements: building, testing, deploying and testing again.

### 4.3.1 Testing the Docker Image

Our CI/CD workflow begins by building the Docker image:

![CI Flow](./figures/05-flow-docker-build.png){ width=70% }

  - **Pull**: get the latest image from the registry. This optional step
    decreases the build time.
  - **Build**: create a Docker image.
  - **Test**: start the application in the container and run tests
    inside.
  - **Push**: if all test pass, push the accepted image to the registry.

### 4.3.2 The Canary and Stable Deployments

In chapter 3, we have talked about Continuous Delivery and Continuous
Deployment. In chapter 2, we learned about canaries and rolling
deployments. Our CI/CD combines these two practices.

As mentioned before, a canary deployment is a limited release of a newer
version. We’ll call the new version the “canary release” and the old
version “stable release”.

We can do a canary deployment by connecting the canary pods to the same
load balancer as the rest of the pods. Thus, a set fraction of user
traffic goes to the canary. For example, if we have nine stable pods and
one canary pod, 10% of the users would get the canary release.

![Canary Flow](./figures/05-flow-canary-deployment.png){ width=70% }

  - **Copy**: the image from the Semaphore registry to the production
    registry.
  - **Canary**: deploy a canary pod.
  - **Test**: run functional tests on the canary pod to ensure it's
    working.
  - **Stable**: if test pass, update the rest of the pods.

Imagine this is the stable state for our application and that we have
three pods running version **v1**.

![Stable rolling update](./figures/05-transition-canary.png){ width=80% }

When we deploy **v2** as a canary, we scale down the number of **v1**
pods to two to keep the total amount of pods to three.

Then, we start a rolling update to version **v2** on the stable
deployment. One at a time, its pods are updated and restarted, until
they are all running on **v2** and we can get rid of the canary.

![Stable deployment complete](./figures/05-transition-stable.png){ width=80% }

## 4.4 Semaphore CI/CD

In this section, we’ll learn how the Semaphore CI/CD Syntax works and
how we can use it to build a Docker image continuously.

### 4.4.1 The Semaphore Syntax

We can completely define the CI/CD environment for our project with
Semaphore Pipelines.

A Semaphore pipeline consists of one or more YAML files that follow the
Semaphore syntax\[1\].

These are some common elements we can find in a pipeline:

**Version**: sets the syntax version of the file; at the time of writing
the only valid value is “v1.0”.

``` yaml
version: v1.0
```

**Name**: gives an optional name to the pipeline.

``` yaml
version: v1.0
name: This is the name of the pipeline
```

**Agent**: the agent is the combination of hardware and software that
runs the jobs. The `machine.type` and `machine.os_image` properties
describe, he virtual machine \[fn::To see all the available machines, go
to `https://docs.semaphoreci.com/article/20-machine-types~] and the
operating system [fn]. The ~e1-standard-2` machine has 2 CPUs and 4 GB
RAM and runs a Ubuntu 18.04 LTS:

``` yaml
agent:
  machine:
    type: e1-standard-2
    os_image: ubuntu1804
```

**Blocks** and **jobs**: define what to do at each step. Each block can
have one or more jobs. All jobs in a block run in parallel, each one in
an isolated environment. Semaphore waits for all jobs in a block to pass
before starting the next one.

This is how a block with two jobs looks like:

``` yaml
blocks:
  - name: The block name
    task:
      jobs:
        - name: The Job name
          commands:
            - command 1
            - command 2
        - name: Another Job
          commands:
            - command 1
            - command 2
```

Commands in the **prologue** section are executed before each job in the
block; it’s a convenient place for setup commands:

``` yaml
prologue:
    commands:
    - checkout
    - cache restore
```

The Ubuntu OS chosen earlier comes with a bunch of convenience scripts
and tools \[2\]. We'll use these:

  - **checkout**: clones the Git repository at the proper code revision
    and \~cd\~s into the directory.
  - **sem-service**: starts an empty database for testing\[3\].

**Environment variables**: can be defined at the block level. They
remain set for all its jobs:

``` yaml
env_vars:
    - name: MY_ENV_1
      value: foo
    - name: MY_ENV_2
      value: bar
```

When a job starts, Semaphore preloads some special variables\[4\]. One
of these is called `SEMAPHORE_WORKFLOW_ID` and we'll use it, later on,
to tag our images with a unique ID.

Also, blocks can have **secrets**. Secrets contain sensitive information
that we can’t have in a Git repository. Secrets import environment
variables and files into the job\[5\]:

``` yaml
secrets:
    - name: secret-1
    - name: secret-2
```

**promotions**: Semaphore always executes first the pipeline found at
`.semaphore/semaphore.yml`. We can have multi-stage, multi-branching
workflows by connecting pipelines together with promotions. Promotions
can be started manually or by user-defined conditions\[6\].

``` yaml
promotions:
  - name: A manual promotion
    pipeline_file: pipeline-file-1.yml
  - name: An automated promotion
    pipeline_file: pipeline-file-2.yml
    auto_promote:
      when: "result = 'passed'"
```

### 4.4.2 The Continous Integration Pipeline

We talked about the benefits of CI/CD in chapter 3. Our demo includes a
full-fledged CI pipeline. Open the file from the demo located at
`.semaphore/semaphore.yml` to learn how we can build and test the Docker
image.

We’ve talked about pipeline basics above, so let’s jump directly to the
first block:

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

The first block:

  - Builds the Docker image
  - Tags it with `$SEMAPHORE_WORKFLOW_ID` so each has a distinct ID.
  - Pushes it to the Semaphore Registry.

<!-- end list -->

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

The second block:

  - Pulls the recently create image from the registry.
  - Runs integration and end-to-end tests.

The last block repeats the pattern:

  - Pulls the image created on the first block.
  - Tags it as “latest” and pushes it again to the registry for future
    runs.

The last section of the file defines the promotion. Uncomment the lines
corresponding to your cloud of choice and save the file. These
promotions are triggered when the Git branch is master or when the
commit tag begins with “hotfix”.

``` yaml
promotions:
  - name: Canary Deployment (DigitalOcean)
    pipeline_file: deploy-canary-digitalocean.yml
    auto_promote:
      when: "result = 'passed' and (branch = 'master' or tag =~ '^hotfix*')"
```

### 4.4.3 Your First Run

We’ve covered a lot of things in a few pages, here we have the change to
pause for a little bit and do an initial run of the CI pipeline.

You can avoid running the deployment pipeline by pushing into a
non-master branch:

``` bash
$ git branch test-integration
$ git checkout test-integration
$ touch any-file
$ git add any-file
$ git commit -m "run integration pipeline for the first time"
$ git push origin test-integration
```

Check the progress of the pipeline from the Semaphore website:

![CI Pipeline](./figures/05-sem-ci-pipeline.png){ width=80% }

## 4.5 Preparing the Cloud Services

Our project supports three clouds: Amazon AWS, Google Cloud Platform
(GCP), and DigitalOcean (DO). AWS is, by far, the most popular, but
likely the most expensive to run Kubernetes in. DigitalOcean is the
easiest to use, while Google Cloud sits comfortably in the middle.

### 4.5.1 Provision a Kubernetes Cluster

In this tutorial, we’ll use a three-node Kubernetes cluster; you can
pick a different size, though. You’ll need at least three nodes to run
an effective canary deployment with rolling updates.

**DigitalOcean Cluster**

DO calls its service *Kubernetes*. Since DigitalOcean doesn’t have a
private registry\[7\], we’ll use a public Docker Hub registry:

  - Sign up for a free account on `hub.docker.com`.
  - Create a public repository called “addressbook”

To create the Kubernetes cluster:

  - Sign up for an account on `digitalocean.com`.
  - Create a *New Project*.
  - Create a *Kubernetes* cluster: select the latest version and choose
    one of the available regions. Name your cluster
    “semaphore-demo-cicd-kubernetes”.

We have to store the DigitalOcean Access Token in secret:

1.  Login to `semaphoreci.com`.
2.  On the main page, under *CONFIGURATION* select *Secrets* and click
    on the *Create New Secret* button.
3.  The name of the secret is “do-key”
4.  Add the following variables:
      - `DO_ACCESS_TOKEN` set its value to your DigitalOcean access
        token.
5.  Click on *Save changes*.

Repeat the operation to add the second secret for the Docker Hub
credentials, call it “dockerhub” and add the following variables:

  - `DOCKER_USERNAME` set your DockerHub user name.
  - `DOCKER_PASSWORD` has the corresponding password.

**GCP Cluster**

GCP calls the service *Kubernetes Engine*. Google also offers a private
*Container Registry*.

  - Sign up for a GCP account on `cloud.google.com`.
  - Create a *New Project* called “semaphore-demo-cicd-kubernetes”.
  - Go to *Kubernetes Engine* \> *Clusters* and create a cluster. Select
    “Zonal” in *Location Type* and select one of the available zones.
  - Name your cluster “semaphore-demo-cicd-kubernetes”.

Create a secret for your GCP Access Key file:

1.  Login to `semaphoreci.com`.
2.  On the main page, under *CONFIGURATION* select *Secrets* and click
    on the *Create New Secret* button.
3.  Name the secret “gcp-key”
4.  Add the following file:
      - `/home/semaphore/gcp-key.json` and upload the GCP Access JSON
        from your computer.
5.  Click on *Save changes*.

**AWS Cluster**

AWS calls its service *Elastic Kubernetes Service* (EKS). The Docker
private registry is called *Elastic Container Registry* (ECR).

Creating a cluster on AWS is, unequivocally, a complex, multi-step
affair. So complex, that they created a specialized tool for it:

  - Sign up for an AWS account at `aws.amazon.com`.
  - Select one of the available regions.
  - Find and go to the *ECR* service. Create a new repository called
    “addressbook” and copy its address.
  - Install *eksctl* from `eksctl.io` and *awscli* from
    `aws.amazon.com/cli` in your machine.
  - Find the IAM console in AWS and create a user with Administrator
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

Once it finishes, eksctl should have created a kubeconfig file at
`$HOME/.kube/config`. Check the output from eksctl for more details.

Create a secret to store the AWS Secret Access Key and the kubeconfig:

1.  Login to `semaphoreci.com`.
2.  On the main page, under *CONFIGURATION* select *Secrets* and click
    on the *Create New Secret* button.
3.  Call the secret “aws-key”
4.  Add the following variables:
      - `AWS_ACCESS_KEY_ID` should have your AWS Access Key ID string.
      - `AWS_SECRET_ACCESS_KEY` has the AWS Access Secret Key string.
5.  Add the following file:
      - `/home/semaphore/aws-key.yml` and upload the Kubeconfig file
        created by eksctl earlier.
6.  Click on *Save changes*.

### 4.5.2 Provision a Database

We’ll need a database to store our data. We’ll use a managed PostgreSQL
service.

**DigitalOcean Database**

  - Go to *Databases*.
  - Create a PostgreSQL database. Select the same region where the
    cluster is running.
  - In the *Connectivity* tab, whitelist the `0.0.0.0/0` network\[8\].
  - Go to the *Users & Databases* tab and create a database called
    “demo” and a user named “demouser”.
  - In the *Overview* tab, take note of the PostgreSQL IP address and
    port.

**GCP Database**

  - Select *SQL* on the console menu.
  - Create a new PostgreSQL database instance.
  - Select the same region and zone where the Kubernetes cluster is
    running.
  - Enable the *Private IP* network.
  - Go to the *Users* tab and create a new user called “demouser”
  - Go to the *Databases* tab and create a new DB called “demo”.
  - In the *Overview* tab, take note of the database IP address and
    port.

**AWS Database**

  - Find the service called *RDS*.
  - Create a PostgreSQL database called “demo” and type in a secure
    password.
  - Choose the same region where the cluster is running.
  - Select one of the available *templates*. The free tier is perfect
    for demoing the application. Under *Connectivity* select all the
    VPCs and subnets where the cluster is running (they appear in
    eksctl’s output).
  - Under *Connectivity & Security* take note of the Endpoint address
    and port.

**Create the Database Secret**

The database secret is the same for all clouds. For GCP and DO, the
database user is “demouser”, while for AWS, the user is called
“postgres” instead. Create a secret to store the database
credentials:

1.  Login to `semaphoreci.com`.
2.  On the main page, under *CONFIGURATION* select *Secrets* and click
    on the *Create New Secret* button.
3.  The secret name is “db-params”
4.  Add the following variables:
      - `DB_HOST` should have the database hostname or IP.
      - `DB_PORT` should point to the database port (default is 5432).
      - `DB_SCHEMA` for AWS should be called “postgres”, for the rest,
        its value should be “demo”.
      - `DB_USER` must have the database user.
      - `DB_PASSWORD` should have the corresponding password.
      - `DB_SSL` should be “true” for DigitalOcean, it can be empty for
        the rest.
5.  Click on *Save changes*.

## 4.6 Releasing the Canary

Now that we have our cloud services, we’re ready to deploy the canary
for the first time.

### 4.6.1 Continuous Deployment Pipeline

Open one of the following files depending on the cloud you’re using to
review the canary deployment pipeline:

  - AWS: `.semaphore/deploy-canary-aws.yml`
  - GCP: `.semaphore/deploy-canary-gcp.yml`
  - DO: `.semaphore/deploy-canary-digitalocean.yml`

We’ll focus on the DO deployment, but the process is the same for all
clouds.

The pipeline consists of three blocks:

**Push**: the push block takes the docker image that we built earlier
and uploads it to a cloud Docker registry. The image must be in a place
that is accessible by the Kubernetes cluster. This block imports a
secret “dockerhub” secret:

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

**Deploy**: this block imports two extra secrets: “db-params” and the
cloud-specific access token.

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

Later on, we define some environment variables that depend on the chosen
cloud. For more details, consult the comments on the corresponding
pipeline files, as you may need to fill in some values.

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

  - Create a load balancer service with `kubectl apply`.
  - Executes `apply.sh`, a convenience script for the manifest that
    waits for the deployment to finish.
  - Scales the stable pods down with `kubectl scale`.

<!-- end list -->

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

**Test**: this is the last block in the pipeline. It runs some tests on
the young canary. Combining `kubectl get pod` and `kubectl exec` we can
run commands inside the pod.

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

### 4.6.2 Your First Release

It’s time to see if all the hard work we did so far pays off. All that
remains is making a push to the master branch:

``` bash
$ git checkout master
$ git add .semaphore
$ git commit -m "first deployment"
$ git push origin master
```

Check the progress of the pipelines on the Semaphore website.

![Canary Pipeline](./figures/05-sem-canary-pipeline.png){ width=80% }

Once the deployment is complete, the workflow stops and waits for the
manual promotion. Here is where we can check how the canary is doing:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           8m40s
```

## 4.7 Releasing the Stable

So far, so good. Let's see where we are: we built the Docker image, and,
after testing it, we released it as one-pod canary deployment. If the
canary worked, we’re ready to complete the deployment.

### 4.7.1 The Continuous Deployment Pipeline

The stable deployment pipeline is the last one in the workflow, for
instance, `.sempahore/deploy-stable-digitalocean.yml` This pipeline does
not introduce anything new. Again we use `apply.sh` script to start a
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

### 4.7.2 Making the Release

The level of confidence in the release will be proportional to the
amount of testing the code must have passed. Our pipeline already did
some tests on the canary.

In tandem with the deployment, we should have a dashboard to monitor
errors, user incidents, and performance metrics to compare against the
baseline. After some pre-determined amount of time, we would reach a go
vs. no-go decision. Is the canaried version good enough to be promoted
to stable? If so, the deployment continues. If not, after collecting the
necessary error reports and stack traces, we rollback and regroup.

Let’s say we decide to go ahead. So go on and hit that *Promote* button.

![Stable Pipeline](./figures/05-sem-stable-pipeline.png){ width=60% }

While the block runs, you should get the existing canary and a new
“addressbook-stable” deployment:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           110s
addressbook-stable   0/3     3            0           1s
```

One at a time, the numbers of replicas should increase until reaching
the target of three:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           114s
addressbook-stable   2/3     3            2           5s
```

With that completed, the canary is no longer needed, so it goes away:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-stable   3/3     3            3           12s
```

Check the service status to see the external IP:

``` bash
$ kubectl get service
NAME             TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
addressbook-lb   LoadBalancer   10.120.14.50   35.225.210.248   80:30479/TCP   2m47s
kubernetes       ClusterIP      10.120.0.1     <none>           443/TCP        49m
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

### 4.7.3 The Rollback Pipeline

Fortunately, Kubernetes and CI/CD make an exceptional team when it comes
to recovering from errors. Our project includes a rollback pipeline.

Let’s say that we don’t like how the canary performs. In that case, we
can click on the *Promote* button on the “Rollback canary” pipeline:

![Rollback Pipeline](./figures/05-sem-rollback-canary.png){ width=60% }

Check the pipeline at `.semaphore/rollback-canary-digitalocean.yml`

The rollback pipeline job is to collect information to diagnose the
problem:

``` yaml
commands:
    - kubectl get all -o wide
    - kubectl get events
    - kubectl describe deployment addressbook-canary || true
    - kubectl logs \
        $(kubectl get pod -l deployment=addressbook-canary -o name | head -n 1) || true

```

And then undo the changes by scaling up the stable deployment and
removing the canary:

``` yaml
- if kubectl get deployment addressbook-stable; then \
    kubectl scale --replicas=3 deployment/addressbook-stable; \
    fi

- if kubectl get deployment addressbook-canary; then \
    kubectl delete deployment/addressbook-canary; \
fi
```

And we’re back to normal, phew\! Now its time to check the job logs to
see what went wrong and fix it before merging to master again.

**But what if the problem is found after the stable release?** Let’s
imagine that a defect sneaked its way into the stable deployment. It can
happen, maybe there was some subtle bug that no one found out hours or
days in. Or perhaps some error not picked up by the functional test. Is
it too late? Can we go back to a previous version?

The answer is yes, we can go to the previous version. Do you remember
that we tagged each Docker image with a unique ID (the
`SEMAPHORE_WORKFLOW_ID`)? We can re-promote the stable deployment
pipeline for the last good version in Semaphore. If the Docker image is
no longer in the registry can just regenerate it using the *Rerun*
button in the top right corner.

### 4.7.2 Troubleshooting and Tips

Even the best plans can fail; failure is certainly an option in the
software business. Maybe the canary is presented with some unexpected
errors, perhaps it has performance problems, or we merged the wrong
branch into master. The important thing is (1) learn something from
them, and (2) know how to go back to solid ground.

Kubectl can give us a lot of insights into what is happening. First, get
an overall picture of the resources on the cluster.

``` bash
$ kubectl get all -o wide
```

Describe can show detailed information of any or all your pods:

``` bash
$ kubectl describe <pod-name>
```

It also works with deployments:

``` bash
$ kubectl describe deployment addressbook-stable
$ kubectl describe deployment addressbook-canary
```

And services:

``` bash
$ kubectl describe service addressbook-lb
```

We also see the events logged on the cluster with:

``` bash
$ kubectl get events
```

And the log output of the pods using:

``` bash
$ kubectl logs <pod-name>
$ kubectl logs --previous <pod-name>
```

If you need to jump in one of the containers, you can start a shell as
long as the pod is running with:

``` bash
$ kubectl exec -it <pod-name> -- bash
```

To access a pod network from your machine, forward a port with
`port-forward`, for instance:

``` bash
$ kubectl port-forward <pod-name> 8080:80
```

These are some common error messages that you might run into:

  - Manifest is invalid: it usually means that the manifest YAML syntax
    is incorrect. Use `--dry-run` or `--validate` options verify the
    manifest.
  - `ImagePullBackOff` or `ErrImagePull`: the requested image is invalid
    or was not found. Check that the image is in the registry and that
    the reference on the manifest file is correct.
  - `CrashLoopBackOff`: the application is crashing, and the pod is
    shutting down. Check the logs for application errors.
  - Pod never leaves `Pending` status: this could mean that one of the
    Kubernetes secrets is missing.
  - Log message says that “container is unhealthy”: this message may
    show that the pod is not passing a probe. Check that the probe
    definitions are correct.
  - Log message says that there are “insufficient resources”: this may
    happen when the cluster is running low on memory or CPU.

## 4.8 Summary

You have learned how to put together the puzzle of CI/CD, Docker, and
Kubernetes into a practical application. In this chapter, you have put
in practice all that you’ve learned in this book:

  - How to setup pipelines in Semaphore CI/CD and use them to deploy to
    the cloud.
  - How to build Docker images and start a dev environment with the help
    of Docker Compose.
  - How to do canaried deployments and rolling updates in Kubernetes.
  - How to scale deployments and how to recover when things don’t go as
    planned.

Each of the pieces has a role: Docker brings portability, Kubernetes
adds orchestration, and Semaphore CI/CD drives the test and deployment
process.

## Footnotes

1.  The full pipeline reference can be fount at
    <https://docs.semaphoreci.com/article/50-pipeline-yaml>

2.  You can find the full toolbox reference here:
    <https://docs.semaphoreci.com/article/54-toolbox-reference>

3.  sem-service can start a lot of popular database engines, for the
    full list check:
    <https://docs.semaphoreci.com/article/132-sem-service-managing-databases-and-services-on-linux>

4.  The full environment reference can be found at
    <https://docs.semaphoreci.com/article/12-environment-variables>

5.  For more details on secrets consult:
    <https://docs.semaphoreci.com/article/66-environment-variables-and-secrets>

6.  For more information on pipelines check
    <https://docs.semaphoreci.com/article/67-deploying-with-promotions>

7.  At the time of writing, DigitalOcean announced a private registry
    offering. The new service is still in beta. For more information,
    consult the available documentation:
    <https://www.digitalocean.com/docs/kubernetes/how-to/set-up-registry>

8.  Later, when everything is working, you can restrict access to the
    Kubernetes nodes to increase security
