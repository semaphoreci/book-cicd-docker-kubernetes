# CI/CD with Docker, Kubernetes and Semaphore Ebook

![Semaphore build](https://semaphore-oss.semaphoreci.com/badges/book-cicd-docker-kubernetes.svg)

## PDF creation

Content is written in Markdown, final PDF made with [Pandoc][pandoc].

We're using official [Docker images of Pandoc][pandoc-docker].
You need to have Docker installed to build the PDF. See `Makefile`.

Semaphore automatically creates and uploads the PDF as an artifact from the
latest version of source text. See [project on Semaphore][semaphore-project].

## Writing

Markdown source intentionally doesn't include new lines at 80 characters. This
is so that text is easy to paste and edit in editors like iA Writer and
Hemingway.

[pandoc]: https://pandoc.org
[pandoc-docker]: https://github.com/pandoc/dockerfiles
[semaphore-project]: https://semaphore-oss.semaphoreci.com/projects/book-cicd-docker-kubernetes
