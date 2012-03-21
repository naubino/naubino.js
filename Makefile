NAUBINO_TARGET = Naubino.full.js
NAUBINO_UGLIFIED_TARGET = Naubino.min.js


NAUBINO_SOURCE = coffee/Ball.coffee \
								 coffee/Keybindings.coffee \
								 coffee/Naub.coffee \
								 coffee/Rules.coffee \
								 coffee/Tutorial.coffee \
								 coffee/Game.coffee \
								 coffee/Layer.coffee \
								 coffee/Overlay.coffee \
								 coffee/Background.coffee \
								 coffee/Naubino.coffee \
								 coffee/Settings.coffee \
								 coffee/Vector.coffee \
								 coffee/Graph.coffee \
								 coffee/Menu.coffee \
								 coffee/PhysicsModel.coffee \
								 coffee/Shape.coffee

# the order is crucial
NAUBINO_TMP = \
							js/Naubino.js \
							js/Settings.js \
							js/Rules.js \
							js/Tutorial.js \
							js/PhysicsModel.js \
							js/Keybindings.js \
							js/Vector.js \
							js/Naub.js \
							js/Shape.js \
							js/Ball.js \
							js/Layer.js \
							js/Overlay.js \
							js/Background.js \
							js/Menu.js \
							js/Game.js \
							js/Graph.js \


all: $(NAUBINO_TARGET)


ugly: $(NAUBINO_UGLIFIED_TARGET)


$(NAUBINO_TARGET) : $(NAUBINO_TMP)
	cat $+ > $@


$(NAUBINO_UGLIFIED_TARGET): $(NAUBINO_TARGET)
	uglifyjs $(NAUBINO_TARGET) > $(NAUBINO_UGLIFIED_TARGET)


js/%.js: coffee/%.coffee
	coffee -p -c $< > $@


.PHONY: clean
clean:
	rm -f $(NAUBINO_TARGET) $(NAUBINO_UGLIFIED_TARGET) js/*


.PHONY: loc
loc:
	@cat $(NAUBINO_SOURCE) | grep -v '^\s*#' | grep -v "^\s*$$" | wc -l

