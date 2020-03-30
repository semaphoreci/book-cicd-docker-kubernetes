## 4.4 Implementing a CI/CD Pipeline With Semaphore

In this section, we’ll learn about Semaphore and how to use it to build
cloud-based CI/CD pipelines.

### 4.4.1 Introduction to Semaphore

For a long time, engineers who needed to implement CI/CD had to choose between
power and ease of use.

On one hand, there was predominantly Jenkins which can
do just about anything, but requires companies to allocate dedicated ops teams
to configure, maintain and scale it — along with the infrastructure on which
it runs. On the other hand, there were several hosted services which let
developers just push their code and not worry about the rest of the process.
However, these services are usually limited to running simple build and test
steps, and would often fall short in need of more elaborate continuous delivery
workflows, which is often the case with containers.

Semaphore (_[https://semaphoreci.com](https://semaphoreci.com)_) is a CI/CD
product that removes all technical barriers to adopting continuous delivery at
scale. It started as one of the simple hosted CI services, but eventually
evolved to support custom continuous delivery pipelines with containers, while
retaining a way of being easy to use by any developer, not just dedicated ops
teams.

Here's what you need to know about Semaphore before we go hands-on:

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

We'll learn about Semaphore's features as we move on in this chapter.

[^roi]: Whitepaper: The 41:1 ROI of Moving CI/CD to Semaphore (_[https://semaphoreci.com/resources/roi](https://semaphoreci.com/resources/roi)_)

### TODO Unclear when is best to do this and in what detail to walk through

To add your project to Semaphore:

1.  Go to `https://semaphoreci.com`
2.  Sign up with your GitHub account.
3.  Click on the **+ (plus)** icon next to *Projects* to see a list of
    your repositories.
4.  Use the *Choose* button next to “semaphore-demo-cicd-kubernetes”.

### 4.4.1 The Semaphore Syntax

You can completely define the CI/CD environment for your project with
Semaphore Pipelines.

A Semaphore pipeline consists of one or more YAML files that follow the
Semaphore syntax\[1\].

These are some common elements you’ll find in a pipeline:

**Version**: sets the syntax version of the file; at the time of writing
the only valid value is “v1.0”.

``` yaml
version: v1.0
```

**Name**: gives an optional name to the pipeline.

``` yaml
name: This is the name of the pipeline
```

**Agent**: the agent is the combination of hardware and software that
runs the jobs. The `machine.type` and `machine.os_image` properties
describe the virtual machine\[2\] and the operating system. The
`e1-standard-2` machine has 2 CPUs and 4 GB RAM and runs a Ubuntu 18.04
LTS\[3\]:

``` yaml
agent:
  machine:
    type: e1-standard-2
    os_image: ubuntu1804
```

**Blocks** and **jobs**: define what to do at each step. Each block can
have one or more jobs. All jobs in a block run in parallel, each in an
isolated environment. Semaphore waits for all jobs in a block to pass
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

### 4.4.2 The Continous Integration Pipeline

We talked about the benefits of CI/CD in chapter 3. Our demo includes a
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

### 4.4.3 Your First Run

We’ve covered a lot of things in a few pages, here we have the change to
pause for a little bit and do an initial run of the CI pipeline.

You can avoid running the deployment pipeline by making a push in a
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

![CI Pipeline](./figures/05-sem-ci-pipeline.png)
