---
layout: post
title: Display your Github Pages locally
date: "2021-02-10"
---

I am using Github Pages, for this blog, and for some [workshops](https://harald-u.github.io/security-and-microservices/){:target="_blank"}, tutorials, etc. Github Pages uses Jekyll to render the pages and there are instructions on how to setup Jekyll locally to test your content before publishing. I never managed to get them to work, I am not a Ruby expert and something was always missing.

On the other hand, using the `git commit && git push` approach is tedious because Github Pages can take some time before it starts rendering. 

I found the perfect solution, at least for me:

Hans Kristian Flaatten (Starefossen) has created a Docker image to solve this problem, instructions are [here](https://github.com/Starefossen/docker-github-pages){:target="_blank"} in his Github repo.

You open a terminal session in the root directory of your local repo and start the Docker image like this:

```bash
$ docker run -it --rm -v "$PWD":/usr/src/app -p "4000:4000" starefossen/github-pages
```

This mounts your current directory into the image and starts Jekyll. Your pages are served under [http://localhost:4000](http://localhost:4000){:target="_blank"}.

What's really cool: you can keep editing your content and whenever you save it, the rendered pages are regenerated. So when you refresh your browser pointing to `http://localhost:4000` you immediately see the changes!

