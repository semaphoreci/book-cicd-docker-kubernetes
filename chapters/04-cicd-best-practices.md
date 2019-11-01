\newpage

# 3 CI/CD Best Practices for Cloud Native Applications

The goal of every engineering team is to deliver bug-free products to customers as productively as possible. Today’s cloud-native technology can empower you to iterate, at scale, faster than ever. But teams that don’t also change how they deliver software will struggle to benefit from the agility and speed that the cloud native technology stack can offer.

“CI/CD” stands for the combined practices of Continuous Integration (CI) and Continuous Delivery (CD). It is a timeless way of developing software in which you’re able to release updates at any time in a sustainable way. When changing code is routine, development cycles are faster and work is more fulfilling.

As a result, a CI/CD practice that is well-tailored to their technology stack enables the leading technology companies to improve their products many times per day.

In this chapter we'll review the principles of CI/CD and see how we can apply them to developing cloud native applications.

## 3.1 What Makes a Good CI/CD Pipeline

A good CI/CD pipeline is fast, reliable and comprehensive.

### 3.1.1 Speed

Pipeline velocity manifests itself in a number of ways:

**How quickly do we get feedback on the correctness of our work?** If it’s longer than the time it takes to get a cup of coffee, pushing code to CI is the equivalent of asking a developer to join a meeting in the middle of solving a problem. Developers will work less effectively due to context switching.

**How long does it take us to build, test and deploy a simple code commit?** For example, a total time of one hour for CI and deployment means that the entire engineering team has a hard limit of up to seven deploys for the whole application in a workday. This causes developers to opt for less frequent and more risky deployments, instead of the rapid change that businesses today need.

**How quickly can we set up a new pipeline?** Difficulty with scaling CI/CD infrastructure or reusing existing configuration creates friction, which stifles development. Today’s cloud infrastructure is best utilized by writing software as a composition of microservices, which calls for frequent and fast initiation of new CI/CD pipelines. This is solved by having a CI/CD tool that is programmable and fits in the existing development workflows. Most notably it should support storing all CI/CD configuration as code that can be reviewed, versioned and restored. It is also important to be able to access CI/CD resources through both a command-line interface (CLI) and remote API. Perhaps most importantly, it should be easy to use for every developer so that projects don't depend on individuals or teams who are tasked to "set up and maintain CI" for other people.

### 3.1.2 Reliability

A reliable pipeline always produces the same output for a given input, and with no significant oscillations in runtime. Intermittent failures cause intense frustration among developers.

Operating and scaling CI/CD infrastructure that provides on-demand, clean, identical and isolated resources for a growing team is a complex job. What seems to work well for one project or a few developers usually breaks down when the team and the number of projects grow, or the technology stack changes. This is a top reason why engineering teams move from a self-hosted to a cloud-based CI/CD solution.

### 3.1.3 Completeness

Any degree of automation is a positive change. However, the job is not fully complete until the CI/CD pipeline accurately runs and visualizes the entire software delivery process. This requires the use of a CI/CD tool that can model both simple and when needed, complex workflows, so that manual error in repetitive tasks is all but impossible.

For example, it’s not uncommon to have the CI phase fully automated, but to leave out deployment as a manual operation to be performed by often a single person on the team. If a CI/CD tool can successfully model the deployment workflow needed, for example with use of secrets, multi-stage pipeline promotions and an audit log, this bottleneck can be removed.

## 3.1 General Principles

### 3.1.1 Architect the System in a Way That Supports Iterative Releases

The most common reason why a system is unable to sustain frequent iterative releases is tight coupling between components.

When building (micro)services, the key decisions are in defining their boundaries and communication with the rest of system.

Changing one service shouldn't require changing another. If one service goes down, other services or, worse, the system as a whole should not go down. Services with well-defined boundaries allow us to to change a behavior in one place, and release that change as quickly as possible.

We don't want to end up with a system where we have to make changes in many different places in order to make a change. This process is slow and prevents clear code ownership. Deploying more than one service at a time is risky.

A loosely coupled service contains related behavior in one place and knows as little as possible about the rest of the system with which it collaborates.

A loosely coupled system is conservative in the design of communication between services. Services usually communicate by making asynchronous remote procedure calls (RPC), use a small number of endpoints, and that failure will happen. There is no shared database, and all changes to databases are run iteratively as part of the CI/CD pipeline.

Metrics and monitoring are also an important part of the feedback loop that enables iterative development. Having metrics that can detect issues in real-time gives us confidence to make changes knowing that we can quickly recover from any error.

### 3.1.2 You Build It, You Run It

