naubino.js is a little game build for the browser. It is intended to be played on multi touch platforms.



# First Setup:

  * `git clone https://github.com/hoodie/naubino.js` ( "thanks for pointing out the obvious!!" - your welcome)
  * `git submodule update --init`
  * use dev.html during development

# Make
 * thanks to Hydroo we have a make file
 * `make` works like a charm
 * `make ugly` makes Naubino.min.js for index.html (deployment)
 * `make loc` lines of code

# Documentation
  * check out doc/roadmap for plans and known issues
    (not as up to date as I would like it to be )

# Constant Building
  * Build once Using: `coffee -o ./js/ -c coffee/*.coffee`
  * While coding use: `coffee -o ./js/ -cw coffee/*.coffee`
  * From Coffeescript 1.1.3 on you need node.js >= 0.6.3 for 'watch' to work
    if watch still does not work ( which it does not for me ) use Coffee-Script 1.1.4-pre

`
git clone https://github.com/jashkenas/coffee-script/
cd coffee-script
sudo bin/cake install
`

# Node.js:
  * In case you dont have a current node.js in your package manager
`
git clone https://github.com/joyent/node ;
cd node ;
./configure ;
make ;
sudo make install ;
`

[![endorse](http://api.coderwall.com/hoodie/endorsecount.png)](http://coderwall.com/hoodie) 
[![endorse](http://api.coderwall.com/payload/endorsecount.png)](http://coderwall.com/payload) 
