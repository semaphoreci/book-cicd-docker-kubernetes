\newpage

# 3 CI/CD Best Practices for Cloud-Native Applications

Engineering leaders strive to deliver bug-free products to customers as productively as possible. Today’s cloud-native technology empowers teams to iterate, at scale, faster than ever. But to experience the promised agility, we need to change how we deliver software.

“CI/CD” stands for the combined practices of Continuous Integration (CI) and Continuous Delivery (CD). It is a timeless way of developing software in which you’re able to release updates at any time in a sustainable way. When changing code is routine, development cycles are faster. Work is more fulfilling. Companies can improve their products many times per day and delight their customers.

In this chapter, we’ll review the principles of CI/CD and see how we can apply them to developing cloud-native applications.

## 3.1 What Makes a Good CI/CD Pipeline

A good CI/CD pipeline is fast, reliable, and comprehensive.

### 3.1.1 Speed

Pipeline velocity manifests itself in several ways:

**How quickly do we get feedback on the correctness of our work?** If it’s longer than the time it takes to get a cup of coffee, pushing code to CI becomes too distracting. It’s like asking a developer to join a meeting in the middle of solving a problem. Developers will work less effectively due to context switching.

**How long does it take us to build, test and deploy a simple code commit?** Take a project with a total time of one hour to run CI and deployment and a team of about a dozen engineers. Such CI/CD runtime means that the entire team has a hard limit of up to six or seven deploys in a workday. In other words, there is less than one deploy per developer per day available. The team will settle on a workflow with less frequent and thus more risky deployments. This workflow is in stark contrast to the rapid iterations that businesses today need.

**How quickly can we set up a new pipeline?** Difficulty with scaling CI/CD infrastructure or reusing existing configuration creates friction. You make the best use of the cloud by writing software as a composition of small services. Developers need new CI/CD pipelines often, and they need them fast. The best way to solve this is to let developers create and own CI/CD pipelines for their projects.

For this to happen, the CI/CD tool of choice should fit into the existing development workflows. Such a CI/CD tool should support storing all pipeline configuration as code. The team can review, version, and reuse pipelines like any other code. But most importantly, CI/CD should be easy to use for every developer. That way, projects don’t depend on individuals or teams who set up and maintain CI for others.

### 3.1.2 Reliability

A reliable pipeline always produces the same output for a given input. And with consistent runtime. Intermittent failures cause intense frustration among developers.

Engineers like to do things independently, and they often opt to maintain their CI/CD system. But operating CI/CD that provides on-demand, clean, stable, and fast resources is a complicated job. What seems to work well for one project or a few developers usually breaks down later. The team and the number of projects grow as the technology stack changes. Then someone from management realizes that by delegating that task, the team could spend more time on the actual product. At that point, if not earlier, the engineering team moves from a self-hosted to a cloud-based CI/CD solution.

### 3.1.3 Completeness

Any increase in automation is a positive change. However, a CI/CD pipeline needs to run and visualize everything that happens to a code change — from the moment it enters the repository until it runs in production. This requires the CI/CD tool to be able to model both simple and, when needed, complex workflows. That way, manual errors are all but impossible.

For example, it’s not uncommon to have the pipeline run only the build and test steps. Deployment remains a manual operation, often performed by a single person. This is a relic of the past when CI tools were unable to model delivery workflows.

Today a service like Semaphore provides features like:

- Secret management
- Multi-stage, parametrized pipelines
- Change detection
- Container registry
- Connections to multiple environments (staging, production, etc.)
- Audit log
- Test results

There is no longer a reason not to automate the entire software delivery process.

## 3.2 General Principles

### 3.2.1 Architect the System in a Way That Supports Iterative Releases

The most common reason why a system is unable to sustain frequent iterative releases is tight coupling between components.

When building (micro)services, the critical decisions are in defining their: 1) boundaries, 2) communication with the rest of the system.

Changing one service shouldn’t require changing another. If one service goes down, other services or, worse, the system as a whole should not go down. Services with well-defined boundaries allow us to change a behavior in one place and release that change as quickly as possible.

