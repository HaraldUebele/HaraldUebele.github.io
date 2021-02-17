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
last_modified_at: "2021-MM-DD"
published: false
excerpt_separator: <!--more-->
allow_comments: "yes"
---
```

excerpt_separator: `<!--more-->`  --> Place the seperator after the text to be displayed in blog summary. Helpful if first paragraph is very short.  

allow_comments: "no" disables the comments (utteranc.es) section

## Images:

Folder for year and month under /images

`![Comment](/images/yyyy/mm/source-sink.png)`

Image title with block attributes below:

```
This is an image title
{:style="color:gray;font-style:italic;font-size:90%;text-align:center;"}
```
This is an image title
{:style="color:gray;font-style:italic;font-size:90%;text-align:center;"}


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
