NAUBINO_TARGET = Naubino.full.js
NAUBINO_UGLIFIED_TARGET = Naubino.min.js


NAUBINO_SOURCE = coffee/Ball.coffee \
				 coffee/Keybindings.coffee \
				 coffee/Naub.coffee \
				 coffee/Rules.coffee \
				 coffee/StateMachine.coffee \
				 coffee/Game.coffee \
				 coffee/Layer.coffee \
				 coffee/Naubino.coffee \
				 coffee/Settings.coffee \
				 coffee/Vector.coffee \
				 coffee/Graph.coffee \
				 coffee/Menu.coffee \
				 coffee/PhysicsModel.coffee \
				 coffee/Shape.coffee

NAUBINO_TMP = js/Ball.js \
			  js/Keybindings.js \
			  js/Naub.js \
			  js/Rules.js \
			  js/StateMachine.js \
			  js/Game.js \
			  js/Layer.js \
			  js/Naubino.js \
			  js/Settings.js \
			  js/Vector.js \
			  js/Graph.js \
			  js/Menu.js \
			  js/PhysicsModel.js \
			  js/Shape.js


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
	cat $(NAUBINO_SOURCE) | grep -v '^\s*#' | grep -v "^\s*$$" | wc -l