We don’t want a system where making one change requires changing code in many different places. This process is slow and prevents clear code ownership. Deploying more than one service at a time is risky.

A loosely coupled service contains related behavior in one place. It knows as little as possible about the rest of the system with which it collaborates.

A loosely coupled system is conservative in the design of communication between services. Services usually communicate by making asynchronous remote procedure calls (RPC). They use a small number of endpoints. There is no shared database, and all changes to databases are run iteratively as part of the CI/CD pipeline.

Metrics and monitoring are also an essential enabler of iterative development. Being able to detect issues in real-time gives us the confidence to make changes, knowing that we can quickly recover from any error.

### 3.2.2 You Build It, You Run It

In the seminal 2006 interview to ACM[^vogels-acm], Werner Vogels, Amazon CTO, pioneered the mindset of *you build it, you run it*. The idea is that developers should be in direct contact with the operation of their software, which, in turn, puts them in close contact with customers.

The critical insight is that involving developers in the customer feedback loop is essential for improving the quality of the service. Which ultimately leads to better business results.

Back then, that view was radical. The tooling required was missing. So only the biggest companies could afford to invest in building software that way.

Since then, the philosophy has passed the test of time. Today the best product organizations are made of small autonomous teams. They own the full lifecycle of their services. They have more freedom to react to feedback from users and make the right decisions quickly.

Being responsible for the quality of software requires being responsible for releasing it. This breaks down the silos between traditional developers and operations groups. Everyone must work together to achieve high-level goals.

It’s not rare that in newly formed teams there is no dedicated operations person. Instead, the approach is to do “NoOps”. Developers who write code also own the delivery pipeline. The cloud providers take care of hosting and monitoring production services.

