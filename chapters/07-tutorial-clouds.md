\newpage

## 4.5 Provisioning Kubernetes



This book will show you how to deploy to Kubernetes hosted on three public cloud providers: Amazon AWS, Google Cloud Platform, and DigitalOcean. With slight modifications, the process will work with any other cloud or Kubernetes instance.

We’ll deploy the application in a three-node Kubernetes cluster. You can pick a different size based on your needs, but you’ll need at least three nodes to run an effective canary deployment with rolling updates.

### 4.5.1 DigitalOcean Cluster

DigitalOcean provides everything needed to deploy the application: a managed Kubernetes, a Container Registry, and Postgres databases.

To create the Kubernetes cluster:

  - Sign up or log in to your account on [digitalocean.com](https://www.digitalocean.com).
  - Create a *New Project*.
  - Create a *Kubernetes* cluster: select the latest version and choose one of the available regions. Name your cluster “semaphore-demo-cicd-kubernetes”.
  -  While DigitalOcean is working on the cluster, go to the *API* menu and generate a *Personal Access Token* with Read & Write permissions.

Next, create a Container Registry with the following actions:

- Go to *Container Registry*.
- Click *Create*.
- Set the registry name. Names are unique across all DigitalOcean customers.
- Select the *Starter* free plan.

On Semaphore, store the DigitalOcean Access Token as a secret:

1.  Log in to your organization on [id.semaphoreci.com](https://id.semaphoreci.com).
2.  In the sidebar on the left-hand side, under *Configuration*, select *Secrets* and click on the *Create New Secret* button.
3.  The name of the secret is “do-key”.
4.  Add the `DO_ACCESS_TOKEN` variable and set its value with your personal token.
5.  Click on *Save Secret*.

### 4.5.2 Google Cloud Cluster

Google Cloud calls its service *Kubernetes Engine*. To create the services:

  - Sign up or log in to your Google Cloud account on [cloud.google.com](https://cloud.google.com).
  - Create a *New Project*. In *Project ID* type “semaphore-demo-cicd-kubernetes”.
  - Go to *Kubernetes Engine* \> *Clusters* and enable the service. Create a public **autopilot** cluster in one of the available zones.
  - Name your cluster “semaphore-demo-cicd-kubernetes”.
  - Go to *IAM* \> *Service Accounts*.
  - Generate an account Basic > Owner role.
  - Click on the menu for the new roles, select *Manage Keys* > *Add Keys*.
  - Generate and download a **JSON** Access Key file.

On Semaphore, create a secret for your Google Cloud Access Key file:

1.  Log in to your organization on [id.semaphoreci.com](https://id.semaphoreci.com).
2.  Open your account menu and click on Settings. Go to *Secrets* > *New Secret*.
3.  Name the secret “gcp-key”.
4.  Add this file: `/home/semaphore/gcp-key.json` and upload the Google Cloud Access JSON from your computer.
5.  Click on *Save Secret*.

### 4.5.3 AWS Cluster

AWS calls its service *Elastic Kubernetes Service* (EKS). The Docker private registry is called *Elastic Container Registry* (ECR).

Creating a cluster on AWS is, unequivocally, a complex affair. So tough that there is a specialized tool for it:

  - Sign up or log in to your AWS account at [aws.amazon.com](https://aws.amazon.com).
  - Select one of the available regions.
  - Find and go to the *ECR* service. Create a new private repository called “semaphore-demo-cicd-kubernetes” and copy its address.
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
6.  Click on *Save Secret*.

## 4.6 Provisioning a Database

We’ll need a database to store data. For that, we’ll use a managed PostgreSQL service.

### 4.6.1 DigitalOcean Database

  - Go to *Databases*.
  - Create a PostgreSQL database. Select the same region where the cluster is running.
  - Once the database is ready, go to the *Users & Databases* tab and create a database called “demo” and a user named “demouser”.
  - In the *Overview* tab, take note of the PostgreSQL IP address and port.

### 4.6.2 Google Cloud Database

  - Select *SQL* on the console menu.
  - Create a new **PostgreSQL** database instance.
  - Select the same region and zone where the Kubernetes cluster is running.
  - Open the *Customize your instance* section.
  - Enable the *Private IP* network with the default options and an automatically allocated IP range.
  - Create the instance.

Once the cloud database is running:

  - Open the left-side menu and select *Users*. Create a new built-in user called “demouser”.
  - Go to the *Databases* and create a new DB called “demo”.
  - In the *Overview* tab (you can skip the getting started part), take note of the database IP address and port.

### 4.6.3 AWS Database

  - Find the service called *RDS*.
  - Create a PostgreSQL database (choose Standard Create) and call it “demo”. Type in a secure password for the `postgres` account.
  - Select one of the available *templates*. The dev/test option is perfect for demoing the application. Under *Connectivity* select all the VPCs and subnets where the cluster is running (they should have appeared in eksctl’s output).
  - In Availability Zone, select the same region the Kubernetes cluster is running.
  - Under *Connectivity & Security*, take note of the endpoint address
    and port.

### 4.6.4 Creating the Database Secret on Semaphore

The database secret is the same for all clouds. Create a secret to store the database credentials:

1.  Log in to your organization on [id.semaphoreci.com](https://id.semaphoreci.com).
2.  On the main page, under *Configuration* select *Secrets* and click on the *Create New Secret* button.
3.  The secret name is “db-params”.
4.  Add the following variables:
      - `DB_HOST` with the database hostname or private IP.
      - `DB_PORT` points to the database port (default is 5432).
      - `DB_SCHEMA` for AWS should be called “postgres”. For the other clouds, its value should be “demo”.
      - `DB_USER` for the database user.
      - `DB_PASSWORD` with the password.
      - `DB_SSL` should be “true” for DigitalOcean. It can be left empty for the rest.
5.  Click on *Save Secret*.


