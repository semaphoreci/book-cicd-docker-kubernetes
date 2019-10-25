\newpage

# 3 CI/CD Best Practices for Cloud Native Applications

The goal of every engineering team is to deliver bug-free products to customers at high velocity. Today’s cloud-native technology can empower you to iterate, at scale, faster than ever. But teams that don’t also change how they deliver software will struggle to benefit from the agility and speed that the cloud native technology stack can offer.

“CI/CD” stands for the combined practices of Continuous Integration (CI) and Continuous Delivery (CD). It is a timeless way of developing software in which you’re able to release updates at any time in a sustainable way. When changing code is routine, development cycles are faster and work is more fulfilling.

As a result, a CI/CD practice that is well-tailored to their technology stack enables the leading technology companies to improve their products many times per day.

In this chapter we'll review the principles of CI/CD and see how we can apply them to developing cloud native applications.

## 3.1 What Makes a Good CI/CD Pipeline

A good CI/CD pipeline is fast, reliable and comprehensive.

### 3.1.1 Speed

Pipeline velocity manifests itself in a number of ways:

**How quickly do we get feedback on the correctness of our work?** If it’s longer than the time it takes to get a cup of coffee, pushing code to CI is the equivalent of asking a developer to join a meeting in the middle of solving a problem. Developers will work less effectively due to context switching.

**How long does it take us to build, test and deploy a simple code commit?** For example, a total time of one hour for CI and deployment means that the entire engineering team has a hard limit of up to seven deploys for the whole application in a workday. This causes developers to opt for less frequent and more risky deployments, instead of the rapid change that businesses today need.

**How quickly can we set up a new pipeline?** Difficulty with scaling CI/CD infrastructure or reusing existing configuration creates friction, which stifles development. Today’s cloud infrastructure is best utilized by writing software as a composition of microservices, which calls for frequent and fast initiation of new CI/CD pipelines. This is solved by having a CI/CD tool that is programmable and fits in the existing development workflows. Most notably it should support storing all CI/CD configuration as code that can be reviewed, versioned and restored. It is also important to be able to access CI/CD resources through both a command-line interface (CLI) and remote API.

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

There are certainly cases when complete automation is not possible. You may have customers who simply don't want continuous updates to their systems. There maye be regulations restricting how software can be updated, as is the case for example in the aerospace, telecom, and medical industries.

But if these conditions do not apply and you think that something in your pipeline can't be automated, you're almost certainly wrong.

To have a successful pipeline, take a good look at your end-to-end process and uncover where you’re doing things manually out of old habit. Make a plan to make any changes that may be needed, are automate it.

## 3.2 Continuous Integration Best Practices

Getting the continuous integration process right is a prerequisite for successful continuous delivery. Usually when the CI process is fast and reliable, the leap to full CI/CD is not hard to make.

### 3.2.1 Treat Master Build as If You're Going to Make a Release at Any Time

When the master is broken, drop what you’re doing and fix it. Maintain a “no broken windows” policy on the pipeline.

### 3.2.2 Keep the Build Fast: Up to 10 Minutes

### 3.2.3 Run Fast and Fundamental Tests First

### 3.2.4 Abolish Feature Branches

Work in small iterations. AKA Have all developers commit code to master at least 10 times per day

testing culture needs to be at its best

Build in quality checking.

Include pull requests.

Wait for tests to pass before opening a pull request.

Peer-review each pull request.

Use CI to maintain your code.

Keep track of key metrics.

## 3.3 Continuous Delivery Best Practices

Build Only Once and Promote the Result Through the Pipeline.

Embrace feature flags.

Developers can push the code into production-like staging environments.

Anyone can deploy any version of the software to any environment on demand, at a push of a button.

The CI/CD Pipeline is the Only Way to Deploy to Production

Always use exactly the same environment
