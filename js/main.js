var include = function(file, path) {
	if (!path) path = 'build/'
    var args = 'type="text/javascript" src="'+path+file+'.js"';
    document.write('<script '+args+'></script>');
};
var toinc = ["glu", "Game", "Naub", "NaubShape", "PhysicsModel","NaubShape"];
for (var i in toinc) include(toinc[i]);
include("b2Vec2", "js/");

window.naubino = {};
