end_scene = make_scene({
  init = function(self)
    self.start_game_text_blink = 0
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

    palt(0, false)

    spr(194, 48, 16, 4, 4)

    center_print("wave: "..self.wave, 52, 7)
    center_print("gold: "..self.gold, 60, 7)

    -- instructions
    if self.start_game_text_blink > 30 then
      center_print("press z try again", 100, 7)
    end
  end
})
