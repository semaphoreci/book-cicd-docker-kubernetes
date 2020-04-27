## 4.5 Preparing the Cloud Services

Our project supports three clouds: Amazon AWS, Google Cloud Platform
(GCP), and DigitalOcean (DO). AWS is, by far, the most popular, but
likely the most expensive to run Kubernetes. DigitalOcean is the easiest
to use, while Google Cloud sits comfortably in the middle.

### 4.5.1 Provision a Kubernetes Cluster

In this tutorial, we’ll use a three-node Kubernetes cluster; you can
pick a different size, though. You’ll need at least three nodes to run
an effective canary deployment with rolling updates.

**DigitalOcean Cluster**

DO calls its service *Kubernetes*. Since DigitalOcean doesn’t have a
private registry\[9\], we’ll use Docker Hub. To create a registry:

  - Sign up for a free account on `hub.docker.com`.
  - Create a public repository called “semaphore-demo-cicd-kubernetes”

To create the Kubernetes cluster:

  - Sign up for an account on `digitalocean.com`.
  - Create a *New Project*.
  - Create a *Kubernetes* cluster: select the latest version and choose
    one of the available regions. Name your cluster
    “semaphore-demo-cicd-kubernetes”.
  - Go to the *API* menu and generate a *Personal Access Token*.

We have to store the DigitalOcean Access Token in secret:

1.  Login to `semaphoreci.com`.
2.  On the main page, under *Configuration* select *Secrets* and click
    on the *Create New Secret* button.
3.  The name of the secret is “do-key”
4.  Add the following variables:
      - `DO_ACCESS_TOKEN` set its value to your DigitalOcean access
        token.
5.  Click on *Save changes*.

Repeat the last steps to add the second secret, call it “dockerhub” and
add the following variables:

  - `DOCKER_USERNAME` for your DockerHub user name.
  - `DOCKER_PASSWORD` with the corresponding password.

**GCP Cluster**

GCP calls the service *Kubernetes Engine*. To create the services:

  - Sign up for a GCP account on `cloud.google.com`.
  - Create a *New Project*. In *Project ID* type
    “semaphore-demo-cicd-kubernetes”.
  - Go to *Kubernetes Engine* \> *Clusters* and create a cluster. Select
    “Zonal” in *Location Type* and select one of the available zones.
  - Name your cluster “semaphore-demo-cicd-kubernetes”.
  - Go to *IAM* \> *Service Accounts*.
  - Generate an account with “Project Owner” permissions.
  - Generate and download a JSON Access Key file.

Create a secret for your GCP Access Key file:

1.  Login to `semaphoreci.com`.
2.  On the main page, under *Cconfiguration* select *Secrets* and click
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
    “semaphore-demo-cicd-kubernetes” and copy its address.
  - Install *eksctl* from `eksctl.io` and *awscli* from
    `aws.amazon.com/cli` in your machine.
  - Find the *IAM* console in AWS and create a user with Administrator
    permissions. Get its *Access Key Id* and *Secret Access Key* values.

Open a terminal and sign in to AWS:

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
2.  On the main page, under *Configuration* select *Secrets* and click
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

We’ll need a database to store the data. For that, we’ll use a managed
PostgreSQL service.

**DigitalOcean Database**

  - Go to *Databases*.
  - Create a PostgreSQL database. Select the same region where the
    cluster is running.
  - In the *Connectivity* tab, whitelist the `0.0.0.0/0` network\[10\].
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
    VPCs and subnets where the cluster is running (they should have
    appeared in eksctl’s output).
  - Under *Connectivity & Security* take note of the endpoint address
    and port.

**Create the Database Secret**

The database secret is the same for all clouds. Create a secret to store
the database credentials:

1.  Login to `semaphoreci.com`.
2.  On the main page, under *Configuration* select *Secrets* and click
    on the *Create New Secret* button.
3.  The secret name is “db-params”
4.  Add the following variables:
      - `DB_HOST` with the database hostname or IP.
      - `DB_PORT` points to the database port (default is 5432).
      - `DB_SCHEMA` for AWS should be called “postgres”, for the other
        clouds its value should be “demo”.
      - `DB_USER` for the database user.
      - `DB_PASSWORD` should have the corresponding password.
      - `DB_SSL` should be “true” for DigitalOcean, it can be empty for
        the rest.
5.  Click on *Save changes*.

## 4.6 Releasing the Canary

Now that we have our cloud services, we’re ready to deploy the canary
for the first time.

### 4.6.1 Continuous Deployment Pipeline

Our project includes three ready-to-use reference pipelines for deployment. They should work with the secrets as described earlier.

  - AWS: `.semaphore/deploy-canary-aws.yml` and `.semaphore/deploy-stable-aws.yml`
  - GCP: `.semaphore/deploy-canary-gcp.yml` and `.semaphore/deploy-stable-gcp.yml`
  - DO: `.semaphore/deploy-canary-digitalocean.yml` and `.semaphore/deploy-stable-digitalocean.yml`

In this section, we’ll focus on the DO deployment but the process is the same for all
clouds.

Open the Workflow Builder again to create the new pipeline.

Create a new promotion using the **+Add First Promotion** button. Promotions connect pipelines together to create complex workflows. Let’s call it “Canary”

![Create promotion](./figures/05-sem-canary-create-promotion.png)

Check the **Enable automatic promotion** box. Now we can define the following auto-starting conditions for the new pipeline:

```
result = 'passed' and (branch = 'master' or tag =~ '^hotfix*')
```

![Automatic promotion](./figures/05-sem-canary-auto-promotion.png)

Click on the new pipeline and change its name to “Deploy to Kubernetes (DigitalOcean)”.

