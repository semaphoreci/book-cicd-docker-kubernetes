# CI/CD with Docker and Kubernetes Book

<a href="https://semaphoreci.com/resources/cicd-docker-kubernetes?utm_source=github&utm_medium=readme&utm_campaign=cicd-docker-kubernetes-semaphore&utm_content=cover">"<img src="cover/cover.jpg" width="300"></a>

---

**[Download ebook/PDF from Semaphore website](https://semaphoreci.com/resources/cicd-docker-kubernetes?utm_source=github&utm_medium=readme&utm_campaign=cicd-docker-kubernetes-semaphore&utm_content=link)**

---

## Production

![Semaphore build](https://semaphore-oss.semaphoreci.com/badges/book-cicd-docker-kubernetes.svg)

Content is written in Markdown, final PDF made with [Pandoc][pandoc].

We're using official [Docker images of Pandoc][pandoc-docker].
You need to have Docker installed to build the PDF. See `Makefile`.

Semaphore automatically creates and uploads the PDF as an artifact from the
latest version of source text. See [project on Semaphore][semaphore-project].

## Writing

Markdown source intentionally doesn't include new lines at 80 characters. This
is so that text is easy to paste and edit in editors like iA Writer and
Hemingway.

## Copyright & License

Copyright © 2020 Rendered Text.

This work is licensed under CC BY-NC-ND 4.0 <a href="https://creativecommons.org/licenses/by-nc-nd/4.0"><img height="11" style="margin-left: 3px;vertical-align:text-bottom;" src="https://search.creativecommons.org/static/img/cc_icon.svg" /><img height="11" style="margin-left: 3px;vertical-align:text-bottom;" src="https://search.creativecommons.org/static/img/cc-by_icon.svg" /><img height="11" style="margin-left: 3px;vertical-align:text-bottom;" src="https://search.creativecommons.org/static/img/cc-nc_icon.svg" /><img height="11" style="important;margin-left: 3px;vertical-align:text-bottom;" src="https://search.creativecommons.org/static/img/cc-nd_icon.svg" /></a>

[pandoc]: https://pandoc.org
[pandoc-docker]: https://github.com/pandoc/dockerfiles
[semaphore-project]: https://semaphore-oss.semaphoreci.com/projects/book-cicd-docker-kubernetes
