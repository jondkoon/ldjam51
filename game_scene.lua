function make_turret()
  local turret = {
    pos = vector{64,64},
    sprite = 1,
    draw = function(self)
      spr(self.sprite,self.pos.x-4, self.pos.y-4)
    end
  }
  return turret
end

function make_prince(x,y)
  local prince = {
    pos = vector{x,y},
    dp = vector{1,0},
    sprite = 2,
    draw = function(self)
      spr(self.sprite,self.pos.x-4, self.pos.y-4)
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
    add(princes, prince)
    self:add(prince)
  end,
  init = function(self)
    self.princes = {}
    self:add_prince()
    palt(7, true)
    local turret = make_turret()
    self:add(turret)
  end,
  update = function(self)
  end,
  draw = function(self)
    cls(6)
  end
})