Click on the first block, we’ll call it “Push to Registry”. The push block takes the docker image that we built earlier and uploads it to Docker Hub. The secrets and the login command will vary depending on the cloud of choice. For DigitalOcean, we’ll use Docker Hub as a repository:

- Open the **Secrets** section and check the `dockerhub` secret.
- Type the following commands in the job:

```bash
docker login -u $SEMAPHORE_REGISTRY_USERNAME -p $SEMAPHORE_REGISTRY_PASSWORD $SEMAPHORE_REGISTRY_URL
docker pull $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID

echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
docker tag $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID $DOCKER_USERNAME/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID
docker push $DOCKER_USERNAME/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID
```

Create the “Deploy” block and enable the `dockerhub` secret. This block also needs two extra secrets: `db-params` and the cloud-specific access token, which is `do-key` in our case.

This job starts the canary deployment:

  - Creates a load balancer service with `kubectl apply`.
  - Executes `apply.sh`, a convenience script for the manifest that
    waits for the deployment to finish.
  - Scales the stable pods down with `kubectl scale`.

Open the **Environment Variables** section and create a variable called `CLUSTER_NAME` with the DigitalOcean cluster name (`semaphore-demo-cicd-kubernetes`).

Next, type the following commands in the **Prologue**:

```bash
wget https://github.com/digitalocean/doctl/releases/download/v1.20.0/doctl-1.20.0-linux-amd64.tar.gz
tar xf doctl-1.20.0-linux-amd64.tar.gz
sudo cp doctl /usr/local/bin
doctl auth init --access-token $DO_ACCESS_TOKEN
doctl kubernetes cluster kubeconfig save "${CLUSTER_NAME}"
checkout
```

The first three lines install DigitalOcean’s `doctl` management tool and the next two lines set up a connection with the cluster.

The prologue installs the cloud management CLI tool and creates an authenticated session. Type the following commands in the job:

```bash
kubectl apply -f manifests/service.yml
./apply.sh manifests/deployment.yml addressbook-canary 1 $DOCKER_USERNAME/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID
if kubectl get deployment addressbook-stable; then kubectl scale --replicas=2 deployment/addressbook-stable; fi
```

Create a third block called “Functional test and migration” and enable the `do-key` secret. Repeat the environment variables and prologue steps from the previous block.

This is the last block in the pipeline. It runs some tests on the canary. By combining `kubectl get pod` and `kubectl exec`, we can run
commands inside the pod.

Type the following commands in the job:

```bash
kubectl exec -it $(kubectl get pod -l deployment=addressbook-canary -o name | head -n 1) -- npm run ping
kubectl exec -it $(kubectl get pod -l deployment=addressbook-canary -o name | head -n 1) -- npm run migrate
```

### 4.6.2 Your First Release

This is the moment of truth. Will the canary work? Click on **Run the workflow** and then **Start**.

![Canary Pipeline](./figures/05-sem-canary-pipeline.png){ width=80% }

Once the deployment is complete, the workflow stops and waits for the manual promotion. Here is where we can check how the canary is doing:

``` bash
$ kubectl get deployment
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
addressbook-canary   1/1     1            1           8m40s
```

## 4.7 Releasing the Stable

So far, so good. Let's see where we are: we built the Docker image, and, after testing it, we released it as one-pod canary deployment. If the canary worked, we’re ready to complete the deployment.

### 4.7.1 The Continuous Deployment Pipeline

The stable deployment pipeline is the last one in the workflow. The pipeline does not introduce anything new. Again, we use `apply.sh`
script to start a rolling update and `kubectl delete` to clean the canary deployment.

Open the Workflow Builder once again and open the canary pipeline. Create a new pipeline branching from the canary and name it “Deploy Stable (DigitalOcean)”.

Create the “Deploy Stable” block with the


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

In tandem with the deployment, we should have a dashboard to monitor
errors, user incidents, and performance metrics to compare against the
baseline. After some pre-determined amount of time, we would reach a go
vs. no-go decision. Is the canaried version good enough to be promoted
to stable? If so, the deployment continues. If not, after collecting the
necessary error reports and stack traces, we rollback and regroup.

Let’s say we decide to go ahead. So go on and hit the *Promote* button.

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
pipeline for the last good version in Semaphore. When the Docker image
is no longer in the registry can just regenerate it using the *Rerun*
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

Each of the pieces had its role: Docker brings portability, Kubernetes
adds orchestration, and Semaphore CI/CD drives the test and deployment
process.

## Footnotes

1.  The full pipeline reference can be fount at
    <https://docs.semaphoreci.com/article/50-pipeline-yaml>

2.  To see all the available machines, go to
    <https://docs.semaphoreci.com/article/20-machine-types>

3.  For more details on the Ubuntu image see:
    <https://docs.semaphoreci.com/article/32-ubuntu-1804-image>

4.  You can find the full toolbox reference here:
    <https://docs.semaphoreci.com/article/54-toolbox-reference>

5.  sem-service can start a lot of popular database engines, for the
    full list check:
    <https://docs.semaphoreci.com/article/132-sem-service-managing-databases-and-services-on-linux>

6.  The full environment reference can be found at
    <https://docs.semaphoreci.com/article/12-environment-variables>

7.  For more details on secrets consult:
    <https://docs.semaphoreci.com/article/66-environment-variables-and-secrets>

8.  For more information on pipelines check
    <https://docs.semaphoreci.com/article/67-deploying-with-promotions>

9.  At the time of writing, DigitalOcean announced a beta for a private
    registry offering. For more information, consult the available
    documentation:
    <https://www.digitalocean.com/docs/kubernetes/how-to/set-up-registry>

10. Later, when everything is working, you can restrict access to the
    Kubernetes nodes to increase security
