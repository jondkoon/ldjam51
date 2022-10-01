local current_scene

function change_scene(scene)
  current_scene = scene
  current_scene:init()
end

function make_scene(options)
  local o = {
    init = options.init,
    update = options.update,
    draw = options.draw,
    after_draw = options.after_draw,
  }

  local scene = {
    init = function(self)
      self.objects = {}
      if (self.music) then
        music(self.music)
      else
        music(-1)
      end
      o.init(self)
    end,
    add = function(self, object)
      if (object.init) then
        object:init()
      end
      return add(self.objects, object)
    end,
    remove = function(self, object)
      del(self.objects, object)
    end,
    update = function(self)
      if (o.update) then
        o.update(self)
      end
      for k, object in pairs(self.objects) do
        if (object.update) then
          object:update()
        end
      end
    end,
    draw = function(self)
      if (o.draw) then
        o.draw(self)
      end
      for k, object in pairs(self.objects) do
        if (object.draw) then
          object:draw()
        end
      end
      if (o.after_draw) then
        o.after_draw(self)
      end
    end
  }
  return merge_tables(options, scene)
end
