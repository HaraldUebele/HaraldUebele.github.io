
## Dateiname:

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

## Bilder:

Pro Monat und Jahr ein Ordner unter /images

`![Kommentar](/images/yyyy/mm/source-sink.png)`

Bildunterschrift (X) zentriert:

```
{:center: style="font-size: 90%; text-align: center"}
_X_
{:center}
```

## Link in neuem Fenster öffnen

`[Knative Runtime Contract](https://github.com/knative/serving/blob/master/docs/runtime-contract.md){:target="_blank"}`

## Preformatted:

	```sh
	```

	```yaml
	```

## Escape characters?

Beim Exportieren könnten Escape Character \ eingefügt worden sein.

# FYI

## Read time

https://int3ractive.com/blog/2018/jekyll-read-time-without-plugins/

## Render locally

https://github.com/Starefossen/docker-github-pages

docker run -it --rm -v "$PWD":/usr/src/app -p "4000:4000" starefossen/github-pages

http://localhost:4000
