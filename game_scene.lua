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
    color = o.color,
    scene = o.scene,
    width = 8,
    height = 8,
    pos = o.pos,
    sprite = 7,
    flip_x = false,
    flip_y = true,
    find_target = function(self)
      local closest
      local closest_mag
      for prince in all(self.scene.princes) do
        local diff = prince.pos - self.pos
        local mag = #diff
        if (closest == nil or mag < closest_mag) then
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
    draw = function(self)
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
    speed = 0.75,
    health = 10,
    hit = function(self, power)
      self.health -= power
    end,
    complete = function(self)
      self.scene:remove_prince(self)
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

function to_tile_coordinate(pos)
  return vector{math_round(pos.x / 8), math_round(pos.y / 8)}
end

function from_tile_coordinate(pos)
  return vector{math_round(pos.x * 8), math_round(pos.y * 8)}
end


function get_tile_key(tile_pos)
  return tile_pos.x..','..tile_pos.y
end

game_scene = make_scene({
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
        if (tile_n == plain_path_tile) then
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
    local next_pos = from_tile_coordinate(next_tile) + vector{3,0} -- convert to screen coordinates and move to center of tile
    return next_pos - pos
  end,
  add_prince = function(self)
    local prince_start = vector{ self.start_tile_pos.x * 8 + 3, self.start_tile_pos.y * 8 }
    local prince = make_prince({ pos = prince_start, scene = self })
    add(self.princes, prince)
    self:add(prince)
  end,
  remove_prince = function(self, prince)
    self:remove(prince)
    del(self.princes, prince)
  end,
  add_turret = function(self, pos)
    local turret = make_turret({ color = 11, scene = self, pos = pos })
    add(self.turrets, turret)
    self:add(turret)
  end,
  init = function(self)
    self.start_tile_pos = find_map_tile(start_tile,0,0,16,16)
    mset(self.start_tile_pos.x, self.start_tile_pos.y, plain_path_tile)

    self.end_tile_pos = find_map_tile(end_tile,0,0,16,16)
    mset(self.end_tile_pos.x, self.end_tile_pos.y, plain_path_tile)

    self:init_path()

    self.turrets = {}
    self:add_turret(vector{32,64})
    self:add_turret(vector{64,64})
    self:add_turret(vector{96,64})

    self.princes = {}
    self:add_prince(self)

    music(0)
  end,
  update = function(self)
    if (btnp(4)) then
      for turret in all(self.turrets) do
        turret:shoot()
      end
    end
    if (btnp(5)) then
      self:add_prince()
    end
  end,
  draw = function(self)
    palt(0, false) -- remove black as default transparent color
    palt(3, true) -- use green as transparent color
    cls(3)
    map(0, 0, 0, 0, 16, 16)


    -- debug path finding
    -- for i = 1, #self.path do
    --   local tile = self.path[i]
    --   local offset = i % 2 == 0 and 2 or -2
    --   print(i, tile.x * 8, tile.y * 8 + offset, 8)
    -- end
  end
})
