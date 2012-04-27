(function() {

  define(function() {
    var PhysicsModel;
    return PhysicsModel = (function() {

      function PhysicsModel(naub) {
        this.naub = naub;
        this.pos = new b2Vec2(0, 0);
        this.vel = new b2Vec2(0, 0);
        this.force = new b2Vec2(0, 0);
        this.attracted_to = new b2Vec2(0, 0);
        this.mass = this.default_mass = Naubino.settings.naub.mass;
        this.friction = this.default_friction = Naubino.settings.physics.friction;
        this.spring_force = Naubino.settings.physics.spring_force;
        this.margin = Naubino.settings.physics.margin;
        this.join_length = Naubino.settings.physics.join_length;
      }

      PhysicsModel.prototype.step = function(dt) {
        var v;
        v = this.force.Copy();
        v.Multiply(dt);
        this.pos.Add(v);
        this.acceleration = new b2Vec2(0, 0);
        return this.apply_friction();
      };

      PhysicsModel.prototype.gravitate = function(dt, to) {
        var diff;
        if (to == null) to = this.attracted_to;
        if (!(this.naub.focused || !this.naub.layer.gravity)) {
          diff = to.Copy();
          diff.Subtract(this.pos);
          diff.Multiply(dt);
          diff.Multiply(this.mass);
          return this.accelerate(diff);
        }
      };

      PhysicsModel.prototype.accelerate = function(diff) {
        return this.force.Add(diff);
      };

      PhysicsModel.prototype.apply_friction = function() {
        return this.force.Multiply(1 / this.friction);
      };

      PhysicsModel.prototype.follow = function(v) {
        var pl;
        if (v == null) v = this.attracted_to;
        pl = v.Copy();
        pl.Subtract(this.pos);
        pl = pl.Length();
        v.Subtract(this.pos);
        v.Normalize();
        v.Multiply(30 * pl);
        return this.force.Add(v);
      };

      PhysicsModel.prototype.collide = function(other) {
        var diff, keep_distance, l, oforce, opos, ovel, v, _ref;
        if (this.naub.number !== other.number) {
          _ref = other.physics, opos = _ref.pos, ovel = _ref.vel, oforce = _ref.force;
          keep_distance = (this.naub.size + other.size) * this.margin;
          diff = opos.Copy();
          diff.Subtract(this.pos);
          l = diff.Length();
          if (this.naub.number < other.number && l < keep_distance) {
            v = diff.Copy();
            v.Normalize();
            v.Multiply(keep_distance - l);
            v.Multiply(0.6);
            this.pos.Subtract(v);
            opos.Add(v);
            this.force.Subtract(v);
            return oforce.Add(v);
          }
        }
      };

      PhysicsModel.prototype.join_springs = function(other) {
        var diff, keep_distance, l, oforce, opos, ovel, v, _ref;
        _ref = other.physics, opos = _ref.pos, ovel = _ref.vel, oforce = _ref.force;
        keep_distance = (this.naub.size + other.size) * this.join_length;
        diff = opos.Copy();
        diff.Subtract(this.pos);
        l = diff.Length();
        v = diff.Copy();
        v.Normalize();
        v.Multiply(-1 / 1000 * this.spring_force * l * l * l % 1000);
        this.force.Subtract(v);
        oforce.Add(v);
        if (l < keep_distance) {
          v = diff.Copy();
          v.Normalize();
          v.Multiply(keep_distance - l);
          v.Multiply(0.6);
          this.vel.Subtract(v);
          ovel.Add(v);
          this.force.Subtract(v);
          return oforce.Add(v);
        }
      };

      return PhysicsModel;

    })();
  });

}).call(this);
