Title:	MultiMarkdown CMS  
Author:	Fletcher T. Penney  
Date:	January 31, 2010  
Tags:	MultiMarkdown, web, server  

# Introduction #

MultiMarkdown CMS is basically a collection of utilities that allows you to
run a web site without any other software. I have tried a variety of packages
when hosting my own web site. In the end, however, I was basically using those
programs to put a wrapper around my content, which was always managed by
MultiMarkdown. Additionally, none of those programs really fit into my
workflow, and the performance was often not what I would like.

So, instead, I decided to run my web site with a minimal amount of software.
In fact, it could be run with MultiMarkdown alone, but I would miss out on
some of the interactive features.

The basic premise is:

* Create a plain text file (in MMD syntax) for each page of the site

* use `mmd2web.pl` to convert to XHTML, including some markup to format the
  pages for the web site

* upload the XHTML file (and optionally the txt file) to your web server, and
  you're off

The newly formatted XHTML file includes SSI code that causes Apache to add
certain templates to the page. This allows you to standardize the appearance
of each page (e.g. headers, footers, sidebar, etc).

Additionally, CGI scripts are included to manage archives, Atom feeds, tags,
searching, OpenID authentication, comments, and more.

When building the system, I started off with a collection of essentially
static web pages. I then added cgi scripts only where I thought they were
absolutely necessary to give my site the interactive features I desired. If
you're someone who likes lots of widgets and gadgets on their site --- I won't
be programming them. However, because of the simple philosophy behind this
approach, the pages should be compatible with just about anything you want to
add that doesn't require a backend database.

However, keep in mind that my goal is simplicity. I don't want lots of
plugins, extensions, modules, etc. I don't want lots of different themes that
I can choose from. If you want these things, then another package might be for
you. But if you want a simple method of creating a web site that focuses on
content, this may be for you.

This package certainly requires more tinkering than a prebuilt solution. If
you're not familiar with .htaccess files, configuring apache, changing file
permissions, and examining error logs then you might run into some roadblocks.
However, that could also be considered an opportunity to track down solutions!


# Where do I get it? #


You can download the package:

<http://github.com/fletcher/MultiMarkdown-CMS>

You can also use git to clone the source:

	git clone git://github.com/fletcher/MultiMarkdown-CMS.git

If you know how to use git, I recommend that approach for reasons that will
become clear later.


# How do I install it? #

Once you download and unpack the software, place the directory where your web
server software expects it.

*Please note: if you have trouble installing the software, do a web search to
figure out what to do. I'm happy to help troubleshoot my software, but I don't
want to get into trying to troubleshoot everyone's web server setup....*


For example, I place mine in `/Users/fletcher/Sites/mmd-static`.


You should now be able to go to something like:

	http://127.0.0.1/~fletcher/mmd_static/index.html

And see *something* --- it will likely give you some error messages, however.


# How to configure Apache #

By default, MultiMarkdown CMS expects to be at the "root" of your web server,
not tucked away at `/~fletcher/mmd_static/`.

To fix this, we need to configure a virtual host in Apache, or your web server
of choice.

For Apache 2 on a Mac, do the following (all others will need to seek help
elsewhere):

* as an admin, go to `/etc/apache2/extra`
* `sudo pico httpd-vhosts.conf` (or similar)
* add something like the following at the end of the file:

		<VirtualHost *:80>
			DocumentRoot "/Users/fletcher/Sites/mmd_static"
			ServerName mmd.local
		</VirtualHost>

then add the following to `/etc/hosts`:

	127.0.0.1       mmd.local

If you restart Web Sharing in the control panel, you should now be able to
access your site by pointing your browser to `http://mmd.local/`. It should
look much better than the first time, but the default CSS is *ugly*. There are
two sample articles, and one sample tag, to get you started.


# How do I add content to my site? #

You can add content anywhere within the MultiMarkdown CMS directory. You can
create folders, and bury your content away. Keep in mind that the archives
feature only locates pages in a `/YYYY/MM/` folder, e.g. the sample posts in
`/2010/01/`. Other folders are not treated as "blog posts". My site is an
example of this structure.

