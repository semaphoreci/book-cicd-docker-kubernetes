BUILD = build
BOOKNAME = CICD_with_Docker_Kubernetes_Semaphore
TITLE = title.txt
CHAPTERS = chapters/01-introduction.md chapters/02-using-docker.md \
	chapters/03-kubernetes-deployment.md chapters/04-cicd-best-practices.md \
	chapters/05-tutorial-intro.md chapters/06-tutorial-semaphore.md \
	chapters/07-tutorial-clouds.md chapters/08-tutorial-deployment.md \
	chapters/09-final-words.md

CHAPTERS_EBOOK = chapters/01-introduction-ebook.md chapters/02-using-docker.md \
	chapters/03-kubernetes-deployment.md chapters/04-cicd-best-practices.md \
	chapters/05-tutorial-intro.md chapters/06-tutorial-semaphore.md \
	chapters/07-tutorial-clouds.md chapters/08-tutorial-deployment.md \
	chapters/09-final-words-ebook.md

all: book 

book: pdf ebook
ebook: epub mobi
pdf: $(BUILD)/pdf/$(BOOKNAME).pdf
epub: $(BUILD)/epub/$(BOOKNAME).epub
mobi: $(BUILD)/mobi/$(BOOKNAME).mobi
azw3: $(BUILD)/azw3/$(BOOKNAME).azw3
html: $(BUILD)/html/$(BOOKNAME).html

clean:
	rm -r $(BUILD)

$(BUILD)/pdf/$(BOOKNAME).pdf: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/pdf
	docker run --rm --volume `pwd`:/data pandoc/latex:2.6 -f markdown-implicit_figures -H make-code-small.tex -V geometry:margin=1.5in -o /data/$@ $^

# intermediate format for epub, uses small figures
$(BUILD)/html/$(BOOKNAME).html: title.txt $(CHAPTERS_EBOOK)
	mkdir -p $(BUILD)/html $(BUILD)/html/figures
	cp figures/* $(BUILD)/html/figures
	cp figures-ebook/* $(BUILD)/html/figures
	docker run --rm --volume `pwd`:/data pandoc/crossref:2.10 -o /data/$@ $^
 
# kindle-optimized epub
# note: output-profile=tablet converts best to kindle
$(BUILD)/epub/$(BOOKNAME).epub: $(BUILD)/html/$(BOOKNAME).html
	mkdir -p $(BUILD)/epub
	docker run --rm --volume `pwd`:/data --entrypoint ebook-convert -w /data linuxserver/calibre $^ /data/$@ \
		--output-profile tablet \
		--chapter "//*[name()='h1' or name()='h2']" \
		--publisher "Semaphore" \
		--book-producer "Semaphore" \
		--cover cover/cover.jpg \
		--epub-version 3 \
		--extra-css /data/styles/epub-kindle.css \
		--language "$(shell egrep '^language:' title.txt | cut -d: -f2 | sed -e 's/^[[:space:]]*//')" \
		--title "$(shell egrep '^title:' title.txt | cut -d: -f2 | sed -e 's/^[[:space:]]*//')" \
		--comments "$(shell egrep '^subtitle:' title.txt | cut -d: -f2 | sed -e 's/^[[:space:]]*//')" \
		--authors "$(shell egrep '^author:' title.txt | cut -d: -f2 | sed -e 's/^[[:space:]]*//')"

# mobipocket format
$(BUILD)/mobi/$(BOOKNAME).mobi: $(BUILD)/epub/$(BOOKNAME).epub
	mkdir -p $(BUILD)/mobi
	docker run --rm --volume `pwd`:/data --entrypoint ebook-convert -w /data linuxserver/calibre $^ /data/$@ 

# amazon kindle format (for testing)
$(BUILD)/azw3/$(BOOKNAME).azw3: $(BUILD)/epub/$(BOOKNAME).epub
	mkdir -p $(BUILD)/azw3
	docker run --rm --volume `pwd`:/data --entrypoint ebook-convert -w /data linuxserver/calibre $^ /data/$@ 

.PHONY: all book clean pdf html epub azw3 mobi
