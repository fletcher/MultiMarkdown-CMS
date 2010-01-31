Title:	MultiMarkdown CMS  
Author:	Fletcher T. Penney  
Date:	January 31, 2010  


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

The newly formated XHTML file includes SSI code that causes Apache to add
certain templates to the page. This allows you to standardize the appearance
of each page (e.g. headers, footers, sidebar, etc).

Additionally, CGI scripts are included to manage archives, Atom feeds, tags,
searching, OpenID authentication, comments, and more.

However, keep in mind that my goal is simplicity. I don't want lots of
plugins, extensions, modules, etc. I don't want lots of different themes that
I can choose from. If you want these things, then another package might be for
you. But if you want a simple method of creating a web site that focuses on
content, this may be for you.

This package certainly requires more tinkering than a prebuilt solution. If
you're not familiar with .htaccess files, configuring apache, changing file
permissions, and examining error logs then you might run into some roadblocks.
However, that could also be considered an opportunity to track down solutions!


# Where to download #


# How to install #

# How to configure Apache #


# Features #


# Settings #

OpenID password

htaccess Timezone




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

