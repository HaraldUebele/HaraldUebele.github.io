---
layout: page
title: All blog entries
permalink: /all/
---


<ul class="html-small">
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }} {{ post.date | date: "%Y/%m/%d" }}</a>
    </li>
  {% endfor %}
</ul>