\newpage

# 1 Using Docker for Development and CI/CD

In 2013, Solomon Hykes showed [a demo of the first version of Docker during the PyCon conference in Santa Clara](https://www.youtube.com/watch?v=wW9CAH9nSLs). Since then, the benefits of Docker containers have spread to seemingly every corner of the software industry. While Docker (the project and the company) made containers so popular, they were not the first project to leverage containers out there; and they are definitely not the last either.

Six years later, we can hopefully see beyond the hype as some powerful, efficient patterns emerged to leverage containers to develop and ship better software, faster.

In this chapter, you will first learn about the kind of benefits that you can expect from implementing Docker containers.

Then, a realistic roadmap that any organization can follow realistically, to attain these benefits.

## 1.1 Benefits of Using Docker

Containers will not instantly turn our monolithic, legacy applications into distributed, scalable microservices.

Containers will not transform overnight all our software engineers into “DevOps engineers”. Notably, because DevOps is not defined by our tools or skills, but rather by a set of practices and cultural changes.

So what can containers do for us?

### 1.1.1 Set up Development Environments in Minutes

Using Docker and its companion tool [Compose](https://docs.docker.com/compose/), you can run a complex app locally, on any machine, in less than five minutes.

It sums up to:

```
$ git clone https://github.com/jpetazzo/dockercoins
$ cd dockercoins
$ docker-compose up
```

You can run these three lines on any machine where Docker is installed (Linux, macOS, Windows), and in a few minutes, you will get the DockerCoins demo app up and running. DockerCoins was created in 2015; it has multiple components written in Python, Ruby, and Node.js, as well as a Redis store. Years later, without changing anything in the code, we can still bring it up with the same three commands.

This means that onboarding a new team member, or switching from a project to another, can now be quick and reliable. It doesn’t matter if DockerCoins is using Python 2.7 and Node.js 8 while your other apps are using Python 3 and Node.js 10, or if your system is using even different versions of these languages; each container is perfectly isolated from the others and from the host system.

We will see how to get there.

### 1.1.2 Deploy Easily in the Cloud or on Premises

After we build container images, we can run them consistently on any server environment. Automating server installation would usually require steps (and domain knowledge) specific to our infrastructure. For instance, if we are using AWS EC2, we may use AMI (Amazon Machine Images), but these images are different (and built differently) from the ones used on Azure, Google Cloud, or a private OpenStack cluster.

Configuration management systems (like Ansible, Chef, Puppet, or Salt) help us by describing our servers and their configuration as manifests that live in version-controlled source repositories. This helps, but writing these manifests is no easy task, and they don’t guarantee reproducible execution. These manifests have to be adapted when switching distributions, distribution versions, and sometimes even from a cloud provider to another, because they would use different network interface or disk naming, for instance.

Once we have installed the Docker Engine (the most popular option), it can run any container image and effectively abstract these environment discrepancies.

The ability to stage up new environments easily and reliably gives us exactly what we need to set up CI/CD (continuous integration and continuous delivery). We will see how to get there. Ultimately, it means that advanced techniques, such as blue/green deployments, or immutable infrastructure, become accessible to us, instead of being the privilege of larger organizations able to spend a lot of time to build their perfect custom tooling.

### 1.1.3 Less Risky Releases

Containers can help us to reduce the risks associated with a new release.

When we start a new version of our app by running the corresponding container image, if something goes wrong, rolling back is very easy. All we have to do is stop the container, and restart the previous version. The image for the previous version will still be around and will start immediately.

This is way safer than attempting a code rollback, especially if the new version implied some dependency upgrades. Are we sure that we can downgrade to the previous version? Is it still available on the package repositories? If we are using containers, we don’t have to worry about that, since our container image is available and ready.

This pattern is sometimes called _immutable infrastructure_, because instead of changing our services, we deploy new ones. Initially, immutable infrastructure happened with virtual machines: each new release would happen by starting a new fleet of virtual machines. Containers make this even easier to use.

As a result, we can deploy with more confidence, because we know that if something goes wrong, we can easily go back to the previous version.

## 1.2 A Roadmap to Adopting Docker

The following roadmap works for organizations and teams of all size, regardless of their existing knowledge of containers. Even better, this roadmap will give you tangible benefits at each step, so that the gains realized give you more confidence into the whole process.

Sounds too good to be true?

Here is the quick overview, before we dive into the details:

1. Write one Dockerfile. Pick a service where this will have the most impact.
1. Write more Dockerfiles. The goal is to get the whole application in containers.
1. Write a Compose file. Now anyone can get this app running on their machine in minutes.
1. Make sure that all developers are on board. They should all have a Docker setup in good condition.
1. Use this to facilitate quality assurance (QA) and end-to-end testing.
1. Automate this process: congratulations, you are now doing continuous deployment to staging.
1. The last logical step is continuous deployment to production.

Each step is a self-contained iteration. Some steps are easy, others are more work; but each of them will improve your workflow.

### 1.2.1 Choosing the First Project to Dockerize

A good candidate for our first Dockerfile is a service that is a pain in the neck to build, and moves quickly. For instance, that new Rails app that we’re building, and where we’re adding or updating dependencies every few days as we’re adding features. Pure Ruby dependencies are fine, but as soon as we rely on a system library, we will hit the infamous “works on my machine (not on yours)” problem, between the developers who are on macOS, and those who are on Linux, for instance. Docker will help with that.

Another good candidate is an application that we are refactoring or updating, and where we want to make sure that we are using the latest version of the language or framework; without breaking the environment for everything else.

If we have a component that is tricky enough to require a tool like Vagrant to run on our developer’s machines, it’s also a good hint that Docker can help there. While Vagrant is an amazing product, there are many scenarios where maintaining a Dockerfile is easier than maintaining a Vagrantfile; and running Docker is also easier and lighter than running Vagrant boxes.

### 1.2.2 Writing the First Dockerfile

There are various ways to write your first Dockerfile, and none of them is inherently right or wrong. Some people prefer to follow the existing environment as close as possible. For example, if you're currently using PHP 7.2 with Apache 2.4, and have some very specific Apache configuration and `.htaccess` files? Sure, makes sense to put that in containers. But if you prefer to start anew from your `.php` files, serve them with PHP FPM, and host the static assets from a separate NGINX container, that’s fine too. Either way, the [official PHP images](https://hub.docker.com/r/_/php/) got us covered.

During this phase, we’ll want to make sure that the team working on that service has Docker installed on their machine, but only a few people will have to meddle with Docker at this point. They will be leveling the field for everyone else.

Here's an example Dockerfile, for the `hasher` microservice that's part of DockerCoins demo, written in Ruby:

```Dockerfile
FROM ruby
RUN gem install sinatra
RUN gem install thin
ADD hasher.rb /
CMD ["ruby", "hasher.rb"]
EXPOSE 80
```

Once we have a working `Dockerfile` for an app, we can start using this container image as the official development environment for this specific service or component. If we picked a fast-moving one, we will see the benefits very quickly, since Docker makes library and other dependency upgrades completely seamless. Rebuilding the entire environment with a different language version now becomes effortless. And if we realize after a difficult upgrade that the new version doesn’t work as well, rolling back is just as easy and instantaneous, because Docker keeps a cache of previous image builds around.

### 1.2.3 Writing More Dockerfiles

The next step is to get the entire application in containers.

Note that we're not talking about production yet, and even if your first experiments go so well that you want to roll out some containers to production, you can do so selectively, only for some components. In particular, it is advised to keep databases and other stateful services outside of containers until you gain more operational experience.

But in development, we want everything in containers, including the precious databases, because the ones sitting on our developers’ machines don’t, or shouldn’t, contain any precious data anyway.

We will probably have to write a few more Dockerfiles, but for standard services like Redis, MySQL, PostgreSQL, MongoDB, and many more, we will be able to use standard images from the [Docker Hub](https://hub.docker.com/). These images often come with special provisions to make them easy to extend and customize; for instance the official PostgreSQL image will automatically run `.sql` files placed in the suitable directory to pre-load our database with table structure or sample data.

Once we have Dockerfiles (or images) for all the components of a given application, we’re ready for the next step.

### 1.2.4 Writing a Docker Compose File

A `Dockerfile` makes it easy to build and run a single container; a [Docker Compose](https://docs.docker.com/compose/) file makes it easy to build and run a stack of multiple containers.

So once each component runs correctly in a container, we can describe the whole application with a Compose file.

Here's what `docker-compose.yml` for DockerCoins demo looks like:

```yaml
rng:
    build: rng
    ports:
      - "8001:80"

hasher:
    build: hasher
    ports:
      - "8002:80"

webui:
    build: webui
    links:
      - redis
    ports:
      - "8000:80"
    volumes:
      - "./webui/files/:/files/"

redis:
    image: redis

worker:
    build: worker
    links:
      - rng
      - hasher
      - redis
```

This gives us the very simple workflow that we mentioned earlier:

```
$ git clone https://github.com/jpetazzo/dockercoins
$ cd dockercoins
$ docker-compose up
```

Compose will analyze the file `docker-compose.yml`, pull the required images, and build the ones that need to. Then it will create a private bridge network for the application, and start all the containers in that network. Why use a private network for the application? Isn’t that a bit overkill?

Since Compose will create a new network for each app that it starts, this lets us run multiple apps next to each other (or multiple versions of the same app) without any risk of interference.

This pairs with Docker’s service discovery mechanism, which relies on DNS. When an application needs to connect to, say, a Redis server, it doesn’t need to specify the IP address of the Redis server, or its FQDN. Instead, it can just use `redis` as the server host name. For instance, in PHP:

```php
$redis = new Redis();
$redis->connect('redis', 6379);
```

Docker will make sure that the name `redis` resolves to the IP address of the Redis container in the current network. So multiple applications can each have a `redis` service, and the name `redis` will resolve to the right one in each network.

### 1.2.5 A Standardized Development Environment

Once we have that Compose file, it’s a good time to make sure that everyone is on board; i.e. that all our developers have a working installation of Docker. Windows and Mac users will find this particularly easy thanks to Docker Desktop.

Our team will need to know a few Docker and Compose commands; but in many scenarios, they will be fine if they only know `docker-compose up --build`. This command will make sure that all images are up-to-date, and run the whole application, showing its log in the terminal. If we want to stop the app, all we have to do is hit `Ctrl-C`.

At this point, we are already benefiting immensely from Docker and containers: everyone gets a consistent development environment, up and running in minutes, independently of the host system.

For simple applications that don’t need to span multiple servers, this would almost be good enough for production; but we don’t have to go there yet, as there are other fields where we take advantage of Docker without the high stakes associated with production.

### 1.2.6 End-To-End Testing and QA

When we want to automate a task, it’s a good idea to start by having it done by a human, and write down the necessary steps. In other words: do things manually first, but document them. Then, these instructions can be given to another person, who will execute them. That person will probably ask us some clarifying questions, which will allow us to refine our manual instructions.

Once these manual instructions are perfectly accurate, we can turn them into a program (a simple script will often suffice) that we can then execute automatically.

Follow these principles to deploy test environments, and execute CI (Continuous Integration) and end-to-end testing, depending on the kind of tests that you use in your organization. Even if you don’t have automated testing, you surely have some kind of testing happening before you ship a feature, even if it’s just someone messing around with the app in staging before your users see it.

In practice, this means that we will document and then automate the deployment of our application, so that anyone can get it up and running by running a script.

Our final deployment scripts will be way simpler to write and to run than full-blown configuration management manifests, VM images, and so on.

If we have a QA team, they are now empowered to test new releases without relying on someone else to deploy the code for them.

If you’re doing any kind of unit testing or end-to-end testing, you can now automate these tasks as well, by following the same principle as we did to automate the deployment process.

We now have a whole sequence of actions: building images, starting containers, executing initialization or migration hooks, and running tests. From now on, we will call this the _pipeline_, because all these actions have to happen in a specific order, and if one of them fails, we don’t execute the subsequent stages.

### 1.2.7 Continuous Deployment to Staging

The next step is to run our pipeline automatically when we push changes to the code repository.

A CI/CD system like Semaphore can connect to GitHub, and run the pipeline each time someone opens, or updates, a pull request. The same or a modified pipeline can also run on a specific branch, or a specific set of branches.

Each time there are relevant changes, our pipeline will automatically perform a sequence similar to the following:

- Build new container images;
- Run unit tests on these images (if applicable);
- Deploy them in a temporary environment;
- Run end-to-end tests on the application;
- Make the application available for human testing.

Further in this book we will see how to actually go and implement such a pipeline.

Note that we still don’t require container orchestration for all of this to work. If our application in a staging environment can fit on a single machine, we don’t need to worry about setting up a cluster, yet. In fact, thanks to Docker’s layer system, running side-by-side images that share a common ancestry, which will be the case for images corresponding to successive versions of the same component, is very disk- and memory-efficient; so there is a good chance that we will be able to run many copies of our app on a single Docker Engine.

But this is also the right time to start looking into orchestration, and a platform like Kubernetes. Again, at this stage we don't need to roll that out straight to production; but we could use one of these orchestrators to deploy the staging versions of our application.

This will give us a low-risk environment where we can ramp up our skills on container orchestration and scheduling, while having the same level of complexity, minus the volume of requests and data, that our production environment.

### 1.2.8 Continuous Deployment to Production

It might be a while before we go from the previous stage to the next, because we need to build confidence and operational experience.

However, at this point, we already have a continuous deployment pipeline that takes every pull request (or every change in a specific branch or set of branches) and deploys the code on a staging cluster, in a fully automated way.

Of course, we need to learn how to collect logs, and metrics, and how to face minor incidents and major outages; but eventually, we will be ready to extend our pipeline all the way to the production environment.

## 1.3 Summary

Building a delivery pipeline with new tools from scratch is certainly a lot of work. But with the roadmap described above, we can get there one step at a time, while enjoying concrete benefits at each step.

In the next chapter, we will learn about deploying code to Kubernetes, including strategies that might not have been possible in your previous technology stack.
