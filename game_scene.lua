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
      circfill(self.pos.x, self.pos.y, 1, 7)
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
    pos = vector{64,64},
    sprite = 7,
    find_target = function(self)
      local closest
      local closest_mag
      for prince in all(self.scene.princes) do
        local diff = (prince.pos - self.pos)
        local mag = diff.mag
        if (not closest or mag < closest_mag) then
          closest = prince
          closest_mag = mag
        end
      end
      return closest
    end,
    shoot = function(self)
      local target = self:find_target()
      local bullet = make_bullet({
        color = self.color, 
        pos = get_center(self),
        target = target,
        scene = self.scene
      })
      self.scene:add(bullet)
    end,
    draw = function(self)
      local target = self:find_target()
      local diff = target.pos - self.pos
      local angle = diff:normalize()
      local rounded = vector{ math_round(angle.x), math_round(angle.y) }

      local sprite = 8
      if (rounded.x == 0) then
        sprite = 7
      elseif (rounded.y == 0) then
        sprite = 9
      end

      local flip_x = rounded.x == -1
      local flip_y = rounded.y == 1

      spr(sprite,self.pos.x, self.pos.y, 1, 1, flip_x, flip_y)
    end
  }
  return turret
end

function make_prince(x,y)
  local prince = {
    pos = vector{x,y},
    dp = vector{0,0},
    width = 2,
    height = 7,
    sprite = 19,
    draw = function(self)
      spr(self.sprite,self.pos.x, self.pos.y)
    end,
    update = function(self)
      if (btn(0)) then
        self.dp.x = -1
      elseif (btn(1)) then
        self.dp.x = 1
      else
        self.dp.x = 0
      end

      if (btn(2)) then
        self.dp.y = -1
      elseif (btn(3)) then
        self.dp.y = 1
      else
        self.dp.y = 0
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
      self.turret:shoot()
    end
  end,
  draw = function(self)
    palt(0, false) -- remove black as default transparent color
    palt(3, true) -- use green as transparent color
    cls(3)
    map(0, 0, 0, 0, 16, 16)
  end
})
