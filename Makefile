BUILD = build
BOOKNAME = CICD_with_Docker_Kubernetes_Semaphore
TITLE = title.txt
CHAPTERS = chapters/01-introduction.md chapters/02-using-docker.md \
	chapters/03-kubernetes-deployment.md chapters/04-cicd-best-practices.md \
	chapters/05-tutorial-intro.md chapters/06-tutorial-semaphore.md \
	chapters/07-tutorial-clouds.md chapters/08-tutorial-deployment.md \
	chapters/09-final-words.md

all: book

book: epub pdf html

clean:
	rm -r $(BUILD)

pdf: $(BUILD)/pdf/$(BOOKNAME).pdf
epub: $(BUILD)/epub/$(BOOKNAME).epub

html: $(BUILD)/html/$(BOOKNAME).html

$(BUILD)/pdf/$(BOOKNAME).pdf: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/pdf
	docker run --rm --volume `pwd`:/data pandoc/latex:2.6 -f markdown-implicit_figures -H make-code-small.tex -V geometry:margin=1.5in -o /data/$@ $^

$(BUILD)/html/$(BOOKNAME).html: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/html
	docker run --rm --volume `pwd`:/data $(TOC) pandoc/latex:2.6 --standalone --to=html5 -o /data/$@ $^

$(BUILD)/epub/$(BOOKNAME).epub: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/epub
	docker run --rm --volume `pwd`:/data pandoc/latex:2.6 -f markdown-implicit_figures -H make-code-small.tex -V geometry:margin=1.5in --epub-cover-image cover/cover.jpg --css epub.css -o /data/$@ $^

.PHONY: all book clean pdf html epub
