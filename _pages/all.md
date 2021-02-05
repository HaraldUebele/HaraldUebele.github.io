---
layout: page
title: All blog entries
permalink: /all/
---


<ul>
  {% for post in site.posts %}
    <li>
      {{ page.date | date: "%Y/%m/%d" }} - <a href="{{ post.url }}">{{ post.title }}</a>
    </li>
  {% endfor %}
</ul>