var include = function(file, path) {
	if (!path) path = 'build/'
    var args = 'type="text/javascript" src="'+path+file+'.js"';
    document.write('<script '+args+'></script>');
};
include("b2Vec2", "js/");
