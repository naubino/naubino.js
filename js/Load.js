(function() {

  console.time("loading");

  define(["Naubino"], function(Naubino) {
    console.log(Naubino);
    return window.onload = function() {
      window.Naubino = new Naubino();
      return window.Naubino.setup();
    };
  });

}).call(this);
