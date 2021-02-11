---
layout: post
title: Moving my Blog from Wordpress to Github Pages
date: "2021-02-10"
published: true
last_modified_at: "2021-02-11"
---

While I was still working as a Developer Advocate at IBM, I have maintained a blog on Wordpress.com. Now that I retired, I don't blog much. So I decided to let the Wordpress subscription expire by the end of this year, 2021. But I didn't want to trash all I wrote so I started to play with Github Pages, Jekyll, and other tools. As you can see I have successfully moved my blog to Github Pages, now.

![Moving](/images/2021/02/move-1015582_640.jpg)
{:center: style="font-size: 90%; text-align: center"}
_Image by <a href="https://pixabay.com/de/users/peggy_marco-1553824/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=1015582">Peggy und Marco Lachmann-Anke</a> on <a href="https://pixabay.com/de/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=1015582">Pixabay</a>_
{:center}

I have used Github Pages before to write the instructions for workshops but have always used one of the Github built-in themes. But they don't work well for blogs. There are many other, Jekyll-based themes that can be used with Github Pages and work for blogs. 

#### 1. Select a theme for Github Pages

The one I selected is called ["Reverie"](https://github.com/amitmerchant1990/reverie){:target="_blank"}. I tried it, liked it, modified it and that is what you are looking at right now. The README has great setup instructions.

You need a Github repository named `yourgithubusername.github.io`. Mine is evidently named `haralduebele.github.io` and this is also the URL that the blog will be served from.

You need to modify `_config.yml`, too, before you can see something meaningful.

An important and not too obvious change is the permalink:

```
permalink: /:year/:month/:day/:title/
```

This duplicates the URL format for blog posts from Wordpress.com.

Once you commit and push your changes, it will take a moment and then you can view your new site.

#### 2. Pack your crates

You can export your content on Wordpress.com under 'Tools' - 'Export'. 

I choose to export all content and export the media library:

![wp export](/images/2021/02/wordpress-export.png)

Exported content will be a ZIP file with a XML document. The exported media library is a TAR file that contains the images, etc. sorted in folders by year and month.

What do you do with the huge Wordpress XML? Somebody (Will Boyd, lonekorean)
already thought of that:

#### 3. Convert Wordpress XML to MarkDown

I found a pretty good tool [here](https://github.com/lonekorean/wordpress-export-to-markdown){:target="_blank"}. 

Using it is pretty straightforward using the instructions in the repository. It requires Node.js 12.14 or later.

Unpack the Wordpress XML from the ZIP file into the root of this repository, run the script `node index.js`, and answer the questions.

I had it create folders for years and months. Output looks something like this:

![wp convert](/images/2021/02/wordpress-convert.png)

`index.md` is the actual post. If there is an images folder, it will contain all the images the tool was able to grab or scrape from the XML.

#### 4. Complete the conversion

"wordpress-export-to-markdown" does a pretty good job but it does require moving files and some manual touch up to the blog posts.

##### a. File names

In Jekyll or Reverie respectively, blog entries go into the `_posts` directory. They need to follow a specific name schema: `yyyy-mm-dd-name.md`. The conversion tool creates a name like this for the folders but not for the actual md files. They are all called `index.md`. So you need to rename the files before you copy them over to the `_posts` directory. I have created year directories under `_posts` to make them a little easier to organize.

![posts directory](/images/2021/02/posts-directory.png)

##### b. Images

The images from the `images` folders go to the `images` folder in your new repo. I created year folders and month folders under the year folders to make it manageable. I believe that the XML files didn't contain all images when I exported/converted. But you always have the media export that should contain all the images.

![images directory](/images/2021/02/images-directory.png)

##### c. Frontmatter

The exported index.md files contain frontmatter pulled from Wordpress:

```yaml
---
title: "Serverless and Knative - Part 1: Installing Knative on CodeReady Containers"
date: "2020-06-02"
tags: 
  - "knative"
  - "kubernetes"
  - "serverless"
---
```

But you must add some more. This is what I usually have there, e.g:

```yaml
---
layout: post
title: "Serverless and Knative - Part 1: Installing Knative on CodeReady Containers"
date: "2020-06-02"
categories: [Knative,Kubernetes,Serverless]
published: false
---
```

You need "layout: post" and you can add "categories" which will show up in the post and you can display all your blog entries sorted by categories.

Change `published: false` to `published: true` to make the post visible. 

##### d. Image links and subtitles

Image links should look like this:

```md
![description](/images/yyyy/mm/imagename.ext)
```

This assumes that you also sort the images into years and months folders.

On Wordpress I sometimes used subtitles under images. In the converted blog entries, the subtitles are simply text, which doesn't really look good. I use some code around them like this:

```
{:center: style="font-size: 90%; text-align: center"}
_The text is then centered, smaller, and in italics_
{:center}
```
{:center: style="font-size: 90%; text-align: center"}
_The text is then centered, smaller, and in italics_
{:center}


##### e. Open external links in new windows/tabs

Github markdown cannot do this at its own. But you can simply add the HTML code ({:target="_blank"}) to the link:

```md
[Link Text](https://url){:target="_blank"}
```

##### f. Syntax highlighting

The Reverie theme uses Pygments/Dracula to highlight code in preformatted sections. I found this to be helpful, especially with quoted YAML.

    ```sh
    $ this would be shell commands
    ```

    ```yaml
    and:
      this:
        - would:
            be: yaml
    ```

##### g. Escape characters

Look out for `\` and remove them, they are not needed.

#### 5. Changes to the Theme

I made modifications to the theme, e.g. I changed the font family in style.scss to IBM Plex Sans because that is my favorite font.

I added "read time" to my posts based on this [article](https://int3ractive.com/blog/2018/jekyll-read-time-without-plugins/){:target="_blank"}.

Instead of the search page that is part of the Reverie theme I created an archive page that lists all my blogs sorted by year. This is based on Rafa Garrido's answer in this [Stackoverflow question](https://stackoverflow.com/questions/19086284/jekyll-liquid-templating-how-to-group-blog-posts-by-year){:target="_blank"}.

And some more stuff ... you can go over your top once you figured out how Jekyll works.

### Update: Comments section

Github Pages uses Jekyll to create a static site. You can't include logic which would be needed to add comments.

I looked at [Disqus](https://disqus.com/){:target="_blank"}, the Reverie theme I use is enabled for Disqus. It is an external service and the pages seem to get very heavy and heavily tracked, too.

I read about the idea to use Github Issues to store the comments. I like it and looked at several examples. Then I found [utterances](https://utteranc.es/){:target="_blank"}. It is a Github App that you install in your repository, you do a little configuration, add a piece of code to the `post.html`. That's it. It just works. And its Open Source, too. So this is what you see below. 
