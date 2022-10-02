function find_map_tile(tile_n, cell_x, cell_y, cell_w, cell_h)
  for x = cell_x, cell_w do
    for y = cell_y, cell_h do
      if (mget(x,y) == tile_n) then
        return vector{ x, y }
      end
    end
  end
  return nil
end

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

function math_round(val)
  local decimal = abs(val - flr(val))
  if (decimal <= 0.5) then
    return flr(val)
  else
    return ceil(val)
  end
end


function center_print(message, y, color)
  local width = #message * 4
  local x = (screen_width - width) / 2
  print(message, x, y, color)
end

function merge_tables(a, b)
  for k, v in pairs(b) do
    a[k] = v
  end
  return a
end

function random_one(set)
	return set[1 + flr(rnd(count(set)))]
end

-- helper function to add delay in coroutines
function delay(frames)
  for i = 1, frames do
    yield()
  end
end
