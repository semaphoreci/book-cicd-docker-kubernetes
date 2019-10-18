BUILD = build
BOOKNAME = CICD_with_Docker_Kubernetes_Semaphore
TITLE = title.txt
CHAPTERS = ch01.md ch02.md ch03.md ch04.md

all: book

book: pdf #epub html

clean:
	rm -r $(BUILD)

pdf: $(BUILD)/pdf/$(BOOKNAME).pdf

$(BUILD)/pdf/$(BOOKNAME).pdf: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/pdf
	pandoc -o $@ $^

.PHONY: all book clean pdf #epub html
