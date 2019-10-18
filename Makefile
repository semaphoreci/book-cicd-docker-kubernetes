BUILD = build
BOOKNAME = CICD_with_Docker_Kubernetes_Semaphore
TITLE = title.txt
CHAPTERS = chapters/01-introduction.md

all: book

book: pdf #epub

clean:
	rm -r $(BUILD)

pdf: $(BUILD)/pdf/$(BOOKNAME).pdf

$(BUILD)/pdf/$(BOOKNAME).pdf: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/pdf
	pandoc -o $@ $^

.PHONY: all book clean pdf #epub
