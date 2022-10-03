function make_bullet(o)
  local bullet = {
    color = o.color,
    pos = o.pos,
    target = o.target,
    scene = o.scene,
    width = 3,
    height = 3,
    speed = 1.5,
    power = 1,
    init = function()
      sfx(4)
    end,
    draw = function(self)
      circfill(self.pos.x, self.pos.y, 1, 7)
    end,
    update = function(self)
      if (collided(self, self.target)) then
        self.target:hit(self.power)
        self.scene:remove(self)
        return
      end
      local dir = get_center(self.target) - self.pos
      self.pos += dir:normalize() * self.speed
    end
  }
  return bullet
end

function make_turret(o)
  local turret = {
    type = 'turret',
    color = o.color,
    scene = o.scene,
    width = 8,
    height = 8,
    pos = o.pos,
    sprite = 7,
    flip_x = false,
    flip_y = true,
    fire_interval = 30,
    range = 30,
    debug_show_range = false,
    find_target = function(self)
      local closest
      local closest_mag
      for prince in all(self.scene.princes) do
        local diff = prince.pos - self.pos
        local mag = #diff
        if ((closest == nil or mag < closest_mag) and mag < self.range) then
          closest = prince
          closest_mag = mag
        end
      end
      return closest
    end,
    shoot = function(self)
      local target = self:find_target()
      if (target) then
        local bullet = make_bullet({
          color = self.color, 
          pos = get_center(self),
          target = target,
          scene = self.scene
        })
        self.scene:add(bullet)
      end
    end,
    update = function(self)
      self.target = self:find_target()
      if (not self.target) then
        return
      end
      if (frame % self.fire_interval == 0) then
        self:shoot()
      end
      local diff = self.target.pos - self.pos
      local angle = diff:normalize()
      local rounded = vector{ math_round(angle.x), math_round(angle.y) }

      local sprite = 8 -- angled
      if (rounded.x == 0) then
        sprite = 7 -- facing up
      elseif (rounded.y == 0) then
        sprite = 9 -- facing right
      end

      self.sprite = sprite

      self.flip_x = rounded.x == -1
      self.flip_y = rounded.y == 1      
    end,
    draw_range = function(self)
      local center = get_center(self)
      circ(center.x, center.y, self.range, 5)
    end,
    draw = function(self)
      if (self.debug_show_range) then
        self:draw_range()
      end
      spr(self.sprite, self.pos.x, self.pos.y, 1, 1, self.flip_x, self.flip_y)
    end
  }
  return turret
end

function make_prince(o)
  local prince = {
    pos = o.pos,
    scene = o.scene,
    dp = vector{0,0},
    width = 2,
    height = 7,
    speed = 0.6,
    health = 5,
    hit = function(self, power)
      self.health -= power
    end,
    complete = function(self)
      self.scene:lost()
    end,
    died = function(self)
      self.scene:remove_prince(self)
    end,
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
      if (self.health < 0) then
        self:died()
      end

      local path_direction = self.scene:get_path_direction(self.pos)

      if (path_direction == nil) then
        return
      end

      if (path_direction == "done") then
        self:complete()
        return
      end

      self.dp = path_direction:normalize()
      self.pos += self.dp * self.speed
    end
  }
  return prince
end

function make_princess(o)
  local princess = {
    pos = o.pos,
    scene = o.scene,
    dp = vector{0,0},
    width = 4,
    height = 7,
    speed = 0.75,
    draw = function(self)
      local flip_x = self.dp.x < 0
      local sprite = 22
      if (math_round(self.dp.y) < 0) then
        sprite = 21
      elseif (math_round(self.dp.x) != 0) then
        sprite = 20
      end

      -- draw cursor
      if (self.cursor_pos) then
        spr(11, self.cursor_pos.x, self.cursor_pos.y)
      end

      if (self.tile_info and self.tile_info.type == 'turret') then
        self.tile_info:draw_range()
      end

      -- draw character
      spr(sprite,self.pos.x - 3, self.pos.y - 2,1,1, flip_x)
    end,
    place_turret = function(self)
      self.scene:add_turret(self.cursor_pos)
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

      local next_pos = self.pos + (self.dp * self.speed)

      if (next_pos.x > 1 and next_pos.x < screen_width - 2 and next_pos.y > 8 and next_pos.y < screen_height - self.height) then
        self.pos = next_pos
      end 

      local tile_pos = from_tile_coordinate(to_tile_coordinate(self.pos - vector{3,2}))

      self.tile_info = self.scene:get_tile_info(tile_pos)

      if self.tile_info then
        self.cursor_pos = tile_pos
        if (btnp(4)) then
          self:place_turret()
        end
      else
        self.tile_info = nil
        self.cursor_pos = nil
      end
    end
  }
  return princess
end

function to_tile_coordinate(pos)
  return vector{math_round(pos.x / 8), math_round(pos.y / 8)}
end

function from_tile_coordinate(pos)
  return vector{math_round(pos.x * 8), math_round(pos.y * 8)}
end


function get_tile_key(tile_pos)
  return tile_pos.x..','..tile_pos.y
end

local is_turret_eligible = {
  [2] = true,
  [3] = true,
  [6] = true
}

local wave_prince_count = {
  1,
  2,
  4,
  6,
  10
}

