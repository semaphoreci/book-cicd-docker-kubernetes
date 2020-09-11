BUILD = build
BOOKNAME = CICD_with_Docker_Kubernetes_Semaphore
TITLE = title.txt
CHAPTERS = chapters/01-introduction.md chapters/02-using-docker.md \
	chapters/03-kubernetes-deployment.md chapters/04-cicd-best-practices.md \
	chapters/05-tutorial-intro.md chapters/06-tutorial-semaphore.md \
	chapters/07-tutorial-clouds.md chapters/08-tutorial-deployment.md \
	chapters/09-final-words.md

all: book html

book: epub pdf html

clean:
	rm -fr $(BUILD)

pdf: $(BUILD)/pdf/$(BOOKNAME).pdf
epub: $(BUILD)/epub/$(BOOKNAME).epub

html: $(BUILD)/html/$(BOOKNAME).html

$(BUILD)/pdf/$(BOOKNAME).pdf: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/pdf
	docker run --rm --volume `pwd`:/data pandoc/latex:2.6 -f markdown-implicit_figures -H make-code-small.tex -V geometry:margin=1.5in -o /data/$@ $^

# $(BUILD)/html/$(BOOKNAME).html: $(TITLE) $(CHAPTERS)
# 	mkdir -p $(BUILD)/html
# 	docker run --rm --volume `pwd`:/data $(TOC) pandoc/latex:2.6 --standalone --to=html5 -o /data/$@ $^


$(BUILD)/html/$(BOOKNAME).html: title-html.txt $(CHAPTERS)
	mkdir -p $(BUILD)/html
	docker run --rm --volume `pwd`:/data pandoc/crossref:2.10 \
		-o /data/$@ $^
	mv -f build/html/* tests/html-css.html


# --self-contained \
# --toc \
# --css epub-cmichel.css \
#
# cp -r figures test/
# ebook-convert tests/html-css.html tests/html-css.epub --extra-css epub-cmichel.css --cover cover/cover.jpg
# TODO: find language, extract-toc, embed-font options in ebook-converter
#    TOC doesn't work (even with --toc) 
#    this expression *seems* to work in calibre: //*[((name()='h1' or name()='h2'))]

# $(BUILD)/epub/$(BOOKNAME).epub: title-css.txt $(CHAPTERS)
# 	mkdir -p $(BUILD)/epub
# 	docker run --rm --volume `pwd`:/data pandoc/crossref:2.10 \
# 		--css epub-cmichel.css \
# 		--epub-cover-image cover/cover.jpg \
# 		-o /data/$@ $^
# 	mv -f build/epub/* tests/plain-css.epub

$(BUILD)/epub/$(BOOKNAME).epub: title-plain.txt $(CHAPTERS)
	mkdir -p $(BUILD)/epub
	docker run --rm --volume `pwd`:/data pandoc/crossref:2.10 \
		--epub-cover-image cover/cover.jpg \
		-o /data/$@ $^
	mv -f build/epub/* tests/plain-plain.epub

# test/plain.epub: epub output no specials, title-plain.txt
# test/plain-css.epub: epub output --css epub-cmichel.css, title-css.txt
# test/html-css.html: html output --css epub-cmichel.css, title-css.txt

# -f markdown-implicit_figures \
# --css epub.css \
# --epub-embed-font=fonts/SourceCodePro/SourceCodePro-Regular.ttf \
# -H make-code-small.tex \
# -V geometry:margin=1.5in \

.PHONY: all book clean pdf html epub
