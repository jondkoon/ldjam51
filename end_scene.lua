end_scene = make_scene({
  set = function(self, stats)
    self.gold = stats.gold
    self.wave = stats.wave
  end,
  init = function(self)
    sfx(1)
    self.start_game_text_blink = 0
    self.scene_timer = 0
  end,
  update = function(self)
    self.scene_timer += 1
    self.start_game_text_blink += 1
    if self.start_game_text_blink > 60 then self.start_game_text_blink = 1 end
    if self.scene_timer / 60 > 2 and (btnp(4) or btnp(5)) then
      change_scene(game_scene)
    end
  end,
  draw = function(self)
    cls(1)

    palt(0, false)

    spr(194, 48, 16, 4, 4)

    local wave = self.wave or 0
    local gold = self.gold or 0

    center_print("wave: "..wave, 52, 7)
    center_print("gold: "..gold, 60, 7)

    -- instructions
    if self.start_game_text_blink > 30 then
      center_print("press z try again", 100, 7)
    end
  end
})
