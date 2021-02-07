---
layout: page
title: All blog entries
permalink: /all/
---

{% for post in site.posts %}

        {% capture year_of_current_post %}
        {{ post.date | date: "%Y" }}
        {% endcapture %}

        {% capture year_of_previous_post %}
        {{ post.previous.date | date: "%Y" }}
        {% endcapture %}

        {% if forloop.first %}
        <h2>{{ year_of_current_post }}</h2>
        <ul>
        {% endif %}

          <li>{{ post.date | date: %m/%d" }} <a href="{{ post.url }}">{{ post.title }}</a></li>

        {% if forloop.last %}
        </ul>
        {% else %}
        {% if year_of_current_post != year_of_previous_post %}
        </ul>

        <h2>{{ year_of_previous_post }}</h2>
        <ul>
        {% endif %}
        {% endif %}

{% endfor %}