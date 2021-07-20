## 4.7 The Canary Pipeline

Now that we have our cloud services, we’re ready to prepare the canary deployment pipeline.

Our project on GitHub includes three ready-to-use reference pipelines for deployment. They should work out-of-the-box in combination with the secrets as described earlier. For further details, check the `.semaphore` folder in the project.

In this section, you'll learn how to create deployment pipelines on Semaphore from scratch. We'll use DigitalOcean and Docker Hub registry as an example, but the process is essentially the same for other clouds.

### 4.7.1 Creating a Promotion and Deployment Pipeline

On Semaphore, open the Workflow Builder to create a new pipeline.

Create a new promotion using the *+Add First Promotion* button. Promotions connect pipelines together to create complex workflows. Let’s call the new pipeline “Canary”.

![Create promotion](./figures/05-sem-canary-create-promotion.png){ width=95% }

Check the *Enable automatic promotion* box. Now we can define the following auto-starting conditions for the new pipeline:

```
result = 'passed' and (branch = 'master' or tag =~ '^hotfix*')
```

![Automatic promotion](./figures/05-sem-canary-auto-promotion.png){ width=95% }

In the new pipeline, click on the first block. Let's call it “Push”. The push block takes the Docker image that we built earlier and uploads it to the private Container Registry. The secrets and the login command will vary depending on the cloud of choice.

Open the *Secrets* section and check the `do-key` secret.

Type the following commands in the job:

```bash
docker login \
  -u $SEMAPHORE_REGISTRY_USERNAME \
  -p $SEMAPHORE_REGISTRY_PASSWORD \
  $SEMAPHORE_REGISTRY_URL
  
docker pull \
  $SEMAPHORE_REGISTRY_URL/demo:$SEMAPHORE_WORKFLOW_ID
  
docker tag \
  $SEMAPHORE_REGISTRY_URL/demo:$SEMAPHORE_WORKFLOW_ID \
  registry.digitalocean.com/$REGISTRY_NAME/demo:$SEMAPHORE_WORKFLOW_ID

doctl auth init -t $DO_ACCESS_TOKEN
doctl registry login

docker push \
  registry.digitalocean.com/$REGISTRY_NAME/demo:$SEMAPHORE_WORKFLOW_ID
```

![Push block](./figures/05-sem-canary-push-block.png){ width=95% }

Create a new block called “Deploy” and enable secrets:

- `db-params` to use the cloud database;
- `do-key` which is the cloud-specific access token.

Open the *Environment Variables* section:

- Create a variable called `CLUSTER_NAME` with the DigitalOcean cluster name (`semaphore-demo-cicd-kubernetes`)
- Create a variable called `REGISTRY_NAME` with the name of the DigitalOcean container registry name.

To connect with the DigitalOcean cluster, we can use the official `doctl` tool, which comes preinstalled in Semaphore.

Add the following commands to the *job*:

```bash
doctl auth init --access-token $DO_ACCESS_TOKEN
doctl kubernetes cluster kubeconfig save "${CLUSTER_NAME}"
checkout
kubectl apply -f manifests/service.yml

./apply.sh \
  manifests/deployment.yml \
  addressbook-canary 1 \
  registry.digitalocean.com/$REGISTRY_NAME/demo:$SEMAPHORE_WORKFLOW_ID

if kubectl get deployment addressbook-stable; then \
  kubectl scale --replicas=2 deployment/addressbook-stable; \
fi
```

This is the canary job sequence:

  - Create a load balancer service with `kubectl apply`.
  - Execute `apply.sh`, which creates the canary deployment.
  - Reduce the size of the stable deployment with `kubectl scale`.

![Deploy block](./figures/05-sem-canary-deploy-block.png){ width=95% }

Create a third block called “Functional test and migration” and enable the `do-key` secret. Repeat the environment variables. This is the last block in the pipeline and it runs some automated tests on the canary. By combining `kubectl get pod` and `kubectl exec`, we can run commands inside the pod.

Type the following commands in the job:

```bash
doctl auth init --access-token $DO_ACCESS_TOKEN
doctl kubernetes cluster kubeconfig save "${CLUSTER_NAME}"
checkout
POD=$(kubectl get pod -l deployment=addressbook-canary -o name | head -n 1)
kubectl exec -it "$POD" -- npm run ping
kubectl exec -it "$POD" -- npm run migrate
```

![Test block](./figures/05-sem-canary-test-block.png){ width=95% }

## 4.8 Your First Release

So far, so good. Let's see where we are: we built the Docker image, and, after testing it, we’ve setup the one-pod canary deployment pipeline. In this section, we’ll extend the workflow with a stable deployment pipeline.

