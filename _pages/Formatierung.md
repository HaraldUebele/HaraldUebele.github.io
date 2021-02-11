---
layout: page
title: Formatting
permalink: /format/
---


## File name:

yyyy-mm-dd-title.md

## Frontmatter
```
---
layout: post
categories: [XX,YY]
title: This is a new article
date: "2021-MM-DD"
published: false
excerpt_separator: <!--more-->
---
```

## Images:

Folder for year and month under /images

`![Comment](/images/yyyy/mm/source-sink.png)`

Image title (X) centered enclosed in:

```
{:center: style="font-size: 90%; text-align: center"}
_X_
{:center}
```

## Open link in new windows

`{:target="_blank"}`

E.g.

`[Knative Runtime Contract](https://runtime-contract.test){:target="_blank"}`

## Preformatting:

Bash

	```sh
	```

YAML

	```yaml
	```

## Escape characters?

Export could have included escape character `\` 

# FYI

## Read time

Read time based on this:

[https://int3ractive.com/blog/2018/jekyll-read-time-without-plugins/](https://int3ractive.com/blog/2018/jekyll-read-time-without-plugins/)

## Render locally

Helpful for editing

[https://github.com/Starefossen/docker-github-pages](https://github.com/Starefossen/docker-github-pages)

docker run -it --rm -v "$PWD":/usr/src/app -p "4000:4000" starefossen/github-pages

Then open local version here [http://localhost:4000](http://localhost:4000)
