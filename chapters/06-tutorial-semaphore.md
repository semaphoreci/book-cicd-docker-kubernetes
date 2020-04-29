
\newpage

## 4.4 Implementing a CI/CD Pipeline With Semaphore

In this section, we’ll learn about Semaphore and how to use it to build cloud-based CI/CD pipelines.

### 4.4.1 Introduction to Semaphore

For a long time, engineers looking for a CI/CD tool had to choose between power and ease of use.

On one hand, there was predominantly Jenkins which can do just about anything, but is difficult to use and requires companies to allocate dedicated ops teams to configure, maintain and scale it — along with the infrastructure on which it runs.

On the other hand, there were several hosted services that let developers just push their code and not worry about the rest of the process. However, these services are usually limited to running simple build and test steps, and would often fall short in need of more elaborate continuous delivery workflows, which is often the case with containers.

Semaphore (_[https://semaphoreci.com](https://semaphoreci.com)_) started as one of the simple hosted CI services, but eventually evolved to support custom continuous delivery pipelines with containers, while retaining a way of being easy to use by any developer, not just dedicated ops teams. As such, it removes all technical barriers to adopting continuous delivery at scale:

- It's a cloud-based service: there's no software for you to install and maintain.
- It provides a visual interface to model CI/CD workflows quickly.
- It's the fastest CI/CD service, due to being based on dedicated hardware instead of common cloud computing services.
- It's free for open source and small private projects.

The key benefit of using Semaphore is increased team productivity. Since there is no need to hire supporting staff or expensive infrastructure, and it runs CI/CD workflows faster than any other solution, companies that adopt Semaphore report a very large, 41x ROI comparing to their previous solution [^roi].

We'll learn about Semaphore's features as we go hands-on in this chapter.

[^roi]: Whitepaper: The 41:1 ROI of Moving CI/CD to Semaphore (_[https://semaphoreci.com/resources/roi](https://semaphoreci.com/resources/roi)_)

### 4.4.1 Creating a Semaphore Account

To get started with Semaphore:

- Go to [https://semaphoreci.com](https://semaphoreci.com) and click to sign up with your GitHub account.
- GitHub will ask you to let Semaphore access your profile information. Allow this so that Semaphore can create an account for you.
- Semaphore will walk you through the process of creating an organization. Since software development is a team sport, all Semaphore projects belong to an organization. Your organization will have its own domain, for example, `awesomecode.semaphoreci.com`.
- Semaphore will ask you to choose between a time-limited free trial with unlimited capacity, a free plan, and an open-source plan. Since we're going to work with an open-source repository, you can choose the open-source option.
- Finally, you'll be greeted with a quick product tour.

### 4.4.2 Creating a Semaphore Project For The Demo Repository

We assume that you have previously forked the demo project from [https://github.com/semaphoreci-demos/semaphore-demo-cicd-kubernetes](https://github.com/semaphoreci-demos/semaphore-demo-cicd-kubernetes) to your GitHub account.

Follow the prompts to create a project. The first time you do this, you will see a screen which asks you to choose between connecting Semaphore to either your public, or both public and private repositories on GitHub:

![Authorizing Semaphore to access your GitHub repositories](./figures/05-github-repo-auth.png)

To keep things simple, select the "Public repositories" option. If you later decide that you want to use Semaphore with your private projects as well, you can extend the permission at any time.

Next, Semaphore will present you a list of repositories to choose from as the source of your project:

![Choosing a repository to set up CI/CD for](./figures/05-choose-repo.png)

In the search field, start typing `semaphore-demo-cicd-kubernetes` and choose that repository.

Semaphore will quickly initialize the project. Behind the scenes, it will set up everything that's needed to know about every Git push automatically pull the latest code — without you configuring anything.

The next screen lets you invite collaborators to your project. Semaphore mirrors access permissions of GitHub, so if you add some people to the GitHub repository later, you can "sync" them inside project settings on Semaphore.

![Add collaborators](./figures/05-sem-add-collaborators.png)

Click on **Go to Workflow Builder**. Semaphore will ask you if you want to use the existing pipelines or create one from scratch. At this point, you can choose to use the existing configuration to get directly to the final workflow. In this chapter, however, we want to learn how to create the pipelines so we’ll make a fresh start.

![Start from scratch or use existing pipeline](./figures/05-sem-existing-pipeline.png)

### 4.4.3 The Semaphore Workflow Builder

When choosing to start from scratch, Semaphore shows some starter workflows with popular frameworks and languages. Choose the Build Docker workflow and click on **Run this workflow**.

![Choosing a starter workflow](./figures/05-sem-starter-workflow.png)

Semaphore will immediately start the workflow. Wait a few seconds and your first Docker image is ready, congratulations!

![Starter run](./figures/05-sem-starter-run.png)

Of course, since we haven’t told Semaphore where to store the image yet, it’s lost as soon as the job ends. We’ll correct that next.

See the **Edit Workflow** button on the top right corner? Click it to open the Workflow Builder.

![Workflow builder overview](./figures/05-sem-wb-overview.png)

Now it’s a good moment to learn how the Workflow Builder works.

**Pipelines**

Pipelines are represented on the builder as big gray boxes. Pipelines organize the workflow in blocks that are executed from left to right. Each pipeline usually has a specific objective such as test, build, or deploy. Pipelines can be chained together to make a complex workflow.

**Agent**

The agent is the combination of hardware and software that powers the pipeline. The **machine type** determines the amount of CPUs and memory allocated to the virtual machine. The operating system is controlled by the **environment type** and **OS image** settings.

The default machine is called `e1-standard-2` and has 2 CPUs, 4 GB RAM, and runs a custom Ubuntu 18.04 image.

**Jobs and Blocks**

Blocks and jobs define what to do at each step. Jobs define the commands that do the work. Blocks contain jobs with a common objective and shared settings.

Jobs inherit their configuration from their parent block. All the jobs in a block run in parallel, each in its isolated environment. If any of the jobs fails, the pipeline stops with an error.

Blocks run sequentially, once all the jobs in the block complete, the next block starts.

### 4.4.4 The Continous Integration Pipeline

We talked about the benefits of CI/CD in chapter 3. In the previous section, we created our very first pipeline. In this section, we’ll extend it with tests and a place to store the images.

At this point, you should be seeing the Workflow Builder with the Docker Build starter workflow. Click on the **Build** block so we can see how it works.

![Build block](./figures/05-sem-build-block.png)

Each line on the job is a command to execute. The first command in the job is `checkout`, which is a built-in script that clones the repository at the correct revision. The next command, `docker build`, builds the image using our `Dockerfile`.

Replace the contents of the job with the following commands:

```bash
checkout
docker login -u $SEMAPHORE_REGISTRY_USERNAME -p $SEMAPHORE_REGISTRY_PASSWORD $SEMAPHORE_REGISTRY_URL
docker pull $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:latest || true
docker build --cache-from $SEMAPHORE_REGISTRY_URL/seamphore-demo-cicd-kubernetes:latest -t $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID .
docker push $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID
```

Each line has its purpose:

- Line 1 clones the repository with `checkout`.
- Line 2 logs in the Semaphore private Docker registry.
- Line 3 pulls the Docker image tagged as `latest`.
- Line 4 builds a newer version of the image using the latest code in the revision.
- Line 5 pushes the new image to the registry.

The perceptive reader will note that we introduced special environment variables; these are predefined automatically in every job. The variables starting with `SEMAPHORE_REGISTRY_*` are used to access the private registry. We’re using `SEMAPHORE_WORKFLOW_ID`, which is guaranteed to be unique for each run, to tag the image.

Now that we have a Docker image that we can test let’s add a second block. Click on the **+Add Block** dotted box.

The job has three jobs:

- Static tests.
- Integration tests.
- Functional tests.

The general sequence is the same for all tests:

1. Pull the image from the registry.
2. Start the container.
3. Run the tests.

Blocks have a *prologue* where we can place common setup commands for the jobs. Open the prologue section on the right side of the block and type the following commands. These will be executed before each job starts:

``` bash
docker login -u $SEMAPHORE_REGISTRY_USERNAME -p $SEMAPHORE_REGISTRY_PASSWORD $SEMAPHORE_REGISTRY_URL
docker pull $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID
```

Next, rename the job as “Unit test” and type the following command, which runs JSHint, a static code analysis tool, inside the container:

``` bash
docker run -it $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID npm run lint
```

Next, click on the **+Add another job** link below the job to create a new one called “Functional test”. Type these commands:

``` bash
sem-service start postgres
docker run --net=host -it $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID npm run ping
docker run --net=host -it $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID npm run migrate
```

This job tests two things: that the container connects to the database (`ping`) and that it can create the tables (`migrate`). Obviously, we’ll a database for this to work; fortunately, we have `sem-service`, which lets us start database engines like MySQL, Postgres, or MongoDB with a single command.

Finally, add a third job called “Integration test” and type these commands:

``` bash
sem-service start postgres
docker run --net=host -it $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID npm run test
```

This last test runs the code in ~src/database.test.js~, which checks if the application can write and delete rows.

![Test block](./figures/05-sem-test-block.png)

Create the third and final block for this pipeline to:

1. Pull the image created on the first block.
2. Tag it as “latest”.
3. Push it again to the Semaphore registry for future runs.

Type these commands for the Push block:

``` bash
docker login -u $SEMAPHORE_REGISTRY_USERNAME -p $SEMAPHORE_REGISTRY_PASSWORD $SEMAPHORE_REGISTRY_URL
docker pull $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID
docker tag $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:$SEMAPHORE_WORKFLOW_ID $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:latest
docker push $SEMAPHORE_REGISTRY_URL/semaphore-demo-cicd-kubernetes:latest
```

![Push block](./figures/05-sem-push-block.png)

This completes the setup of the CI pipeline.

### 4.4.5 Your First Build

We’ve covered a lot of things in a few pages; here, we have the chance to pause for a little bit and try the CI pipeline. Click on the **Run the workflow** button on the top-right corner and then click on **Start**.

![Run workflow](./figures/05-sem-ci-pipeline.png)

Wait until the pipeline is complete then go to the top level of the project. Click on the **Docker Registry** button and open the repository to verify that the Docker image is there.

![Docker registry](./figures/05-sem-registry.png)

