NAUBINO_TARGET = Naubino.full.js
NAUBINO_UGLIFIED_TARGET = Naubino.min.js

# the order is no longer crucial
NAUBINO_TMP = \
							js/Background.js \
							js/Game.js \
							js/Graph.js \
							js/Keybindings.js \
							js/Layer.js \
							js/Load.js \
							js/Menu.js \
							js/Naubino.js \
							js/Naub.js \
							js/Overlay.js \
							js/PhysicsModel.js \
							js/Settings.js \
							js/Shapes.js \
							js/StandardGame.js \
							js/TestCase.js \
							js/Tutorial.js \
							js/Util.js


NAUBINO_SOURCE = $(NAUBINO_TMP:js/%.js=coffee/%.coffee)

all: $(NAUBINO_TARGET)


ugly: $(NAUBINO_UGLIFIED_TARGET)


$(NAUBINO_TARGET) : $(NAUBINO_TMP)
	r.js -o name=Load out=./$@ baseUrl=js optimize=none
	cp $@ $(NAUBINO_UGLIFIED_TARGET)


$(NAUBINO_UGLIFIED_TARGET): $(NAUBINO_TMP)
	r.js -o name=Load out=./$@ baseUrl=js


js/%.js: coffee/%.coffee
	coffee -p -c $< > $@


.PHONY: clean
clean:
	rm -f $(NAUBINO_TARGET) $(NAUBINO_UGLIFIED_TARGET)

.PHONY: clean-all
clean-all:
	rm -f $(NAUBINO_TARGET) $(NAUBINO_UGLIFIED_TARGET) js/*

.PHONY: loc
loc:
	@cat $(NAUBINO_SOURCE) | grep -v '^\s*#' | grep -v "^\s*$$" | wc -l

doc: docs/*
	codo coffee/* -o docs/
