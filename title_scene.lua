function make_title_prince(o)
  local prince = {
    pos = o.pos,
    scene = o.scene,
    dp = vector{1,0},
    width = 2,
    height = 7,
    speed = o.speed,
    health = 10,
    draw = function(self)
      local flip_x = self.dp.x < 0
      local sprite = 16
      if (math_round(self.dp.y) < 0) then
        sprite = 17
      elseif (math_round(self.dp.y) > 0) then
        sprite = 18
      end
      spr(sprite,self.pos.x - 3, self.pos.y - 1,1,1, flip_x)
    end,
    update = function(self)
      local new_x = self.pos.x + (self.dp.x * self.speed)
      local new_y = self.pos.y + (self.dp.y * self.speed)
      if (new_x > screen_width - 8) then
        self.dp.x = -1
      elseif (new_x < 8) then
        self.dp.x = 1
      end

      self.pos += self.dp * self.speed
    end
  }
  return prince
end

title_scene = make_scene({
  add_prince = function(self)
    local start_x = (screen_width + rnd(screen_width))
    local start_y = 108 + math_round(rnd(5))
    local pos = vector{start_x, start_y}
    local speed = rnd(0.25) + 0.5
    local prince = make_title_prince({ pos = pos, scene = self, speed = speed })
    add(self.princes, prince)
    self:add(prince)
  end,
  remove_prince = function(self, prince)
    self:remove(prince)
    del(self.princes, prince)
  end,
  init = function(self)
    self.start_game_text_blink = 1
    self.princes = {}

    for i = 1, 10 do
      self:add_prince()
    end
  end,
  update = function(self)
    self.start_game_text_blink += 1
    if self.start_game_text_blink > 60 then self.start_game_text_blink = 1 end
    if btnp(4) or btnp(5) then
      change_scene(game_scene)
    end
  end,
  draw = function(self)
    cls(1)

    -- game title
    palt()
    palt(2, true)
    spr(48, 7, 7, 15, 3)

    -- byline
    center_print("bY jON, jULIE, AND eLLIOT", 32, 7)

    -- instructions
    if self.start_game_text_blink > 30 then
      center_print("press z or x to start", 50, 7)
    end

    -- castle
    palt()
    palt(10, true)
    spr(80, 21, 57, 11, 6)


    -- grass
    rectfill(0,104, screen_width, screen_height, 3)
    rectfill(0,111, screen_width, screen_height - 5, 6)



    -- scene sprites
    palt()
    palt(3, true) -- use green as transparent color
  end
})
