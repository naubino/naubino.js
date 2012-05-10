ful_TARGET = Naubino.full.js
min_TARGET = Naubino.min.js
all_TARGETS := $(ful_TARGET) $(min_TARGET)

SRC_DIR = coffee/
DOC_DIR = docs/
LIB_DIR = lib/
TMP_DIR = js/

SRC := $(shell find $(SRC_DIR) -type f -iname \*.coffee)
TMP := $(SRC:$(SRC_DIR)%.coffee=$(TMP_DIR)%.js)


all:       $(min_TARGET)
js:        $(TMP)
libs:      $(LIB_DIR)
doc:       $(DOC_DIR)
readable:  $(ful_TARGET)


$(min_TARGET): $(TMP)
	r.js -o name=Load out=./$@ baseUrl=js

$(ful_TARGET) : $(TMP)
	r.js -o name=Load out=./$@ baseUrl=js optimize=none
	cp $@ $(min_TARGET)

$(SRC): $(TMP_DIR)

$(TMP): $(SRC)
	coffee -p -c $< > $@

$(DOC_DIR): $(SRC_DIR)
	codo -o $@ $<

$(TMP_DIR):
	mkdir $(TMP_DIR)

watch: $(TMP_DIR)
	coffee -o $(TMP_DIR) -cw $(SRC_DIR)

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