game_scene = make_scene({
  init_turret_grid = function(self)
    local turret_grid = {}
    local max_x = screen_width / 8
    local max_y = screen_height / 8
    for x = 0, max_x do
      for y = 0, max_y do
        local tile_n = mget(x, y)
        if (is_turret_eligible[tile_n]) then
          if (turret_grid[x] == nil) then
            turret_grid[x] = {}
          end
          turret_grid[x][y] = false
        end
      end
    end
    self.turret_grid = turret_grid
  end,
  init_path = function(self)
    local visited = {}
    self.path = {}
    self.next_tile_table = {}
    function visit(tile_pos, prev_tile_pos)
      local key = get_tile_key(tile_pos)
      if (visited[key]) then
        return
      end
      visited[key] = key
      add(self.path, tile_pos)
      if (prev_tile_pos) then
        self.next_tile_table[get_tile_key(prev_tile_pos)] = tile_pos
      end
      for direction in all(vector_directions_4) do
        local neighbor = tile_pos + direction
        local tile_n = vector_mget(neighbor)
        if (tile_n == plain_path_tile or tile_n == end_tile) then
          visit(neighbor, tile_pos)
        end
      end
    end
    visit(self.start_tile_pos)
  end,
  get_path_direction = function(self, pos)
    local current_tile = to_tile_coordinate(pos)
    if (current_tile == self.end_tile_pos) then
      return "done"
    end
    local next_tile = self.next_tile_table[get_tile_key(current_tile)]
    if (not next_tile) then
      return nil
    end
    local next_pos = from_tile_coordinate(next_tile) + vector{3,0} -- convert to screen coordinates and move to center of tile
    return next_pos - pos
  end,
  lost = function(self)
    end_scene.gold = self.gold_earned
    end_scene.wave = self.wave
    change_scene(end_scene)
  end,
  add_prince = function(self)
    local prince_start = vector{ self.start_tile_pos.x * 8 + 3, self.start_tile_pos.y * 8 }
    local prince = make_prince({ pos = prince_start, scene = self })
    add(self.princes, prince)
    self:add(prince)
  end,
  remove_prince = function(self, prince)
    self:add_gold(10)
    self:remove(prince)
    del(self.princes, prince)
  end,
  get_tile_info = function(self, pos)
    local tile_pos = to_tile_coordinate(pos)
    local grid_x = self.turret_grid[tile_pos.x]
    local tile_info = grid_x and grid_x[tile_pos.y]
    if (tile_info == false) then
      return { type = 'available' }
    end
    return tile_info
  end,
  add_turret = function(self, pos)
    local turret_cost = 50
    local tile_pos = to_tile_coordinate(pos)
    local grid_x = self.turret_grid[tile_pos.x]
    local is_eligible = grid_x and grid_x[tile_pos.y] == false
    if (is_eligible and self.gold >= turret_cost) then
      local turret = make_turret({ color = 11, scene = self, pos = pos })
      grid_x[tile_pos.y] = turret
      add(self.turrets, turret)
      self:add(turret)
      self.gold -= turret_cost
    end
  end,
  add_gold = function(self, amount) 
    self.gold += amount
    self.gold_earned += amount
  end,
  init = function(self)
    self.prince_wave_count = 0
    self.next_prince_wave_count = wave_prince_count[1]
    self.wave = 0
    self.wave_countdown = 10

    self.gold = 100
    self.gold_earned = self.gold

    self.start_tile_pos = find_map_tile(start_tile,0,0,16,16)
    self.end_tile_pos = find_map_tile(end_tile,0,0,16,16)

    self:init_path()
    self:init_turret_grid()

    self.turrets = {}

    self.princes = {}

    self.princess = make_princess({ scene = self, pos = vector{ 30, 24 } })
    self:add(self.princess)

    self.iris = make_iris(self.princess.pos.x + 1, self.princess.pos.y + 3)

    music(0)

    menuitem(1, "restart", function() change_scene(game_scene) end)
  end,
  next_wave = function(self)
    self.wave_countdown = 10
    self.wave += 1
    self.prince_wave_count = wave_prince_count[self.wave] or 20
    self.next_prince_wave_count = wave_prince_count[self.wave + 1] or 20
  end,
  update = function(self)
    if (frame % 30 == 0 and self.prince_wave_count > 0) then
      self.prince_wave_count -= 1
      self:add_prince()
    end

    if (frame % 60 == 0) then
      self.wave_countdown -= 1
    end

    if (self.wave_countdown == -1) then
      self:next_wave()
    end

    self.iris:update()
    if (btnp(4)) then
      for turret in all(self.turrets) do
        turret:shoot()
      end
    end
    if (btnp(5)) then
      self:add_prince()
    end
  end,
  draw_over_tile = function(self, tile_pos)
    local map_pos = from_tile_coordinate(tile_pos)
    spr(plain_path_tile, map_pos.x, map_pos.y)
  end,
  draw = function(self)
    palt(0, false) -- remove black as default transparent color
    palt(3, true) -- use green as transparent color
    cls(3)
    map(0, 0, 0, 0, 16, 16)

    self:draw_over_tile(self.start_tile_pos)
    self:draw_over_tile(self.end_tile_pos)


    -- debug path finding
    -- for i = 1, #self.path do
    --   local tile = self.path[i]
    --   local offset = i % 2 == 0 and 2 or -2
    --   print(i, tile.x * 8, tile.y * 8 + offset, 8)
    -- end
  end,
  after_draw = function(self)
    self.iris:draw()
    
    -- black HUD
    rectfill(0,0,screen_width, 6, 1)

    -- coin indicator
    spr(25, 1, 1)
    print(self.gold, 6, 1, 7)

    -- wave indicator
    print("wave "..self.wave, 50, 1, 7)

    -- wave_countdown
    local next_count_x_offset = self.next_prince_wave_count >= 10 and 5 or 0
    print(self.next_prince_wave_count, screen_width - 19 - next_count_x_offset, 1)
    spr(24, screen_width - 15,0)
    local countdown_text = self.wave_countdown == 10 and "10" or "0"..self.wave_countdown
    local countdown_color = self.wave_countdown <= 3 and 8 or 7
    print(countdown_text, screen_width - 8, 1, countdown_color)
  end
})
