var include = function(file, path) {
	if (!path) path = 'build/'
    var args = 'type="text/javascript" src="'+path+file+'"';
    document.write('<script '+args+'></script>');
};
var toinc = ["foo.js", "Game.js"];
for (var i in toinc) include(toinc[i]);
include("b2Vec2.js", "js/");