[^vogels-acm]: A Conversation with Werner Vogels, ACMQueue
  _[https://queue.acm.org/detail.cfm?id=1142065](https://www.youtube.com/watch?v=wW9CAH9nSLs)_

### 3.2.3 Use Ephemeral Resources

There are three main reasons for using ephemeral resources to run your CI/CD pipeline.

The speed imperative demands CI/CD to not act as a bottleneck. It needs to scale to meet the growth of your team, applications, and test suites. A simple solution is to rely on a cloud service that automatically scales CI/CD pipelines on demand. Ideally, this would come at a pay-as-you-go pricing model, so that you only pay for what you use.

Ephemeral resources help ensure that your tests run consistently. Cloud-based CI/CD solutions run your code in clean and isolated environments. They are created on-demand and deleted as soon as the job has finished.

As we’ve seen in chapter 1, containers allow us to use one environment in development, CI/CD, and production. There’s no need to set up and maintain infrastructure or sacrifice environmental fidelity.

### 3.2.4 Automate Everything

It’s worth repeating: automate everything you can.

There are cases when complete automation is not possible. You may have customers who simply don’t want continuous updates to their systems. There may be regulations restricting how software can be updated. This is the case, for example, in the aerospace, telecom, and medical industries.

But if these conditions do not apply and you still think that your pipeline can’t be fully automated — you’re almost certainly wrong.

Take a good look at your end-to-end process and uncover where you’re doing things manually out of habit. Make a plan to make any changes that may be needed, and automate it.

## 3.3 Continuous Integration Best Practices

Getting the continuous integration process right is a prerequisite for successful continuous delivery. Usually, when the CI process is fast and reliable, the leap to full CI/CD is not hard to make.

### 3.3.1 Treat Master Build as If You’re Going to Make a Release at Any Time

Small, simple, frequent changes are a less risky way of building software in a team than making big, complex, rare changes. This implies that the team will make fewer mistakes by always being ready for release, not more.

Your team’s goal should be to get new code to production as soon as it’s ready. And if something goes wrong — own it and handle it accordingly. Let the team grow through the sense of ownership of what they do.

Being always ready for a release requires a highly developed testing culture. A pull request with new code should always include automated tests. If it doesn’t, then there’s no point in moving fast to oblivion.

If you’re starting a new project, invest time to bring everyone on the same page, and commit to writing automated tests for all code. Set up the entire CI/CD pipeline, even while the application has no real functionality. The pipeline will discourage any manual or risky processes from creeping in and slowing you down in the future.

If you have an existing project with some technical debt, you can start by committing to a “no broken windows” policy on the CI pipeline. When someone breaks master, they should drop what they’re doing and fix it.

Every test failure is a bug. It needs to be logged, investigated, and fixed. Assume that the defect is in application code unless tests can prove otherwise. However, sometimes the test itself is the problem. Then the solution is to rewrite it to be more reliable.

The process of cleaning up the master build usually starts as being frustrating. But if you’re committed and stick to the process, over time, the pain goes away. One day you reach a stage when a failed test means there is a real bug. You don’t have to re-run the CI build to move on with your work. No one has to impose a code freeze. Days become productive again.

### 3.3.2 Keep the Build Fast: Up to 10 Minutes

Let’s take two development teams, both writing tests, as an example. Team A has a CI build that runs for about 3 minutes. Team B has a build that clocks at 45 minutes. They both use a CI service that runs tests on all branches. They both release reliable software in predictable cycles. But team A has the potential to build and release over 100 times in a day, while team B can do that up to 7 times. Are they both doing *continuous* integration?

The short answer is no.

If a CI build takes a long time, we approach our work defensively. We tend to keep branches on the local computer longer. Every developer’s code is in a different state. Merges are rarer, and they become big and risky events. Refactoring becomes hard to do on the scale that the system needs to stay healthy.

With a slow build, every “git push” leads to a huge distraction. We either wait or look for something else to do to avoid being completely idle. And if we context-switch to something else, we know that we’ll need to switch back again when the build is finished. The catch is that every task switch in programming is hard, and it sucks up our energy.

The point of *continuous* in continuous integration is speed. Speed drives high productivity: we want feedback as soon as possible. Fast feedback loops keep us in a state of flow, which is the source of our happiness at work.

So, it’s helpful to establish criteria for how fast should a CI process be:

_Proper continuous integration is when it takes you less than 10 minutes from pushing new code to getting results_.

The 10-minute mark is about how much a developer can wait without getting too distracted. It’s also adopted by one of the pioneers of continuous delivery, Jez Humble. He performs the following informal poll at conferences[^jez].

First, he asks his audience to raise their hands if they do continuous integration. Usually, most of the audience raise their hands.

He then asks them to keep their hands up if everyone on their team commits and pushes to the master branch at least daily.

Over half the hands go down. He then asks them to keep their hands up if each such commit causes an automated build and test. Half the remaining hands are lowered.

Finally, he asks if, when the build fails, it’s usually back to green within ten minutes.

With that last question, only a few hands remain. Those are the people who pass the informal CI certification test.

There are a couple of tactics which you can employ to reduce CI build time:

- **Caching**: Project dependencies should be independently reused across builds. When building Docker containers, use the layer caching feature to reuse known layers from the registry.
- **Built-in Docker registry**: A container-native CI solution should include a built-in registry. This saves a lot of money compared to using the registry provided by your cloud provider. It also speeds up CI, often by several minutes.
- **Test parallelization**: A large test suite is the most common reason why CI is slow. The solution is to distribute tests across as many parallel jobs as needed.
- **Change detection**: Large test suites can be dramatically sped up by only testing code that has changed since the last commit.

### 3.3.3 Build Only Once and Promote the Result Through the Pipeline

In the context of container-based services, this principle means building containers only once and then reusing the images throughout the pipeline.

For example, consider a case where you need to run tests in parallel and then deploy a container. The desired pipeline should build the container image in the first stage. The later stages of testing and deployment reuse the container from the registry. Ideally, the registry would be part of the CI service to save costs and avoid network overhead.

![Build Docker once](figures/04-build-docker-once.png){ width=95% }

The same principle applies to any other assets that you need to create from source code and use later. The most common are binary packages and website assets.

Besides speed, there is the aspect of reliability. The goal is to be sure that every automated test ran against the artifact that will go to production.

To support such workflows, your CI system should be able to:

- Execute pipelines in multiple stages.
- Run each stage in an identical, clean, and isolated environment.
- Version and upload the resulting artifact to an artifact or container storage system.
- Reuse the artifacts in later stages of the pipeline.

These steps ensure that the build doesn’t change as it progresses through the system.

### 3.3.4 Run Fast and Fundamental Tests First

On many occasions, you can get all the feedback from CI that you need without running the entire test suite.

**Unit tests** run the fastest because they:

- Test small units of code in isolation from the rest of the system.
- Verify the core business logic, not behavior from the end-user perspective.
- Usually don’t touch the database.

The **test pyramid** diagram is a common representation of the distribution of tests in a system:

![Test pyramid](figures/04-test-pyramid.png){ width=70% }

According to this strategy, a test suite has:

- The most unit tests.
- Somewhat less service-level tests, which include calls to the database and any other core external resource.
- Few user interfaces, or end-to-end tests. These serve to verify the behavior of the system as a whole, usually from the user's perspective.

If a team follows this strategy, a failing unit test is a signal of a fundamental problem. The remaining high-level and long-running tests are irrelevant until we resolve the problem.

For these reasons, projects with test suites that run for anything longer than a minute should prioritize unit tests in the CI pipeline. For example, such a pipeline may look like this:

![Multi-stage testing](figures/04-multistage-testing.png){ width=95% }

This strategy allows developers to get feedback on trivial errors in seconds. It also encourages all team members to understand the performance impact of individual tests as the code base grows.

There are additional tactics that you can use with your CI system to get fast feedback:

**Conditional stage execution** lets you defer running certain parts of your build for the right moment. For example, you can configure your CI to run a subset of end-to-end tests only if a related component has changed.

![](figures/04-pipeline-deps.png){ width=95% }

In the pipeline above, backend and frontend tests run if code changed in the corresponding directories. End-to-end tests run if any of the two has passed and none has failed.

**Change detection** lets you skip steps in the pipeline when the underlying code has not changed. By running only the relevant tests for a given commit, you can speed up the pipeline and cut down costs.

![](./figures/04-change-detection.png){ width=80% }

**A fail-fast strategy** gives you instant feedback when a job fails. CI stops all currently running jobs in the pipeline as soon as one of the jobs has failed. This approach is particularly useful when running parallel jobs with variable duration.

**Automatic cancelation of queued builds** can help in situations when you push some changes, only to realize that you have made a mistake. So you push a new revision immediately but would then need to wait for twice as long for feedback. Using automatic cancelations, you can get feedback on revisions that matter while skipping the intermediate ones.

### 3.3.5 Minimize Feature Branches, Embrace Feature Flags

One of the reasons why Git overshadowed earlier version control systems like Subversion is that it made branching easy. This motivated developers to create and merge branches many times per day.

The point of making such short-lived branches is to work in isolation from the master, which we agreed to keep in a releasable state at all times. In a Git branch, developers can commit and save their work at any time. When they’re done, they can squash all commits to form a nicely formatted changeset. Then they submit the changeset for feedback and eventually merge it. It’s also common to call such branches “feature branches”. In that context, the term is misleading.

That is not what this best practice is about.

By feature branches, we refer to branches that live for as long as a new product feature is in development. Such branches do not live for hours, but months.

Working in a branch for so long opens the door to all the problems that come up with infrequent integration. Dependencies and internal APIs are likely to change. The amount of work and coordination needed to merge skyrockets. The difficulty is not just to merge code on a line-by-line level. It’s also to make sure it doesn’t introduce unforeseen bugs at runtime.

The solution is to use feature flags. Feature flags boil down to:

```ruby
if current_user.can_use_feature?("new-feature")
  render_new_feature_widget
end
```

So you don’t even load the related code unless the user is a developer working on it, or a small group of beta testers. No matter how unfinished the code is, nobody will be affected. So you can work on it in short iterations and make sure each iteration is well integrated with the system as a whole. Such integrations are much easier to deal with than a big-bang merge.

### 3.3.6 Use CI to Maintain Your Code

If you’re used to working on monolithic applications, building microservices leads to an unfamiliar situation. Services often reach a stage of being done, as in no further work is necessary for the time being.

No one may touch the service’s repository for months. And then, one day, there’s an urgent need to deploy a change. The CI build unexpectedly fails: there are security vulnerabilities in several dependencies, some of which have introduced breaking changes. What seemed like a minor update becomes a high-risk operation that may drag into days of work.

To prevent this from happening, you can **schedule a daily CI build**. A scheduled build is an excellent way of detecting any issues with dependencies early, regardless of how often your code changes (or doesn’t).

You can further support the quality of your code by incorporating in your CI pipeline:

- Code style checkers
- Code smell detectors
- Security scanners

And running them first, before unit tests.

## 3.4 Continuous Delivery Best Practices

### 3.4.1 The CI/CD Pipeline is the Only Way to Deploy to Production

A CI/CD pipeline is a codified standard of quality and procedure for making a release. By rejecting any change that breaks any of the rules, the pipeline acts as a gatekeeper of quality. It protects the production environment from unverified code. It pushes the team to work in the spirit of continuous improvement.

It’s crucial to maintain the discipline of having every single change go through the pipeline before reaching production. The CI/CD pipeline should be the only way code can reach production.

It can be tempting to break this rule in cases of seemingly exceptional circumstances and revert to manual procedures that circumvent the pipeline. On the contrary, the times of crisis are exactly when the pipeline delivers value by making sure that the system doesn’t degrade even further. When timing is critical, the pipeline should roll back to the previous release.

Once it happens that the configuration and history of the CI/CD pipeline diverge from what teams do in reality, it’s difficult to re-establish automation and the culture of quality. For this reason, it’s important to invest time in making the pipeline fast so that no one feels encouraged to skip it.

### 3.4.2 Developers Can Deploy to Production-Like Staging Environments at a Push of a Button

An ideal CI/CD pipeline is almost invisible. Developers get feedback from tests without losing focus and deploy with a single command or button press. There’s no delay between intent and actualization. Anything that gets in the way of that ideal state is undesirable.

Developers should be the ones who deploy their code. This is in line with the general principle of “You build it, you run it”. Delegating that task to anyone else simply makes the process an order of magnitude slower and more complicated.

Developers who build containerized microservices need to have a staging Kubernetes cluster where they can deploy at will. Alternatively, they need a way to deploy a canary build, which we describe later in the book.

![Deploy button on Semaphore](figures/03-deploy-button.png){ width=80% }

The deployment operation needs to be streamlined to a single command that is trivial to run and very unlikely to fail. A more complicated deployment sequence invites human and infrastructure errors that slow down the progress.

### 3.4.3 Always Use the Same Environment

Before containers, the realistic advice would be to make the pipeline, staging, and production as similar as possible. The goal is to ensure that the automated tests which we run in the CI/CD pipeline accurately reflect how the change would behave in production. The bigger the differences between staging and production, the higher is the chance of introducing bugs.

Today containers guarantee that your code always runs in the same environment. You can run your entire CI/CD pipeline in your custom Docker containers. And you can be sure that the containers that you build early in the pipeline are bit-exact in further pipeline tests, staging, and production.

Other environments are still not the same as production, since reproducing the same infrastructure and load is expensive. However, the differences are manageable, and we get to avoid most of the errors that would have occurred with non-identical environments.

Chapter 1 includes a roadmap for adopting Docker for this purpose. Chapter 2 described some of the advanced deployment strategies that you can use with Kubernetes. Strategies like blue-green and canary deployment reduce the risk of bad deployments. Now that we know what a proper CI/CD pipeline should look like, it’s time to start implementing it.

[^jez]: What is Proper Continuous Integration, Semaphore
  [https://semaphoreci.com/blog/2017/03/02/what-is-proper-continuous-integration.html](https://semaphoreci.com/blog/2017/03/02/what-is-proper-continuous-integration.html?utm_source=ebook&utm_medium=pdf&utm_campaign=cicd-docker-kubernetes-semaphore)