To process the files into HTML, you need to have a working installation of
[MultiMarkdown](http://fletcherpenney.net/multimarkdown/).

Once you add the text files, you need to run `mmd2web.pl` to create an
appropriate html file. This uses the `xhtml-static-site.xslt` file to add the
appropriate templates to your documents. You will also need to change the
permissions on your `.html` files so that the execute bit is enabled (because
I use
[XBitHack](http://httpd.apache.org/docs/1.3/mod/mod_include.html#xbithack) to
enable SSI without screwing everything else up).

Now you just need to customize your templates and CSS files to make everything
look pretty....


# Features #


Included with MultiMarkdown-CMS are several cgi scripts that add additional
features:

* pages in the `/YYYY/MM/` hierarchy are treated as "blog posts" - organized
  by date

* an archive of blog posts is available at `/archives/`, you can also go to
  any year or year/month and see a list of posts in that month

* visitors can leave comments on any blog post (by default comments are not
  accepted on other pages)

* visitors are authenticated via OpenID for leaving comments

* two Atom feeds are generated automatically - one for blog posts, and one for
  comments

* `/sitemap.xml` generates a Google compatible sitemap of the content of your
  site

* by default, the home page lists the last 15 blog posts

* by default, `index.html` pages show a list of the other pages within that
  folder

* a built-in search function is available (though setting up a [Custom Search Engine](http://www.google.com/cse/) isn't a bad idea either)

* a list of similar pages can be added to each page in the site

* several tag related features are available automatically

These features are all demonstrated by the default configuration - feel free
to modify the scripts as needed for your own requirements.


# Settings #

There are a couple of configuration changes that should be done before going
live with this software:

* the root `.htaccess` file should be changed to reflect your desired time
  zone

* four files in `/cgi/` contain the phrase "enter your password here" --- this
  should be changed to a private passphrase for better security when handling
  OpenID authentication


Obviously, I recommend improving the CSS design, and tweaking the various
templates to construct the look of your site.


# Advanced use of git #

One of the things I really wanted to be able to do was to manage my site on my
laptop, experiment with it to be sure it works after any changes are made, and
only then to upload my changes to the live server. I have tried to design the
cgi scripts so that they configure themselves as much as possible, so that the
same code can be run locally, or from a production server.

My workflow is that I make changes in `/Users/fletcher/Sites/mmd_static/` as
described above. That directory was created as a git clone of the
MultiMarkdown-CMS software(as above).

I then add a remote repository to the git repo:

	git remote add live ssh://user@my.live.host/path/to/public

where the username and host are what I would normally use to ssh into my web
provider. `/path/to/public` is the path to the directory that holds my web
site.

This allows me to use git to upload a copy of my local site to my web host
when I am satisfied with the changes. Additionally, by storing my web site in
a git repository, I can undo changes when I make a mistake, and I can also go
back to any previous version of my site.

One trick, though, is that you have to configure the remote repository to
update the remote copies of all files after every `git push`. To do this, ssh
into your account, and go to the public directory. (You may want to back
everything up at this point....) Then do the following to create the remote
git repository:

	git init
	cd .git/hooks
	pico post-update

and then put the following in the file:

	#!/bin/sh
	#
	cd /path/to/public
	/usr/bin/env -i /usr/local/bin/git reset --hard
	chmod g+s templates/accept_comment.cgi

What this does is force git on the remote server to reset the remote directory
to match the state of the repository itself. Then I change the permissions on
accept_comment.cgi so that it is permission to write to the comments files.

You can, of course, add your own commands to this file as well.

If you use the same approach, whenever you want to upload your changes, simply
type:

	git push live master

Your changes will be uploaded, then the remote repository will be reset so
it's up to date, and the permissions will be fixed on accept_comment.cgi.

Remember, since you have a read-only connection to my github repository, your
changes and private files cannot be uploaded. You can still use `git pull
origin master` to update to the latest version of software I have released.
This should not overwrite any changes you have made, since git is pretty good
at avoiding "collisions".

**NOTE**: This set-up works for me. I don't promise it will work for you, or
that it won't mess something up. I am not a git expert. I simply patched this
together with a lot of help from Google. I can't really offer any support if
it's not working for you.


# Included Software #

This software would not be possible without work previously done for many
other projects:


## Net-OpenID-Consumer ##

* by Brad Fitzpatrick
* <http://search.cpan.org/~mart/Net-OpenID-Consumer/>

Used for OpenID authentication.


## Crypt-DH ##

* by Benjamin Trott
* <http://search.cpan.org/dist/Crypt-DH/>

Crypt-DH is used to enable the OpenID authentication.


## XML-Atom-Simplefeed ##

* by Aristotle Pagaltzis
* <http://search.cpan.org/~aristotle/XML-Atom-SimpleFeed/>

Used to generate the atom feeds.

## VectorMap.pm ##

* by Fletcher T. Penney
* <http://fletcherpenney.net/>

Used to find similar pages, and perform searches of site content.

## Lingua-Stem ##

* by Benjamin Franz and Jim Richardson
* <http://search.cpan.org/dist/Lingua-Stem/>

Used by my VectorMap searching software to improve results


## MultiMarkdown [MMD] ##

* by Fletcher T. Penney
* <http://fletcherpenney.net/multimarkdown/>

MultiMarkdown is my update to John Gruber's
[Markdown](http://daringfireball.net/projects/markdown/) software. It is what
this bundle is based on. To learn more about why you would want to use this
bundle, check out the web page for MultiMarkdown.


## SmartyPants ##

* by John Gruber
* <http://daringfireball.net/projects/smartypants/>

SmartyPants is another program by John Gruber, and is designed to add "smart"
typography to HTML documents, including proper quotes, dashes, and ellipses.
Additionally, there are several variations of the SmartyPants files to handle
different localizations (specifically, Dutch, French, German, and Swedish).
These localizations were provided by Joakim Hertze.


## Text::ASCIIMathML ##

* by Mark Nodine
* <http://search.cpan.org/~nodine/>

This perl module adds support for converting the ASCIIMathML syntax into
MathML markup suitable for inclusion in XHTML documents.

# License #

	Copyright (C) 2010  Fletcher T. Penney <fletcher@fletcherpenney.net>

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the
	   Free Software Foundation, Inc.
	   59 Temple Place, Suite 330
	   Boston, MA 02111-1307 USA
