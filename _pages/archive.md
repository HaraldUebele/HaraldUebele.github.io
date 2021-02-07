---
layout: page
title: Blog entries by year
permalink: /archive/
---

{% for tag in site.tags %}
  <h3>{{ tag[0] }}</h3>
  <ul style="list-style: none;">
    {% for post in tag[1] %}
      <li>{{ post.date | date: "%m/%d" }}  <a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endfor %}
  </ul>
{% endfor %}