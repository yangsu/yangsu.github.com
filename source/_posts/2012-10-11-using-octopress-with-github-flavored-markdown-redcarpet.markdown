---
layout: post
title: "Using Octopress with Github Flavored Markdown (RedCarpet)"
date: 2012-10-11 11:38
comments: true
categories: [Octopress, Github, RedCarpet, Markdown, GFM]
---
One of the most annoying features of Markdown for me is the fact that newlines within a paragraph are automatically joined, which is one of the reasons why I like [Github Flavored Markdown](http://github.github.com/github-flavored-markdown/) so much.

Ever since I setup my Octopress blog, I've wanted to use it with GFM. I searched around the web and found how to switch the markdown processor for [Jekyll](http://jekyllrb.com/). I came across [this post](http://www.whatwherewhy.me/blog/2012/01/15/changing-the-markdown-processor-in-octopress/) with instructions on switching to [Maruku](http://maruku.rubyforge.org/), which extends Markdown with the ability to create tables, footnotes, custom header ids, etc. I gave it a shot, but quickly realized that there's no option to enable hard warp linebreaks. Back to searching.

<!-- more -->

I then came across [this post](http://stackoverflow.com/questions/373002/better-ruby-markdown-interpreter) on Stackoverflow that compared [Maruku](http://maruku.rubyforge.org/), [BlueCloth](http://www.deveiate.org/projects/BlueCloth), and [RDiscount](https://github.com/rtomayko/rdiscount), none of which offered what I wanted. However, I discovered [RedCarpet](https://github.com/blog/832-rolling-out-the-redcarpet), the open source Markdown processor tha Github uses to render Markdown and GFM pages. Seems like exactly what I was looking for.

Maybe it's because my Google-Fu is not up to par, but I could not find any instructions on using RedCarpet with Octopress. It turned out that I was just not looking for the correct terms. I found [a Stackoverflow answer](http://stackoverflow.com/questions/10759577/underscore-issues-jekyll-redcarpet-github-flavored-markdown?rq=1) on how to [configure Jekyll](https://github.com/mojombo/jekyll/wiki/configuration) with RedCarpet. Perfect!

Below are the instructions for getting Octopress to render Github Flavored Markdown using RedCarpet.

---

1. add `gem 'redcarpet', '~> 2.1.1'` to `Gemfile` in the Octopress directory
2. run `bundle install --no-deployment` to install RedCarpet
3. Install [@nono](https://github.com/nono)'s [RedCarpet Jekyll Plugin](https://github.com/nono/Jekyll-plugins) by saving it as `redcarpet2_markdown.rb` in the `plugins` folder

``` ruby redcarpet2_markdown.rb https://github.com/nono/Jekyll-plugins/blob/master/redcarpet2_markdown.rb View on Github
require 'fileutils'
require 'digest/md5'
require 'redcarpet'
require 'albino'

PYGMENTS_CACHE_DIR = File.expand_path('../../_cache', __FILE__)
FileUtils.mkdir_p(PYGMENTS_CACHE_DIR)

class Redcarpet2Markdown < Redcarpet::Render::HTML
  def block_code(code, lang)
    lang = lang || "text"
    path = File.join(PYGMENTS_CACHE_DIR, "#{lang}-#{Digest::MD5.hexdigest code}.html")
    cache(path) do
      colorized = Albino.colorize(code, lang)
      add_code_tags(colorized, lang)
    end
  end

  def add_code_tags(code, lang)
    code.sub(/<pre>/, "<pre><code class=\"#{lang}\">").
         sub(/<\/pre>/, "</code></pre>")
  end

  def cache(path)
    if File.exist?(path)
      File.read(path)
    else
      content = yield
      File.open(path, 'w') {|f| f.print(content) }
      content
    end
  end
end

class Jekyll::MarkdownConverter
  def extensions
    Hash[ *@config['redcarpet']['extensions'].map {|e| [e.to_sym, true] }.flatten ]
  end

  def markdown
    @markdown ||= Redcarpet::Markdown.new(Redcarpet2Markdown.new(extensions), extensions)
  end

  def convert(content)
    return super unless @config['markdown'] == 'redcarpet2'
    markdown.render(content)
  end
end
```
4. Replace `markdown: rdiscount` in `_config.yml` with the following
``` ruby
markdown: redcarpet2
redcarpet:
  extensions: ["hard_wrap"]
```

That should be it! Now the lines should be hard wrapped. I also have a few other extensions turned on. Below is my extension settings:
``` ruby
extensions: ["hard_wrap", "no_intra_emphasis", "fenced_code_blocks", "autolink", "tables", "with_toc_data", "strikethrough", "superscript"]
```

* `no_intra_emphasis`: `Multiple_underscores_in_words` => Multiple_underscores_in_words
* `fenced_code_blocks`: Don't need to endent to embed code
* `autolink`: URL autolinking => http://google.com test@email.com
* `tables`: allow tables
* `with_toc_data`: add HTML anchors to each header
* `strikethrough`: `~~strikethrough text~~` => ~~strikethrough text~~
* `superscript`: `normaltext ^(superscript)` => normaltext ^(superscript)

More options are described in [RedCarpet's Documentation](https://github.com/vmg/redcarpet).