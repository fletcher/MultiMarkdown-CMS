# Makefile for MultiMarkdown-CMS based wikis
# Thanks to Dr. Drang for inspiring me to use make:
#	http://www.leancrew.com/all-this/2008/06/my-no-server-personal-wiki—part-3/


#
# NOTE: You must customize the path to the mmd2web utility!!!

srcfiles := $(filter-out cgi/* templates/* css/* images/* robots.txt, $(wildcard *.txt */*.txt */*/*.txt */*/*/*.txt))

htmlfiles := $(patsubst %.txt, %.html, $(srcfiles))

templates := $(wildcard templates/*.html)


all: $(htmlfiles) cgi/vector_index


cgi/vector_index: $(htmlfiles)
	cd cgi; ./map_my_site.pl > vector_index


%.html: %.txt # $(templates)
# Fix the path to mmd2web (or your preferred command)
	mmd2web.pl $*.txt
	chmod 755  $*.html


clean:
	rm $(htmlfiles)


fast: $(htmlfiles)
