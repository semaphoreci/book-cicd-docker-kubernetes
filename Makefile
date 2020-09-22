BUILD = build
BOOKNAME = CICD_with_Docker_Kubernetes_Semaphore
TITLE = title.txt
CHAPTERS = chapters/01-introduction.md chapters/02-using-docker.md \
	chapters/03-kubernetes-deployment.md chapters/04-cicd-best-practices.md \
	chapters/05-tutorial-intro.md chapters/06-tutorial-semaphore.md \
	chapters/07-tutorial-clouds.md chapters/08-tutorial-deployment.md \
	chapters/09-final-words.md

CHAPTERS_EPUB = chapters/01-introduction.md chapters/02-using-docker.md \
	chapters/03-kubernetes-deployment.md chapters/04-cicd-best-practices.md \
	chapters/05-tutorial-intro.md chapters/06-tutorial-semaphore.md \
	chapters/07-tutorial-clouds.md chapters/08-tutorial-deployment.md \
	chapters/09-final-words-epub.md

all: book 

book: pdf epub azw3 mobi
ebook: epub azw3 mobi

clean:
	rm -fr $(BUILD)

pdf: $(BUILD)/pdf/$(BOOKNAME).pdf
epub: $(BUILD)/epub/$(BOOKNAME).epub
mobi: $(BUILD)/mobi/$(BOOKNAME).mobi
azw3: $(BUILD)/azw3/$(BOOKNAME).azw3
html: $(BUILD)/html/$(BOOKNAME).html

$(BUILD)/pdf/$(BOOKNAME).pdf: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/pdf
	docker run --rm --volume `pwd`:/data pandoc/latex:2.6 -f markdown-implicit_figures -H make-code-small.tex -V geometry:margin=1.5in -o /data/$@ $^

# intermediate format for epub, override small figures
$(BUILD)/html/$(BOOKNAME).html: title.txt $(CHAPTERS_EPUB)
	mkdir -p $(BUILD)/html $(BUILD)/html/figures
	cp figures/* $(BUILD)/html/figures
	cp figures-small/* $(BUILD)/html/figures
	docker run --rm --volume `pwd`:/data pandoc/crossref:2.10 -o /data/$@ $^
	
# issues:
# embed fonts
# footnotes show a 'V15' char on kindle device
# style: line-height, pre left-margin
 
# kindle-optimized epub
$(BUILD)/epub/$(BOOKNAME).epub: $(BUILD)/html/$(BOOKNAME).html
	mkdir -p $(BUILD)/epub
	docker run --rm --volume `pwd`:/data --entrypoint ebook-convert -w /data linuxserver/calibre $^ /data/$@ \
		--output-profile kindle \
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

# --embed-all-fonts \
# --subset-embedded-fonts \
# --authors "Marko Anastasov&Jérôme Petazzoni&Tomas Fernandez"
# --extra-css /data/styles/epub-kindle.css \

# amazon kindle format
$(BUILD)/azw3/$(BOOKNAME).azw3: $(BUILD)/epub/$(BOOKNAME).epub
	mkdir -p $(BUILD)/azw3
	docker run --rm --volume `pwd`:/data --entrypoint ebook-convert -w /data linuxserver/calibre $^ /data/$@ 


# mobipocket format, compatible with kindle
$(BUILD)/mobi/$(BOOKNAME).mobi: $(BUILD)/epub/$(BOOKNAME).epub
	mkdir -p $(BUILD)/mobi
	docker run --rm --volume `pwd`:/data --entrypoint ebook-convert -w /data linuxserver/calibre $^ /data/$@ 

.PHONY: all book clean pdf html epub azw3 mobi
