JOINED_TARGET = Naubino.joined.js
FULL_TARGET = Naubino.full.js
MIN_TARGET = Naubino.min.js
all_TARGETS = $(FULL_TARGET) $(MIN_TARGET) $(JOINED_TARGET)

COFFEE	= /usr/bin/coffee
#COFFEE	= /usr/local/bin/coffee
RJS			= r.js
INDEX	  = index.html
SCORE 	= highscore.html
SRC_DIR = coffee/
AUDIO_DIR = sound/
IMG_DIR = images/
DIST_DIR = dist/
DOC_DIR = docs/
LIB_DIR = lib/
TMP_DIR = js/
CSS_DIR = css/

SRC = $(shell find $(SRC_DIR) -type f -iname \*.coffee)
TMP = $(SRC:$(SRC_DIR)%.coffee=$(TMP_DIR)%.js)
LIB_PACK = $(DIST_DIR)$(LIB_DIR)/*.js
LIB_PACK_DIR = $(DIST_DIR)$(LIB_DIR)


LIB = \
lib/signals/dist/signals.min.js\
lib/state-machine/state-machine.min.js\
lib/zepto/dist/zepto.min.js\
lib/chipmunk/cp.min.js\
lib/requirejs/require.js


all:       $(MIN_TARGET)
js:        $(TMP)
doc:       $(DOC_DIR)
dist:      $(DIST)
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

$(TMP): $(TMP_DIR) $(LIB)

$(TMP_DIR)%.js: $(SRC_DIR)%.coffee
	$(COFFEE) -p -c $< > $@

$(DOC_DIR): $(SRC_DIR)
	codo -o $@ $<

$(TMP_DIR):
	mkdir $(TMP_DIR) -p

$(LIB_PACK): $(LIB) $(LIB_PACK_DIR)
	cp $(LIB) $(DIST_DIR)$(LIB_DIR)

$(LIB_PACK_DIR): $(DIST_DIR)
	mkdir	$(LIB_PACK_DIR) -p

dist: $(LIB_PACK) $(MIN_TARGET) $(INDEX) $(SCORE) $(CSS_DIR)
	cp $(MIN_TARGET) $(DIST_DIR)
	cp -r $(CSS_DIR) $(DIST_DIR)
	cp -r $(IMG_DIR) $(DIST_DIR)
	cp -r $(AUDIO_DIR) $(DIST_DIR)
	cp $(INDEX) $(DIST_DIR)
	cp $(SCORE) $(DIST_DIR)

$(DIST_DIR):
	mkdir $(DIST_DIR) -p

watch: $(TMP_DIR)
	$(COFFEE) -o $(TMP_DIR) -cw $(SRC_DIR)

$(LIB):
	git submodule update --init
	cd lib/zepto; rake

.PHONY:
todo:
	cat doc/TODO

.PHONY: clean
clean:
	rm -f  $(all_TARGETS)
	rm -rf $(TMP_DIR)
	rm -rf $(DOC_DIR)
	rm -rf $(DIST_DIR)*

.PHONY: loc
loc:
	@cat $(SRC) | grep -v '^\s*#' | grep -v "^\s*$$" | wc -l