The phrase above was pioneered by Werner Vogels, Amazon CTO, in the [seminal 2006 interview to ACM](https://queue.acm.org/detail.cfm?id=1142065). The idea is that developers should be in direct contact with the operation of their software, because it brings them into contact with customers. The key insight is that involving developers in the customer feedback loop is essential for improving the quality of the service and ultimately business results. Back then, that view was radical and limited to only companies with large revenue or funding who could invest in creating the missing tooling.

Today, the best product organizations are made of small autonomous teams owning the full lifecycle of their services. The cloud native technology makes it possible even for companies with a handful of engineers to work in this style. They have more freedom to react to feedback (or lack of) from users, and make the right decisions quickly.

The idea that autonomous engineering teams are responsible for the quality and stability of the software they build means that they are responsible for releasing it. This breaks down the silos between traditional developers and operations groups, as they work together to achieve high-level goals.

It's not rare that in newly formed teams there is actually no dedicated operations or "DevOps" person, and the developers who write code also fully own the delivery pipeline and rely on cloud providers for hosting and monitoring production services.

### 3.1.3 Use Ephemeral Resources

There are three main reasons for using ephemeral resources to run your CI/CD pipeline.

The speed imperative demands the ability to scale CI/CD capacity up to meet the growth of your team, applications and their test suites. This is easiest to accomplish if you rely on a cloud service which automatically scales CI/CD pipelines on demand, both up and down. Typically this comes at a pay-as-you-go pricing model, so that you only pay for the CI/CD resources that you have used.

Ephemeral resources help ensure that your tests always run the same at various stages and are key for pipeline reliability. Cloud-based CI/CD solutions can typically run your code in both containers, and clean and isolated virtual machines (VM) that are spun up on demand.

As we've seen in the first chapter, containers make it easy for developers replicate the configuration that will be used later on in the pipeline without having to either manually set up and maintain infrastructure or sacrifice environmental fidelity.

### 3.1.4 Automate Everything

This may seem obvious, but it’s worth repeating: automate everything you can.

There are certainly cases when complete automation is not possible. You may have customers who simply don't want continuous updates to their systems. There may be regulations restricting how software can be updated, as is the case for example in the aerospace, telecom, and medical industries.

But if these conditions do not apply and you think that something in your pipeline can't be automated, you're almost certainly wrong.

To have a successful pipeline, take a good look at your end-to-end process and uncover where you’re doing things manually out of old habit. Make a plan to make any changes that may be needed, are automate it.

## 3.2 Continuous Integration Best Practices

Getting the continuous integration process right is a prerequisite for successful continuous delivery. Usually when the CI process is fast and reliable, the leap to full CI/CD is not hard to make.

### 3.2.1 Treat Master Build as If You're Going to Make a Release at Any Time

The reason for practicing continuous integration is that small, simple, frequent changes is a less risky way of building software in a team than making big, complex infrequent changes. This implies that team will make fewer mistakes by always being ready for release, not more.

Your team's goal should be to get new code to production as soon as it's ready. And if something goes wrong — own it and handle it accordingly. Let the team grow through the sense of ownership on what they do.

Being always ready for a release requires a highly developed testing culture. Code that's checked in should always be fully tested. If it's not, then there's no point in moving fast to oblivion.

If you're just starting a new project, invest time to bring everyone on the same page and commit to writing automated tests for all code. When the project begins, set up the entire CI/CD pipeline, even while the application has no real functionality. Not only will the team benefit from a CI/CD feedback loop right from the start, but a fully automated pipeline will discourage any manual processes from creeping in and slowing down your team in the future.

If you have an existing project with some technical debt, you can start by committing to a “no broken windows” policy on the CI pipeline. This means that when the master is broken, drop what you're doing and fix it.

Every test failure is a bug. It needs to be logged, investigated and fixed. Assume that the defect is in application code, unless tests can prove otherwise. However, sometimes the test itself really is the problem, which is when the solution is to rewrite it to be more reliable.

The process of cleaning up the master build is something which usually starts being very painful, but if you're committed and stick to the process, over time the pain goes away. One day you reach a stage when a failed test means there is a real bug. You don't have to re-run the CI build just to move on with your work. No one has to impose a code freeze. Days become productive again.

### 3.2.2 Keep the Build Fast: Up to 10 Minutes

Let’s take two development teams, both writing tests, as an example. Team A has a CI build which runs for about 3 minutes. Team B has a build that clocks at 45 minutes. They both use a CI service which runs tests on all branches. They both release reliable software in predictable cycles. It's just that team A has a potential to build and release over 100 times in a day, while team B can do that up to 7 times. Are they both doing *continuous* integration?

The short answer is no.

If a CI build takes a long time, we approach our work defensively. We tend to keep branches on the local computer longer, and thus every developer’s code is in a significantly different state. Merges are rarer, and they become big and risky events. Refactoring becomes hard to do on the scale that the system needs to stay healthy.

With a slow build, every “git push” leads to a huge distraction. We either wait, or look for something else to do to avoid being completely idle. And if we context-switch to something else, we know that we’ll need to switch back again when the build is finished. The catch is that every task switch in programming is hard and it sucks up our energy.

The point of continuous in continuous integration is speed. Speed drives high productivity: we want feedback as soon as possible. Fast feedback loops keep us in a state of flow, which is the source of our happiness at work.

So, it’s helpful to establish criteria for how fast should a continuous integration process be:

Proper continuous integration is when it takes you less than 10 minutes from pushing new code to getting results.

While the 10-minute mark is about how much a developer can wait without getting too distracted, it's also adopted by a leading one of the pioneers of continuous delivery, Jez Humble, who performs the following informal poll at conferences.

He usually begins by asking his audience to raise their hands if they do continuous integration. Usually most of the audience raise their hands.

He then asks them to keep their hands up if everyone on their team commits and pushes to the master branch at least daily.

Over half the hands go down. He then asks them to keep their hands up if each such commit causes an automated build and test. Half the remaining hands are lowered.

Finally he asks if, when the build fails, it’s usually back to green within ten minutes.

With that last question only a few hands remain. Those are the people who pass the informal CI certification test.

There are a couple of tactics which you can employ to reduce CI build time:

- **Caching**: Project dependencies should be independently reused across builds. When building Docker containers, use the layer caching feature to reuse known layers from the registry.
- **Built-in Docker registry**: A container-native CI solution should include a built-in registry. This not only saves a lot of money comparing to using the registry provided by your cloud provider, but it also significantly speeds up CI.
- **Test parallelization**: A large test suite is the most common reason why CI is slow. The solution is to use a cloud-based CI service which can automatically distribute tests across as many parallel jobs as needed to achieve the 10-minute benchmark, or better.

### 3.2.3 Build Only Once and Promote the Result Through the Pipeline

A primary goal of a CI/CD pipeline is to build confidence in your changes and minimize the chance of unexpected outcomes. Continuous integration of container-based services should execute building containers only once, and the resulting images should be reused throughout the entire pipeline.

For example, consider a a case where you need to run tests in parallel and then deploy a container. The desired pipeline should build the container in the first stage, while the later stages of parallel testing and deployment reuse the container from the registry that's part of the CI service.

TODO: diagram build docker once

The same principle applies to any other assets that you need to create from source code and use later in the pipeline, such as binary packages or website assets.

When software is compiled or packaged multiple times, it's possible for slight inconsistencies to be injected into the resulting artifacts. It also means that tests don't target the same software that will be deployed later, making our pipeline unreliable.

To avoid this problem, your CI system should be able to execute pipelines in multiple stages, each running in an identical, clean and isolated environment. The resulting artifact should be versioned and uploaded to an artifact or container storage system to be pulled down by subsequent stages of the pipeline, ensuring that the build does not change as it progresses through the system.

### 3.2.4 Run Fast and Fundamental Tests First

While it's great to keep your entire pipeline fast, on many occasions you can get all the feedback from CI that you need without running all tests.

Unit tests run the fastest, because they are isolated and usually don't touch the database. They define the business logic, and are the most numerous, as is commonly depicted in the "test pyramid" diagram:

![Test pyramid](figures/04-test-pyramid.png){ width=70% }

A failure in unit tests then is a signal of a fundamental problem, which makes running the remaining high-level and long-running tests irrelevant. For these reasons, projects with test suites that run for anything longer than a minute should prioritize unit tests in the CI pipeline.

![Multi-stage testing](figures/04-multistage-testing.png){ width=70% }

This strategy allows developers to get feedback on trivial errors in seconds. It also encourages all team members to understand the performance impact of individual tests as the code base grows.

There are additional tactics that you can use with your CI system to get fast feedback:

- **Conditional stage execution** lets you defer running certain parts of your build for the right moment. For example, you can configure your CI to run a subset of end-to-end tests only if one of the related components was changed.
- **A fail-fast strategy** gives you instant feedback when a job fails. CI stops all currently running jobs in the pipeline as soon as one of the jobs has failed. This approach is particularly useful when running parallel jobs with variable duration.
- **Automatic cancelation of queued builds** can help in situations when you push some changes, only to realize that you have missed something small, so you push a new revision immediately, but then need to wait for twice as long for feedback. With this approach you get feedback on revisions that matter while skipping all the intermediate ones.

### 3.2.5 Minimize Feature Branches, Embrace Feature Flags

One of the reasons why Git completely overshadowed previously used version control systems like Subversion and CVS is how it made branching easy. It quickly became common practice among some developers to create and merge branches multiple times per day.

The point of making such short-lived branches is to work in isolation from master, which we agreed to keep in a releasable state at all times. In a Git branch, developers can commit and save their work at any time, then squash those commits to form a nicely formatted set of changes when they're ready to ask for feedback and eventually merge them. It's also common to call such branches "feature branches".

That is not what this best practice is about.

When we say you should minimize feature branches, we refer to not having long-lived branches that live for as long as a new product feature is in development, which can easily take months.

Keeping a branch running for weeks or months opens the door to all the problems that come up with infrequent integration. Dependencies and internal APIs are likely to change, and the amount of work and coordination needed to merge skyrockets. The difficulty is not just to merge code on line-by-line level, but to make sure it doesn’t introduce unforeseen bugs at runtime.

The solution is to use feature flags. Feature flags are basically:

```ruby
if current_user.can_use_feature?("new-feature")
  render_new_feature_widget
end
```

So you don’t even load the related code unless the user is a developer working on it, or a small group of beta testers. No matter how unfinished the code is, nobody will be affected. So you can work on it in small iterations and make sure each iteration is well integrated with the system as a whole. Such integrations are much easier to deal with than a big-bang merge.

### 3.2.6 Use CI to Maintain Your Code

If you're used to working on monolithic applications, building microservices leads to an unfamiliar situation: a service often reach a phase of being done, as in no further work is necessary for the time being.

No one may touch the service's repository for months. And then, one day, there's an urgent need to make a change. The CI build fails with unexpected errors: there are security vulnerabilities in multiple dependencies, and many others have changes that someone needs to review. Suddenly, what seemed like a trivial update becomes a risky operation that may explode into days of work.

To prevent this from happening, you can schedule a daily CI build. A scheduled build is a great way of detecting any issues with dependencies early, regardless of how often your code changes.

You can further support the quality of your code by incorporating code style checkers, code smell detectors and security scanners in your CI pipeline — and running them first, before unit tests.

## 3.3 Continuous Delivery Best Practices

### 3.3.1 The CI/CD Pipeline is the Only Way to Deploy to Production

A CI/CD pipeline is a codified standard of quality and procedure for making a release. By rejecting any change that breaks any of the rules, the pipeline acts as a gatekeeper of quality that protects the production environment from unverified code and pushes the team to work in the spirit of continuous improvement.

To reap these benefits, it's important to maintain the discipline of having every single change go through the pipeline before reaching production. The CI/CD pipeline should be the only way code can reach production.

It can be tempting to break this rule in cases of seemingly exceptional circumstances, and revert to manual procedures that circumvent the pipeline. On the contrary, the times of crisis are exactly when the pipeline delivers value, by making sure that the system doesn't degrade even further. When timing is critical, the pipeline should be used to roll back to the previous release.

Once it happens that configuration and history of the CI/CD pipeline diverge from what teams does in reality, it’s difficult to re-establish the automation and quality-driven culture. For this reason, it’s important to invest time in making the pipeline fast, so that no one feels encouraged to skip it.

### 3.3.2 Developers Can Deploy to Production-Like Staging Environments at a Push of a Button

An ideal CI/CD pipeline is the one which is almost invisible. Developers get feedback from tests without losing focus, and deploy with a single command or button press. There's no delay between intent and actualization. Anything that gets in the way of that ideal state is undesirable.

First, developers should be the ones who deploy their own code. This is in line with the general principle of "You build it, you run it". Delegating that task to anyone else simply makes the process an order of magnitude slower and more complicated.

Developers who build containerized microservices need to have a staging Kubernetes cluster where they can deploy at will.

Second, the deployment operation needs to be streamlined to a single command that is trivial to run and very unlikely to fail. This is the task for the person or team who are setting up the infrastructure at the beginning of the project. A more complicated deployment sequence invites human and infrastructure errors that slow down the flow of progress.

### 3.3.3 Always Use Exactly the Same Environment

Before containers, the realistic advice would be to make the pipeline, staging and production environments as similar as possible. This helps ensure that the automated tests which we run in the CI/CD pipeline accurately reflect how the change would behave in production. The bigger the differences between staging and production, the more it is likely that team will release problematic changes to customers that were reproduced while testing.

Today containers guarantee that your code always runs in exactly the same environment. You can run your entire CI/CD pipeline in your custom Docker containers. And you can be sure that the containers that you build during the pipeline will be bit-exact in further pipeline tests, staging and production environments.

Other environments are still not exactly the same as production, since reproducing the exact same infrastructure and load is expensive. However, the differences are manageable, and we get to avoid most of the errors that would have occurred with non-identical environments.

Chapter 1 includes a roadmap for adopting Docker for this purpose. Chapter 2 described some of the advanced deployment strategies that you can employ with Kubernetes that serve to further minimize the risk of bad deploys, such as blue-green and canary deployment.