### 4.8.1 The Stable Deployment Pipeline

The stable pipeline completes the deployment cycle. This pipeline doesn't introduce anything new; again, we use `apply.sh` script to start a rolling update and `kubectl delete` to clean the canary deployment.

Create a new pipeline (using the *Add promotion* button) branching out from the canary and name it “Deploy Stable (DigitalOcean)”.

![Stable promotion](./figures/05-sem-stable-promotion.png){ width=95% }

Create the “Deploy to Kubernetes” block with the `do-key` and `db-params` secrets. Also, create the `CLUSTER_NAME` and `REGISTRY_NAME` variables as we did in the previous step.

In the job command box, type the following lines to make the rolling deployment and delete the canary pods:

```bash
doctl auth init --access-token $DO_ACCESS_TOKEN
doctl kubernetes cluster kubeconfig save "${CLUSTER_NAME}"
checkout
kubectl apply -f manifests/service.yml

./apply.sh \
  manifests/deployment.yml \
  addressbook-stable 3 \
  registry.digitalocean.com/$REGISTRY_NAME/demo:$SEMAPHORE_WORKFLOW_ID

if kubectl get deployment addressbook-canary; then \
  kubectl delete deployment/addressbook-canary; \
fi
```

![Deploy block](./figures/05-sem-stable-deploy-block.png){ width=95% }

Good! We’re done with the release pipeline.

### 4.8.2 Releasing the Canary

Here is the moment of truth. Will the canary work? Click on *Run the workflow* and then *Start*.

Wait until the CI pipeline is done an click on *Promote* to start the canary pipeline[^no-autopromotion].

[^no-autopromotion]: You might be wondering why the automatic promotion hasn’t kicked in for the canary pipeline. The reason is that we set it to trigger only for the master branch, and the Workflow Builder by default saves all its changes on a separate branch called `setup-semaphore`.

![Canary Promote](./figures/05-sem-promote-canary.png)
![Canary Pipeline](./figures/05-sem-canary-pipeline.png)

Once it completes, we can check how the canary is doing.

``` bash
$ kubectl get deployment

NAME                READY UP-TO-DATE AVAILABLE AGE
addressbook-canary  1/1   1          1         8m40s
```

### 4.8.3 Releasing the Stable

In tandem with the canary deployment, we should have a dashboard to monitor errors, user reports, and performance metrics to compare against the baseline. After some pre-determined amount of time, we would reach a go vs. no-go decision. Is the canary version is good enough to be promoted to stable? If so, the deployment continues. If not, after collecting the necessary error reports and stack traces, we rollback and regroup.

Let’s say we decide to go ahead. So go on and hit the *Promote* button next to the stable pipeline.

![Stable Pipeline](./figures/05-sem-stable-pipeline.png){ width=60% }

While the block runs, you should see both the existing canary and a new “addressbook-stable” deployment:

``` bash
$ kubectl get deployment

NAME                READY UP-TO-DATE AVAILABLE AGE
addressbook-canary  1/1   1          1         110s
addressbook-stable  0/3   3          0         1s
```

One at a time, the numbers of replicas should increase until reaching the target of three:

``` bash
$ kubectl get deployment

NAME                READY UP-TO-DATE AVAILABLE AGE
addressbook-canary  1/1   1          1         114s
addressbook-stable  2/3   3          2         5s
```

With that completed, the canary is no longer needed, so it goes away:

``` bash
$ kubectl get deployment

NAME                READY UP-TO-DATE AVAILABLE AGE
addressbook-stable  3/3   3          3         12s
```

Check the service status to see the external IP:

``` bash
$ kubectl get service

NAME            TYPE         EXTERNAL-IP    PORT(S)
addressbook-lb  LoadBalancer 35.225.210.248 80:30479/TCP
kubernetes      ClusterIP    <none>         443/TCP
```

We can use curl to test the API endpoint directly. For example, to create a person in the addressbook:

``` bash
$ curl -w "\n" -X PUT \
  -d "firstName=Sammy&lastName=David Jr" \
  34.68.150.168/person

{
    "id": 1,
    "firstName": "Sammy",
    "lastName": "David Jr",
    "updatedAt": "2019-11-10T16:48:15.900Z",
    "createdAt": "2019-11-10T16:48:15.900Z"
}
```

To retrieve all persons, try:

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

### 4.8.4 The Rollback Pipeline

Fortunately, Kubernetes and CI/CD make an exceptional team when it comes to recovering from errors. Let’s say that we don’t like how the canary performs or, even worse, the functional tests at the end of the canary deployment pipeline fails. In that case, wouldn’t be great to have the system go back to the previous state automatically? What about being able to undo the change with a click of a button? This is exactly what we are going to create in this step, a rollback pipeline [^no-db-rollback].

