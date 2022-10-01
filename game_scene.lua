function get_center(o)
  return o.pos + vector{o.width / 2, o.height / 2}
end

function get_box(o)
  return {
    min_x = o.pos.x,
    min_y = o.pos.y,
    max_x = o.pos.x + o.width,
    max_y = o.pos.y + o.height
  }
end

function collided(a,b)
  local box_a = get_box(a)
  local box_b = get_box(b)
  return (
    box_a.min_x <= box_b.max_x and
    box_a.max_x >= box_b.min_x and
    box_a.min_y <= box_b.max_y and
    box_a.max_y >= box_b.min_y
  )
end


function make_bullet(o)
  local bullet = {
    color = o.color,
    pos = o.pos,
    target = o.target,
    scene = o.scene,
    width = 3,
    height = 3,
    draw = function(self)
      circfill(self.pos.x, self.pos.y, 1, 3)
    end,
    update = function(self)
      if (collided(self, self.target)) then
        self.scene:remove(self)
        return
      end
      local dir = get_center(self.target) - self.pos
      self.pos += dir:normalize() * 2
    end
  }
  return bullet
end

function make_turret(o)
  local turret = {
    color = o.color,
    scene = o.scene,
    width = 8,
    height = 8,
    shoot = function(self, target)
      local bullet = make_bullet({
        color = self.color, 
        pos = get_center(self),
        target = target,
        scene = self.scene
      })
      self.scene:add(bullet)
    end,
    pos = vector{64,64},
    sprite = 1,
    draw = function(self)
      spr(self.sprite,self.pos.x, self.pos.y)
    end
  }
  return turret
end

function make_prince(x,y)
  local prince = {
    pos = vector{x,y},
    dp = vector{1,0},
    width = 2,
    height = 7,
    sprite = 2,
    draw = function(self)
      spr(self.sprite,self.pos.x, self.pos.y)
    end,
    update = function(self)
      if (self.pos.x + self.dp.x > screen_width) then
        self.dp.x = -1
      elseif (self.pos.x + self.dp.x < 0) then
        self.dp.x = 1
      end
      self.pos += self.dp
    end
  }
  return prince
end

game_scene = make_scene({
  add_prince = function(self)
    local prince = make_prince(28,28)
    add(self.princes, prince)
    self:add(prince)
  end,
  init = function(self)
    self.princes = {}
    self:add_prince()
    palt(7, true)
    self.turret = make_turret({ color = 11, scene = self })
    self:add(self.turret)
  end,
  update = function(self)
    if (btnp(4)) then
      self.turret:shoot(self.princes[1])
    end
  end,
  draw = function(self)
    cls(6)
  end
})
