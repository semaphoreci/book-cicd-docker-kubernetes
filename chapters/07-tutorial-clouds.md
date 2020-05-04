\newpage

### 4.5 Provisioning a Kubernetes Cluster

In this book we will show you how to deploy to Kubernetes hosted on three public cloud providers: Amazon AWS, Google Cloud Platform, and DigitalOcean. With small modifications, the process will work with any other cloud or Kubernetes instance.

We’ll deploy the application in a three-node Kubernetes cluster. You can pick a different size based on your needs, but you’ll need at least three nodes to run an effective canary deployment with rolling updates.

#### 4.5.1 DigitalOcean Cluster

DigitalOcean provides a managed Kubernetes service but lacks a private Docker registry[^do-private-reg], so we’ll use Docker Hub for the images.

[^do-private-reg]: At the time of writing, DigitalOcean announced a beta for a private registry offering. For more information, consult the available documentation: _<https://www.digitalocean.com/docs/kubernetes/how-to/set-up-registry>_

  - Sign up for a free account on [hub.docker.com](https://hub.docker.com).
  - Create a public repository called “semaphore-demo-cicd-kubernetes”.

To create the Kubernetes cluster:

  - Sign up or log in to your account on [digitalocean.com](https://www.digitalocean.com).
  - Create a *New Project*.
  - Create a *Kubernetes* cluster: select the latest version and choose one of the available regions. Name your cluster “semaphore-demo-cicd-kubernetes”.
  - Go to the *API* menu and generate a *Personal Access Token*.

On Semaphore, store the DigitalOcean Access Token as a secret:

1.  Log in to your organization on [id.semaphoreci.com](https://id.semaphoreci.com).
2.  In the sidebar on the left-hand side, under *Configuration*, select *Secrets* and click on the *Create New Secret* button.
3.  The name of the secret is “do-key”.
4.  Add the `DO_ACCESS_TOKEN` variable and set its value with your personal token.
5.  Click on *Save changes*.

Repeat the last steps to add the second secret, call it “dockerhub” and add the following variables:

  - `DOCKER_USERNAME` for your DockerHub user name.
  - `DOCKER_PASSWORD` with the corresponding password.

#### 4.5.2 Google Cloud Cluster

Google Cloud calls its service *Kubernetes Engine*. To create the services:

  - Sign up or log in to your Google Cloud account on [cloud.google.com](https://cloud.google.com).
  - Create a *New Project*. In *Project ID* type “semaphore-demo-cicd-kubernetes”.
  - Go to *Kubernetes Engine* \> *Clusters* and create a cluster. Select “Zonal” in *Location Type* and select one of the available zones.
  - Name your cluster “semaphore-demo-cicd-kubernetes”.
  - Go to *IAM* \> *Service Accounts*.
  - Generate an account with “Project Owner” permissions.
  - Generate and download a JSON Access Key file.

On Semaphore, create a secret for your Google Cloud Access Key file:

1.  Log in to your organization on [id.semaphoreci.com](https://id.semaphoreci.com).
2.  In the sidebar on the left-hand side, under *Cconfiguration*, select *Secrets* and click on the *Create New Secret* button.
3.  Name the secret “gcp-key”.
4.  Add this file: `/home/semaphore/gcp-key.json` and upload the Google Cloud Access JSON from your computer.
5.  Click on *Save changes*.

#### 4.5.3 AWS Cluster

AWS calls its service *Elastic Kubernetes Service* (EKS). The Docker private registry is called *Elastic Container Registry* (ECR).

Creating a cluster on AWS is, unequivocally, a complex affair. So complex that there is a specialized tool for it:

  - Sign up or log in to your AWS account at [aws.amazon.com](https://aws.amazon.com).
  - Select one of the available regions.
  - Find and go to the *ECR* service. Create a new repository called “semaphore-demo-cicd-kubernetes” and copy its address.
  - Install *eksctl* from `eksctl.io` and *awscli* from `aws.amazon.com/cli` in your machine.
  - Find the *IAM* console in AWS and create a user with Administrator permissions. Get its *Access Key Id* and *Secret Access Key* values.

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

Once it finishes, eksctl should have created a kubeconfig file at `$HOME/.kube/config`. Check the output from eksctl for more details.

On Semaphore, create a secret to store the AWS Secret Access Key and the kubeconfig file:

1.  Log in to your organization on [id.semaphoreci.com](https://id.semaphoreci.com).
2.  In the sidebar on the left-hand side, under *Configuration*, select *Secrets* and click on the *Create New Secret* button.
3.  Call the secret “aws-key”.
4.  Add the following variables:
      - `AWS_ACCESS_KEY_ID` should have your AWS Access Key ID string.
      - `AWS_SECRET_ACCESS_KEY` has the AWS Access Secret Key string.
5.  Add the following file:
      - `/home/semaphore/aws-key.yml` and upload the Kubeconfig file created by eksctl earlier.
6.  Click on *Save changes*.

### 4.6 Provisioning a Database

We’ll need a database to store data. For that, we’ll use a managed PostgreSQL service.

#### 4.6.1 DigitalOcean Database

  - Go to *Databases*.
  - Create a PostgreSQL database. Select the same region where the cluster is running.
  - In the *Connectivity* tab, whitelist the `0.0.0.0/0` network[^network-whitelist].
  - Go to the *Users & Databases* tab and create a database called “demo” and a user named “demouser”.
  - In the *Overview* tab, take note of the PostgreSQL IP address and port.

[^network-whitelist]: Later, when everything is working, you can restrict access to the Kubernetes nodes to increase security.

#### 4.6.2 Google Cloud Database

  - Select *SQL* on the console menu.
  - Create a new PostgreSQL database instance.
  - Select the same region and zone where the Kubernetes cluster is running.
  - Enable the *Private IP* network.
  - Go to the *Users* tab and create a new user called “demouser”.
  - Go to the *Databases* tab and create a new DB called “demo”.
  - In the *Overview* tab, take note of the database IP address and port.

#### 4.6.3 AWS Database

  - Find the service called *RDS*.
  - Create a PostgreSQL database called “demo” and type in a secure password.
  - Choose the same region where the cluster is running.
  - Select one of the available *templates*. The free tier is perfect for demoing the application. Under *Connectivity* select all the VPCs and subnets where the cluster is running (they should have appeared in eksctl’s output).
  - Under *Connectivity & Security* take note of the endpoint address
    and port.

#### 4.6.4 Creating the Database Secret on Semaphore

The database secret is the same for all clouds. Create a secret to store the database credentials:

1.  Log in to your organization on [id.semaphoreci.com](https://id.semaphoreci.com).
2.  On the main page, under *Configuration* select *Secrets* and click on the *Create New Secret* button.
3.  The secret name is “db-params”.
4.  Add the following variables:
      - `DB_HOST` with the database hostname or IP.
      - `DB_PORT` points to the database port (default is 5432).
      - `DB_SCHEMA` for AWS should be called “postgres”, for the other clouds its value should be “demo”.
      - `DB_USER` for the database user.
      - `DB_PASSWORD` with the password.
      - `DB_SSL` should be “true” for DigitalOcean, it can be left empty for the rest.
5.  Click on *Save changes*.
