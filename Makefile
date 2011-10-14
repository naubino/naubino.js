COFFEE = $(wildcard coffee/*.coffee)
BUILD_PATH = js/
JS = $(wildcard js/*.js)

compile: $(COFFEE) $(JS)
	coffee -o $(BUILD_PATH) -c $(COFFEE)

install: compile
	cat js/Naubino.js js/Settings.js js/StateMachine.js js/Rules.js js/Keybindings.js js/Naub.js js/Shape.js js/Ball.js js/PhysicsModel.js js/Layer.js js/Menu.js js/Game.js js/Graph.js > Naubino.full.js
	uglifyjs Naubino.full.js > Naubino.min.js

loc:
	cat $(COFFEE) | grep -v '^\\( *#\|\s*$\)' | wc -l | tr -s ' '

clean:
	rm -f $(JS)
	rm -f *.js
