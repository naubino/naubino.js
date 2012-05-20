JOINED_TARGET = Naubino.joined.js
FULL_TARGET = Naubino.full.js
MIN_TARGET = Naubino.min.js
all_TARGETS = $(FULL_TARGET) $(MIN_TARGET) $(JOINED_TARGET)

COFFEE	= /usr/bin/coffee
#COFFEE	= /usr/local/bin/coffee
RJS			= r.js
SRC_DIR = coffee/
DOC_DIR = docs/
LIB_DIR = lib/
TMP_DIR = js/

SRC = $(shell find $(SRC_DIR) -type f -iname \*.coffee)
TMP = $(SRC:$(SRC_DIR)%.coffee=$(TMP_DIR)%.js)


all:       $(MIN_TARGET)
js:        $(TMP)
libs:      $(LIB_DIR)
doc:       $(DOC_DIR)
readable:  $(FULL_TARGET)
joined	:  $(JOINED_TARGET)


$(MIN_TARGET): $(TMP)
	$(RJS) -o name=Load out=./$@ baseUrl=js

$(FULL_TARGET) : $(TMP)
	$(RJS) -o name=Load out=./$@ baseUrl=js optimize=none
	cp $@ $(MIN_TARGET)

$(JOINED_TARGET): $(SRC_DIR)
	$(COFFEE) -j $(JOINED_TARGET) -c $(SRC_DIR)
	cp $@ $(MIN_TARGET)



$(SRC): $(TMP_DIR)

$(TMP_DIR)%.js: $(SRC_DIR)%.coffee
	$(COFFEE) -p -c $< > $@

$(DOC_DIR): $(SRC_DIR)
	codo -o $@ $<

$(TMP_DIR):
	mkdir $(TMP_DIR)

watch: $(TMP_DIR)
	$(COFFEE) -o $(TMP_DIR) -cw $(SRC_DIR)

$(LIB_DIR):
	git submodule update --init


libs: $(LIB_DIR)
	cd lib/zepto; rake

.PHONY:
todo:
	cat doc/TODO

.PHONY: clean
clean:
	rm -f  $(all_TARGETS)
	rm -rf $(TMP_DIR)
	rm -rf $(DOC_DIR)

.PHONY: loc
loc:
	@cat $(SRC) | grep -v '^\s*#' | grep -v "^\s*$$" | wc -l