[^no-db-rollback]: This isn’t technically true for applications that use databases, changes to the database are not automatically rolled back. We should use database backups and migration scripts to manage upgrades.

Open the Workflow Builder once more and go to the end of the canary pipeline. Create a new promotion branching out of it, check the *Enable automatic promotion* box, and set this condition:

```text
result = 'failed'
```

![Rollback promotion](./figures/05-sem-rollback-promotion.png){ width=95% }

The rollback job collects information to help diagnose the problem. Create a new block called “Rollback Canary”, import the `do-ctl` secret, and create `CLUSTER_NAME` and `REGISTRY_NAME`.  Type these lines in the job:

```bash
doctl auth init --access-token $DO_ACCESS_TOKEN
doctl kubernetes cluster kubeconfig save "${CLUSTER_NAME}"
kubectl get all -o wide
kubectl get events
kubectl describe deployment addressbook-canary || true
POD=$(kubectl get pod -l deployment=addressbook-canary -o name | head -n 1)
kubectl logs "$POD" || true

if kubectl get deployment addressbook-stable; then \
  kubectl scale --replicas=3 \
  deployment/addressbook-stable; \
fi

if kubectl get deployment addressbook-canary; then \
  kubectl delete deployment/addressbook-canary;  \
fi
```

The first four lines print out information about the cluster. The last two, undoes the changes by scaling up the stable deployment and removing the canary.

![Rollback block](./figures/05-sem-rollback-block.png){ width=95% }

Run the workflow once more and make a canary release, but this time try rollback pipeline by clicking on its promote button:

![Rollback Pipeline](./figures/05-sem-rollback-canary.png){ width=60% }

And we’re back to normal, phew\! Now its time to check the job logs to see what went wrong and fix it before merging to master again.

**But what if we discover a problem after we deploy a stable release?** Let’s imagine that a defect sneaked its way into production. It can happen, maybe there was some subtle bug that no one found out hours or days in. Or perhaps some error not picked up by the functional test. Is it too late? Can we go back to the previous version?

The answer is yes, we can go to the previous version, but a manual intervention is required. Remember that we tagged each Docker image with a unique ID (the `SEMAPHORE_WORKFLOW_ID`)? We can re-promote the stable deployment pipeline from the last good version in Semaphore. If the Docker image is no longer in the registry, we can just regenerate it using the *Rerun* button in the top right corner.

### 4.8.5 Troubleshooting and Tips

Even the best plans can fail; failure is certainly an option in the software development. Maybe the canary is presented with some unexpected errors, perhaps it has performance problems, or we merged the wrong branch into master. The important thing is (1) learn something from them, and (2) know how to go back to solid ground.

Kubectl can give us a lot of insights into what is happening. First, get an overall picture of the resources on the cluster.

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

If you need to jump in one of the containers, you can start a shell as long as the pod is running with:

``` bash
$ kubectl exec -it <pod-name> -- sh
```

To access a pod network from your machine, forward a port with `port-forward`, for instance:

``` bash
  $ kubectl port-forward <pod-name> 8080:80
```

These are some common error messages that you might run into:

  - Manifest is invalid: it usually means that the manifest YAML syntax is incorrect. Use `kubectl --dry-run` or `--validate` options verify the manifest.
  - `ImagePullBackOff` or `ErrImagePull`: the requested image is invalid or was not found. Check that the image is in the registry and that the reference in the manifest is correct.
  - `CrashLoopBackOff`: the application is crashing, and the pod is shutting down. Check the logs for application errors.
  - Pod never leaves `Pending` status: this could mean that one of the Kubernetes secrets are missing.
  - Log message says that “container is unhealthy”: this message may show that the pod is not passing a probe. Check that the probe definitions are correct.
  - Log message says that there are “insufficient resources”: this may happen when the cluster is running low on memory or CPU.

## 4.9 Summary

You have learned how to put together the puzzle of CI/CD, Docker, and Kubernetes into a practical application. In this chapter, you have put in practice all that you’ve learned in this book:

  - How to setup pipelines in Semaphore CI/CD and use them to deploy to the cloud.
  - How to build Docker images and start a dev environment with the help of Docker Compose.
  - How to do canary deployments and rolling updates in Kubernetes.
  - How to scale deployments and how to recover when things don’t go as planned.

Each of the pieces had its role: Docker brings portability, Kubernetes adds orchestration, and Semaphore CI/CD drives the test and deployment process.
