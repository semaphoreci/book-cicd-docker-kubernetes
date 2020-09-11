BUILD = build
BOOKNAME = CICD_with_Docker_Kubernetes_Semaphore
TITLE = title.txt
CHAPTERS = chapters/01-introduction.md chapters/02-using-docker.md \
	chapters/03-kubernetes-deployment.md chapters/04-cicd-best-practices.md \
	chapters/05-tutorial-intro.md chapters/06-tutorial-semaphore.md \
	chapters/07-tutorial-clouds.md chapters/08-tutorial-deployment.md \
	chapters/09-final-words.md

all: book html mobi

book: epub pdf html mobi

clean:
	rm -fr $(BUILD)

pdf: $(BUILD)/pdf/$(BOOKNAME).pdf
epub: $(BUILD)/epub/$(BOOKNAME).epub
mobi: $(BUILD)/mobi/$(BOOKNAME).mobi
html: $(BUILD)/html/$(BOOKNAME).html

$(BUILD)/pdf/$(BOOKNAME).pdf: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/pdf
	docker run --rm --volume `pwd`:/data pandoc/latex:2.6 -f markdown-implicit_figures -H make-code-small.tex -V geometry:margin=1.5in -o /data/$@ $^

$(BUILD)/html/$(BOOKNAME).html: title.txt $(CHAPTERS)
	mkdir -p $(BUILD)/html
	ln -sf ../../figures/ build/html
	docker run --rm --volume `pwd`:/data pandoc/crossref:2.10 -o /data/$@ $^
	
# mv -f build/html/* tests/html-css.html

# issues:
# embed fonts
# footnotes show a 'V15' char on kindle device
# style: line-height, pre left-margin
#
# kindle-optimized epub
$(BUILD)/epub/$(BOOKNAME).epub: $(BUILD)/html/$(BOOKNAME).html
	mkdir -p $(BUILD)/epub
	ebook-convert $^ $@ \
		--authors "Marko Anastasov&Jérôme Petazzoni&Tomas Fernandez" \
		--book-producer Semaphore \
		--publisher Semaphore \
		--title "TEST CALIBRE 2" \
		--language en-US \
		--comments "How to Deliver Cloud Native Applications at High Velocity" \
		--epub-version 3 \
		--extra-css styles/epub-kindle.css \
		--cover cover/cover.jpg \
		--output-profile kindle \
		--chapter "//*[name()='h1' or name()='h2']"

# mobipocket format, also compatible with kindle
$(BUILD)/mobi/$(BOOKNAME).mobi: $(BUILD)/epub/$(BOOKNAME).epub
	mkdir -p $(BUILD)/mobi
	ebook-convert $^ $@

.PHONY: all book clean pdf html epub
