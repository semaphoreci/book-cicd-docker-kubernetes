# CI/CD with Docker, Kubernetes and Semaphore Ebook

![Semaphore build](https://semaphore.semaphoreci.com/badges/k8s-cicd-book.svg?key=703023bf-c686-4d4a-8538-07e2b1df3e97)

## PDF creation

Content is written in Markdown, final PDF made with [Pandoc][pandoc].

We're using official [Docker images of Pandoc][pandoc-docker].
You need to have Docker installed to build the PDF. See `Makefile`.

Semaphore automatically creates and uploads the PDF as an artifact from the
latest version of source text. See [k8s-cicd-book][semaphore-project] project.

## Writing

Markdown source intentionally doesn't include new lines at 80 characters. This
is so that text is easy to paste and edit in editors like iA Writer and
Hemingway.

[pandoc]: https://pandoc.org
[pandoc-docker]: https://github.com/pandoc/dockerfiles
[semaphore-project]: https://semaphore.semaphoreci.com/projects/k8s-cicd-book
