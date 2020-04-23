## 4.4 Implementing a CI/CD Pipeline With Semaphore

In this section, we’ll learn about Semaphore and how to use it to build
cloud-based CI/CD pipelines.

### 4.4.1 Introduction to Semaphore

For a long time, engineers looking for a CI/CD tool had to choose between
power and ease of use.

On one hand, there was predominantly Jenkins which can
do just about anything, but is difficult to use and requires companies to
allocate dedicated ops teams to configure, maintain and scale it — along with
the infrastructure on which it runs.
On the other hand, there were several hosted services which let
developers just push their code and not worry about the rest of the process.
However, these services are usually limited to running simple build and test
steps, and would often fall short in need of more elaborate continuous delivery
workflows, which is often the case with containers.

Semaphore (_[https://semaphoreci.com](https://semaphoreci.com)_) started
as one of the simple hosted CI services, but eventually
evolved to support custom continuous delivery pipelines with containers, while
retaining a way of being easy to use by any developer, not just dedicated ops
teams. As such it removes all technical barriers to adopting continuous
delivery at scale:

- It's a cloud-based service: there's no software for you to install and
  maintain.
- It provides a visual interface to model CI/CD workflows quickly.
- It's the fastest CI/CD service, due to being based on dedicated hardware
  instead of common cloud computing services.
- It's free for open source and small private projects.

The key benefit of using Semaphore is increased team productivity.
Since there is there is no need to hire supporting staff or expensive
infrastructure, and it runs CI/CD workflows faster than any other solution,
companies that adopt Semaphore report a very large, 41x ROI comparing to their
previous solution [^roi].

We'll learn about Semaphore's features as we go hands-on in this chapter.

[^roi]: Whitepaper: The 41:1 ROI of Moving CI/CD to Semaphore (_[https://semaphoreci.com/resources/roi](https://semaphoreci.com/resources/roi)_)

### 4.4.1 Creating a Semaphore Account

To get started with Semaphore:

- Go to [https://semaphoreci.com](https://semaphoreci.com) and click to
  sign up with your GitHub account.
- GitHub will ask you to let Semaphore access your profile information.
  Allow this so that Semaphore can create an account for you.
- Semaphore will walk you through the process of creating an organization.
  Since software development is a team sport, all Semaphore projects belong to
  an organization. Your organization will have its own domain, for example
  `awesomecode.semaphoreci.com`.
- Semaphore will ask you to choose between a time-limited free trial
  with unlimited capacity, free plan and open source plan. Since we're going
  to work with an open source repository you can choose the open source option.
- Finally you'll be greeted with a quick product tour.

### 4.4.2 Creating a Semaphore Project For The Demo Repository

We assume that you have previously forked the demo project from
[https://github.com/semaphoreci-demos/semaphore-demo-cicd-kubernetes](https://github.com/semaphoreci-demos/semaphore-demo-cicd-kubernetes)
to your GitHub account.

Follow the prompt to create a project. The first time you do this,
you will see a screen which asks you to choose between connecting Semaphore
to either your public, or both public and private repositories on GitHub:

![Authorizing Semaphore to access your GitHub repositories](./figures/05-github-repo-auth.png)

To keep things simple, select the "Public repositories" option.
If you decide that you want to use Semaphore with your private projects as well,
you can extend the permission at any time.

Next, Semaphore will present you a list of repositories to choose from as the
source of your project:

![Choosing a repository to set up CI/CD for](./figures/05-choose-repo.png)

In the search field, start typing `semaphore-demo-cicd-kubernetes` and choose
that repository.

Semaphore will quickly initialize the project. Behind the scenes, it will
set up everything that's needed to know about every Git push automatically
pull the latest code — without you configuring anything.

The next screen optionally lets you invite your repository collaborators
to join the Semaphore project. Semaphore mirrors access permissions of GitHub,
so if you add some people to the GitHub repository later, you can "sync" them
inside project settings on Semaphore.


TODO: new version begins here
-------------------------------------------------

![Add collaborators](./figures/05-add-collaborators.png)

Click on **Go to Workflow Builder**. Semaphore will ask you if you want to use the existing pipelines or create one from scratch. At this point, you can choose to use the existing configuration to get directly to the final workflow. In this chapter, however, we’ll make a fresh start so we can learn how to create the pipelines.

![Start from scratch or use existing pipeline](./figures/05-existing-pipeline.png)

TBC

### 4.4.3 The Semaphore Workflow Builder

If you chose to start from scratch, Semaphore should be asking you to pick a starter workflow. These are templates that come preloaded with popular languages and frameworks. Choose the Build Docker workflow and click on **Run this Workflow**.

![Choosing a starter workflow](./figures/05-starter-workflow.png)

Semaphore will immediately start the workflow. Wait a few seconds and, congratulations, your first Docker image is ready.

![Starter run](./figures/05-starter-run.png)

Of course, since the image is not stored anywhere yet, it’s lost once the workflow completes. We’ll correct that now.

See the **Edit Workflow** button on the top right corner? Click it to open the Workflow Builder.

![Workflow builder overview](./figures/05-wb-overview.png)

Now it’s a good moment to learn how the Workflow Builder works.

**Pipelines**

Pipelines are represented on the builder as big gray boxes. Pipelines organize the workflow in blocks that are executed from left to right. Each pipeline usually has a specific objective such as test, build, or deploy. Pipelines can be chained together to make a complex workflow.

**Agent**

The agent is the combination of hardware and software that powers the pipeline. The **machine type** determines the amount of CPUs and memory allocated to the virtual machine. The operating system is controlled by the **environment type** and **OS image** settings.

The default machine is called `e1-standard-2` and has 2 CPUs, 4 GB RAM, and runs a custom Ubuntu 18.04 image.

**Jobs and Blocks**

Blocks and jobs define what to do at each step. Jobs define the commands that do the work. A block is a group of jobs with a common objective and shared settings.

Jobs inherit their configuration from their parent block. All the jobs in a block run in parallel, each in its isolated environment. If any of the jobs fails, the pipeline stops with an error.

Blocks run sequentially, once all the jobs in the block complete, the next block starts.


### 4.4.4 The Continous Integration Pipeline

We talked about the benefits of CI/CD in chapter 3. In the previous section, we created our very first pipeline. In this section, we’ll customize it to build, test, and store a Docker image.

At this point, you should be seeing the Workflow Builder with the Docker Build starter workflow. Click on the **Build** block so we can see how it works.

![Build block](./figures/05-build-block.png)

Each line on the job is a command to execute. The first command in the job is `checkout`, which is a built-in script that clones the repository at the correct revision and changes the current directory. The next command, `docker build`, builds the image using the `Dockerfile` pushed to the repository.

When the job ends, the machine in which runs is deleted. We have to push the Docker image to a registry to preserve it.

Replace the contents of the job with the following commands:

```bash
checkout
docker login -u $SEMAPHORE_REGISTRY_USERNAME -p $SEMAPHORE_REGISTRY_PASSWORD $SEMAPHORE_REGISTRY_URL
docker pull $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:latest || true
docker build --cache-from $SEMAPHORE_REGISTRY_URL/seamphore-demo-cicd-kubernetes:latest -t $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID .
docker push $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID
```

This is the sequence:

1. Clones the repository with `checkout`.
2. Logs in the Semaphore private Docker registry.
3. Pulls the Docker image tagged as `latest`.
4. Builds a newer version of the image using the latest code in the revision.
5. Pushes the new image to the registry.

The perceptive reader will note that we used some special environment variables. These are preset by Semaphore automatically in every job. The variables starting with `SEMAPHORE_REGISTRY` are used to access the private registry. `SEMAPHORE_WORKFLOW_ID` is guaranteed to be unique for each workflow run. In our case, we’re using it to tag the resulting Docker image.

We can try the pipeline now. Click on the **Run the workflow** button on the top-right corner and then click on **Start**.

Wait until the pipeline is complete then go to the top level of the project by clicking on its name on the left navigation menu. Click on the **Docker Registry** button. Open the repository to verify that the Docker image is there.

![Docker registry](./figures/05-registry.png)

TODO: end of the new version
-------------------------------------------------


TODO: some of this can be reused
-------------------------------------------------

Commands in the **prologue** section are executed before each job in the
block; it’s a convenient place for setup commands:

``` yaml
prologue:
    commands:
    - checkout
    - cache restore
```

The Ubuntu OS image comes with a bunch of convenience scripts and
tools\[4\]:

  - **checkout**: clones the Git repository at the proper code revision
    and `cd` into the directory.
  - **sem-service**: starts an empty database for testing\[5\].

**Environment variables**: defined at the block level are applied for
all its jobs:

``` yaml
env_vars:
    - name: MY_ENV_1
      value: foo
    - name: MY_ENV_2
      value: bar
```

When a job starts, Semaphore preloads some special variables\[6\]. One
of these is called `$SEMAPHORE_WORKFLOW_ID` and contains a unique string
that is preserved for all pipelines in a given run. We’ll use it to
uniquely tag our Docker images.

Also, blocks can have **secrets**. Secrets contain sensitive information
that doesn’t belong in a Git repository. Secrets import environment
variables and files into the job\[7\]:

``` yaml
secrets:
    - name: secret-1
    - name: secret-2
```

**promotions**: Semaphore always executes first the pipeline found at
`.semaphore/semaphore.yml`. We can have multi-stage, multi-branching
workflows by connecting pipelines together with promotions. Promotions
can be started manually or by user-defined conditions\[8\].

``` yaml
promotions:
  - name: A manual promotion
    pipeline_file: pipeline-file-1.yml
  - name: An automated promotion
    pipeline_file: pipeline-file-2.yml
    auto_promote:
      when: "result = 'passed'"
```
-----------------------

Commands in the **prologue** section are executed before each job in the
block; it’s a convenient place for setup commands:

``` yaml
prologue:
    commands:
    - checkout
    - cache restore
```

The Ubuntu OS image comes with a bunch of convenience scripts and
tools\[4\]:

  - **checkout**: clones the Git repository at the proper code revision
    and `cd` into the directory.

ENV
CHECKOUT
PROLOGUE




TODO: this most likely goes
-----------
Our demo includes a
full-fledged CI pipeline. Open the file from the demo located at
`.semaphore/semaphore.yml` to learn how we can build and test the Docker
image.

We’ve already covered the basics, so let’s jump directly to the first
block. The prologue clones the repo and logins to the Semaphore Docker
registry:

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

The “Build” job then:

  - Pulls the “latest” image from the registry.
  - Builds the Docker image with the current code revision.
  - Tags it with `$SEMAPHORE_WORKFLOW_ID` so each has a distinct ID.
  - Pushes it back to the Registry.

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

<!-- end list -->

``` yaml
jobs:
  - name: Static test
    commands:
      - docker run -it \
        $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID \
        npm run lint

  - name: Integration test
    commands:
      - sem-service start postgres
      - docker run --net=host -it \
        $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID \
        npm run test

  - name: Functional test
    commands:
      - sem-service start postgres
      - docker run --net=host -it \
        $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID \
        npm run ping
      - docker run --net=host -it \
        $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID \
        npm run migrate
```

The last block repeats the pattern:

  - Pulls the image created on the first block.
  - Tags it as “latest” and pushes it again to the Semaphore registry
    for future runs.

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

-----

### 4.4.5 Your First Build

We’ve covered a lot of things in a few pages, here we have the change to
pause for a little bit and do an initial run of the CI pipeline.

You can avoid running the deployment pipeline by making a push in a
non-master branch:

TODO: pull first and switch to setup-semaphore branch

``` bash
$ git branch test-integration
$ git checkout test-integration
$ touch any-file
$ git add any-file
$ git commit -m "run integration pipeline for the first time"
$ git push origin test-integration
```

Check the progress of the pipeline from the Semaphore website:

![CI Pipeline](./figures/05-sem-ci-pipeline.png)
