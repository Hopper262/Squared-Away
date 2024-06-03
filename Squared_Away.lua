Triggers = {}
function Triggers.draw()

  if TexturePalette.draw() then return end
  if Screen.term_active then return end
  if Player.dead then return end
  if not deja then return end
  
  -- oxygen bar
  do
    local otwo_x = sx + dejaheight
    local otwo_y = sy + dejaheight
    local otwo_w = dejaheight
    local otwo_h = dejaheight * 9
    draw_frame(otwo_x, otwo_y, otwo_w, otwo_h)
    
    local otwo_fill = math.floor(otwo_h * (Player.oxygen / 10800))
    Screen.fill_rect(otwo_x, otwo_y + (otwo_h - otwo_fill), otwo_w, otwo_fill,
                     { 0.2, 0.4, 0.8, 0.6 })
  end
  
  -- health bar
  do
    local life_x = sx + dejaheight * 13
    local life_y = sy + dejaheight
    local life_seg = math.floor((sw - dejaheight * 30) / 3)
    local life_h = dejaheight
    
    local life_amt = Player.life
    local life_w = life_seg
    local color = { 0.8, 0, 0, 0.6 }
    if life_amt > 150 then
      life_w = life_seg * 2
      color = { 0.8, 0.8, 0, 0.6 }
    end
    if life_amt > 300 then
      life_w = life_seg * 3
      color = { 0.8, 0, 0.8, 0.6 }
    end
    draw_frame(life_x, life_y, life_w, life_h)
    
    if life_amt > 0 then
      Screen.fill_rect(life_x, life_y,
                       math.floor(life_seg * (math.min(150, life_amt) / 150)),
                       life_h,
                       color)
    end
    if life_amt > 150 then
      Screen.fill_rect(life_x + life_seg + 1, life_y,
                       math.floor((life_seg - 1) * (math.min(150, life_amt - 150) / 150)),
                       life_h,
                       color)
    end
    if life_amt > 300 then
      Screen.fill_rect(life_x + life_seg*2 + 1, life_y,
                       math.floor((life_seg - 1) * (math.min(150, life_amt - 300) / 150)),
                       life_h,
                       color)
    end
  end
  
  -- inventory
  do
    local inv_h = dejaheight * 9
    local inv_w = dejaheight * 15
    local inv_x = sx + sw - dejaheight - inv_w
    local inv_y = sy + dejaheight
    draw_frame(inv_x, inv_y, inv_w, inv_h)
    clip(inv_x, inv_y, inv_w, inv_h)
    
    -- header
    local sec = Player.inventory_sections.current
    Screen.fill_rect(inv_x, inv_y, inv_w, dejaheight, { 0.6, 0.6, 0.6, 0.2 })
    local extra = nil
    if sec.type == "network statistics" then
      extra = net_header()
    end
    if extra then
      local tw, th = deja:measure_text(extra)
      deja:draw_text(extra, inv_x + inv_w - tw - dejawidth, inv_y, { 0.8, 0.8, 0.8, 1 })
      deja:draw_text(sec.name, inv_x, inv_y, { 0.6, 0.6, 0.6, 1 })
    else
      local tw, th = deja:measure_text(sec.name)
      deja:draw_text(sec.name, inv_x + (inv_w - tw)/2, inv_y, { 0.6, 0.6, 0.6, 1 })
    end
    
    -- content area
    inv_y = inv_y + dejaheight
    inv_h = inv_h - dejaheight
    
    if sec.type == "network statistics" then
      -- player list and rankings
      local all_players = sorted_players()
      local gametype = Game.type
      if gametype == "netscript" then
        gametype = Game.scoring_mode
      end
 
      local mw, mh = deja:measure_text("99:99")
      local mx = inv_x + mw + dejawidth
      local mwh = mw + math.floor(dejawidth/2)

      for i = 1,#all_players do
        local p = all_players[i]

        -- background with player and team colors
        Screen.fill_rect(inv_x, inv_y, mwh, dejaheight,
                         colortable[p.team.mnemonic])
        Screen.fill_rect(inv_x + mwh, inv_y, inv_w - mwh, dejaheight,
                         colortable[p.color.mnemonic])
        
        -- ranking text
        local score = player_ranking_text(gametype, p.ranking)
        local iw, ih = deja:measure_text(score)
        deja:draw_text(score, inv_x + mw - iw, inv_y, { 1, 1, 1, 1})
        
        -- player name
        deja:draw_text(p.name, mx, inv_y, { 1, 1, 1, 1 })
        
        inv_y = inv_y + dejaheight
      end
    else
      -- item list
      local mw, mh = deja:measure_text("999")
      local mx = inv_x + mw + dejawidth
      for i = 1,#ItemTypes do
        local item = Player.items[i - 1]
        local name = ItemTypes[i - 1]
        if (item.count > 0 and item.inventory_section == sec.type) and not (name == "knife") then
          local ct = string.format("%d", item.count)
          local iw, ih = deja:measure_text(ct)
          deja:draw_text(ct, inv_x + mw - iw, inv_y, { 0.8, 0.8, 0.8, 1})
          
          local iname
          if item.count == 1 then
            iname = item.singular
          else
            iname = item.plural
          end 
          deja:draw_text(iname, mx, inv_y, { 0.8, 0.8, 0.8, 1 })
          inv_y = inv_y + dejaheight
        end
      end
    end
    
    unclip()
  end
   
  -- ammo
  if Player.weapons.current then
    local weapon = Player.weapons.current
    local wp = weapon.primary
    local ws = weapon.secondary
    local primary_ammo = nil
    local secondary_ammo = nil
    
    if wp and wp.ammo_type then
      primary_ammo = wp.ammo_type
    end
    
    if ws and ws.ammo_type then
      secondary_ammo = ws.ammo_type
      if secondary_ammo == primary_ammo then
        if Player.items[weapon.type.mnemonic].count < 2 then
          secondary_ammo = nil
        end
      end
    end
    
    if not (weapon.type == "alien weapon") then
      -- primary trigger
      if primary_ammo then
        local ammo_w = dejaheight * 15
        local ammo_h = dejaheight * 2 + 1
        local ammo_x = sx + sw - ammo_w - dejaheight
        local ammo_y = sy + sh - dejaheight - ammo_h
        draw_frame(ammo_x, ammo_y, ammo_w, ammo_h)
  
        local item = Player.items[primary_ammo]
  
        -- loaded rounds
        Screen.fill_rect(ammo_x, ammo_y,
                         math.floor(ammo_w * (wp.rounds / wp.total_rounds)),
                         dejaheight,
                         { 0.6, 0.6, 0.6, 0.6 })
        if string.find(item.singular, "[(]x" .. wp.total_rounds) or string.find(item.singular, "FLECHETTE") then
          deja:draw_text(wp.rounds, ammo_x, ammo_y, { 0.1, 0.1, 0.1, 1 })
        end
        
        -- item reserve
        ammo_y = ammo_y + dejaheight + 1
        ammo_h = dejaheight
        clip(ammo_x, ammo_y, ammo_w, ammo_h)
        
        Screen.fill_rect(ammo_x, ammo_y, ammo_w, ammo_h,
                         { 0.6, 0.6, 0.6, 0.2 })
        
        local mw, mh = deja:measure_text("999")
        local mx = ammo_x + mw + dejawidth
        
        local ct = string.format("%d", item.count)
        local iw, ih = deja:measure_text(ct)
        deja:draw_text(ct, ammo_x + mw - iw, ammo_y, { 0.6, 0.6, 0.6, 1})
  
        local iname
        if item.count == 1 then
          iname = item.singular
        else
          iname = item.plural
        end 
        deja:draw_text(iname, mx, ammo_y, { 0.6, 0.6, 0.6, 1 })
        
        unclip()
      end
  
      -- secondary trigger
      if secondary_ammo then
        local ammo_w = dejaheight * 15
        local ammo_h = dejaheight * 2 + 1
        local ammo_x = sx + dejaheight
        local ammo_y = sy + sh - dejaheight - ammo_h
        draw_frame(ammo_x, ammo_y, ammo_w, ammo_h)
  
        local item = Player.items[secondary_ammo]
  
        -- loaded rounds
        Screen.fill_rect(ammo_x, ammo_y,
                         math.floor(ammo_w * (ws.rounds / ws.total_rounds)),
                         dejaheight,
                         { 0.6, 0.6, 0.6, 0.6 })
        if string.find(item.singular, "[(]x" .. wp.total_rounds) or string.find(item.singular, "FLECHETTE") then
          deja:draw_text(ws.rounds, ammo_x, ammo_y, { 0.1, 0.1, 0.1, 1 })
        end
        
        -- item reserve
        ammo_y = ammo_y + dejaheight + 1
        ammo_h = dejaheight
        clip(ammo_x, ammo_y, ammo_w, ammo_h)
        
        Screen.fill_rect(ammo_x, ammo_y, ammo_w, ammo_h,
                         { 0.6, 0.6, 0.6, 0.2 })
        
        local mw, mh = deja:measure_text("999")
        local mx = ammo_x + mw + dejawidth
        
        local ct = string.format("%d", item.count)
        local iw, ih = deja:measure_text(ct)
        deja:draw_text(ct, ammo_x + mw - iw, ammo_y, { 0.6, 0.6, 0.6, 1})
  
        local iname
        if item.count == 1 then
          iname = item.singular
        else
          iname = item.plural
        end 
        deja:draw_text(iname, mx, ammo_y, { 0.6, 0.6, 0.6, 1 })
        
        unclip()
      end
    end  
  end
  
  -- motion sensor
  if Player.motion_sensor.active then
    local sens_x = sx + dejaheight * 3
    local sens_y = sy + dejaheight
    local sens_w = dejaheight * 9
    local sens_h = sens_w
    local sens_brad = math.floor(dejaheight * .75)
    local sens_rad = sens_w/2 - sens_brad/2 - 1
    local sens_xcen = sens_x + math.floor(sens_w/2)
    local sens_ycen = sens_y + math.floor(sens_h/2)
    
    draw_frame(sens_x, sens_y, sens_w, sens_h)
    
    if Player.compass.nw then
      Screen.fill_rect(sens_x, sens_y,
                       sens_xcen - sens_x,
                       sens_ycen - sens_y,
                       { 0.8, 0.8, 0, 0.2 })
    end
    if Player.compass.ne then
      Screen.fill_rect(sens_xcen, sens_y,
                       sens_w - (sens_xcen - sens_x),
                       sens_ycen - sens_y,
                       { 0.8, 0.8, 0, 0.2 })
    end
    if Player.compass.sw then
      Screen.fill_rect(sens_x, sens_ycen,
                       sens_xcen - sens_x,
                       sens_h - (sens_ycen - sens_y),
                       { 0.8, 0.8, 0, 0.2 })
    end
    if Player.compass.se then
      Screen.fill_rect(sens_xcen, sens_ycen,
                       sens_w - (sens_xcen - sens_x),
                       sens_h - (sens_ycen - sens_y),
                       { 0.8, 0.8, 0, 0.2 })
    end
    
    for i = 1,#Player.motion_sensor.blips do
      local blip = Player.motion_sensor.blips[i - 1]
      local mult = blip.distance * sens_rad / 8
      local rad = math.rad(blip.direction)
      local xoff = sens_xcen + math.cos(rad) * mult
      local yoff = sens_ycen + math.sin(rad) * mult
      
      local alpha = 1.0
      local strength = 0.8
      if blip.intensity > 0 then
        alpha = 1.0 / (blip.intensity + 1)
        strength = 0.4
      end
      local color = { 0, strength, 0, alpha }
      if blip.type == "alien" then
        color = { strength, 0, 0, alpha }
      end
      if blip.type == "hostile player" then
        color = { strength, strength, 0, alpha }
      end
      
      Screen.fill_rect(math.floor(xoff - sens_brad/2),
                       math.floor(yoff - sens_brad/2),
                       sens_brad, sens_brad, color)
      if blip.intensity == 0 then
        Screen.frame_rect(math.floor(xoff - sens_brad/2) - 1,
                         math.floor(yoff - sens_brad/2) - 1,
                         sens_brad + 2, sens_brad + 2,
                         { 0, 0, 0, 0.3 }, 1)
      end
    end
  end

end

function Triggers.resize()

  if TexturePalette.resize() then return end

  Screen.clip_rect.width = Screen.width
  Screen.clip_rect.x = 0
  Screen.clip_rect.height = Screen.height
  Screen.clip_rect.y = 0

  Screen.map_rect.width = Screen.width
  Screen.map_rect.x = 0
  Screen.map_rect.height = Screen.height
  Screen.map_rect.y = 0
  
  local h = math.min(Screen.height, Screen.width / 1.5)
  local w = math.min(Screen.width, h*2)
  Screen.world_rect.width = w
  Screen.world_rect.x = (Screen.width - w)/2
  Screen.world_rect.height = h
  Screen.world_rect.y = (Screen.height - h)/2
  
  h = math.min(Screen.height, Screen.width / 2)
  w = h*2
  Screen.term_rect.width = w
  Screen.term_rect.x = (Screen.width - w)/2
  Screen.term_rect.height = h
  Screen.term_rect.y = (Screen.height - h)/2

  sx = Screen.world_rect.x
  sy = Screen.world_rect.y
  sw = Screen.world_rect.width
  sh = Screen.world_rect.height
    
  deja = Fonts.new{file = "dejavu/DejaVuLGCSansCondensed-Bold.ttf", size = sh / 48, style = 0}
  dejawidth, dejaheight = deja:measure_text("  ")
end

function Triggers.init()
  colortable = { slate  = { 0.0, 0.4, 0.8, 0.6 },
                 red    = { 0.8, 0.0, 0.0, 0.6 },
                 violet = { 0.8, 0.0, 0.4, 0.6 },
                 yellow = { 0.8, 0.8, 0.0, 0.6 },
                 white  = { 0.8, 0.8, 0.8, 0.6 },
                 orange = { 0.8, 0.4, 0.0, 0.6 },
                 blue   = { 0.0, 0.0, 0.8, 0.6 },
                 green  = { 0.0, 0.8, 0.0, 0.6 } }
  
  Triggers.resize()
end

function draw_frame(x, y, w, h)
  Screen.fill_rect(x - 1, y - 1, w + 2, h + 2,
                   { 0, 0, 0, 0.6 })
  Screen.frame_rect(x - 2, y - 2, w + 4, h + 4,
                    { 0.6, 0.6, 0.6, 0.6 }, 1)
end

function clip(x, y, w, h)
  local rect = Screen.clip_rect
  rect.x = x
  rect.y = y
  rect.width = w
  rect.height = h
end

function unclip()
  local rect = Screen.clip_rect
  rect.x = 0
  rect.y = 0
  rect.width = Screen.width
  rect.height = Screen.height
end

function format_time(ticks)
   local secs = math.floor(ticks / 30)
   return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

function net_header()
  if Game.time_remaining then
    return format_time(Game.time_remaining)
  elseif Game.kill_limit then
    local max_kills = 0
    for i = 1,#Game.players do
      max_kills = math.max(max_kills, Game.players[i - 1].kills)
    end
    return string.format("%d", Game.kill_limit - max_kills)
  end
  return nil
end

function player_ranking_text(gametype, ranking)
  if     gametype == "kill monsters" or
         gametype == "capture the flag" or
         gametype == "rugby" or
         gametype == "most points" then
    return string.format("%d", ranking)
  elseif gametype == "least points" then
    return string.format("%d", -ranking)
  elseif gametype == "cooperative play" then
    return string.format("%d%%", ranking)
  elseif gametype == "most time" or
         gametype == "least time" or
         gametype == "king of the hill" or
         gametype == "kill the man with the ball" or
         gametype == "defense" or
         gametype == "tag" then
    return format_time(math.abs(ranking))
  end
  return nil
end

function sorted_players()
  local tbl = {}
  for i = 1,#Game.players do
    table.insert(tbl, Game.players[i - 1])
  end
  local sortfunc = function(a, b)
    if a.ranking ~= b.ranking then return a.ranking > b.ranking end
    return a.index < b.index
  end
  table.sort(tbl, sortfunc)
  return tbl
end

-- BEGIN texture palette utility
--
-- Use: in Triggers.draw: "if TexturePalette.draw() then return end"
--    in Triggers.resize: "if TexturePalette.resize() then return end"

TexturePalette = {}
TexturePalette.active = false

function TexturePalette.check_active()
  local old_active = TexturePalette.active
  local new_active = false
  if Player.texture_palette.size > 0 then new_active = true end
  TexturePalette.active = new_active

  if old_active and not new_active then
    Screen.crosshairs.lua_hud = TexturePalette.saved_crosshairs_lua_hud
    Triggers.resize()
  elseif new_active and not old_active then
    TexturePalette.palette_cache = {}
    TexturePalette.saved_crosshairs_lua_hud = Screen.crosshairs.lua_hud
    Screen.crosshairs.lua_hud = false
    TexturePalette.resize()
  end
  return TexturePalette.active
end

function TexturePalette.get_shape(slot)
  local key = string.format("%d %d", slot.collection, slot.texture_index)
  local shp = TexturePalette.palette_cache[key]
  if not shp then
    shp = Shapes.new{collection = slot.collection, texture_index = slot.texture_index, type = slot.type}
    TexturePalette.palette_cache[key] = shp
  end
  return shp
end

function TexturePalette.draw_shape(slot, x, y, size)
  local shp = TexturePalette.get_shape(slot)
  if not shp then return end
  if shp.width > shp.height then
    shp:rescale(size, shp.unscaled_height * size / shp.unscaled_width)
    shp:draw(x, y + (size - shp.height)/2)
  else
    shp:rescale(shp.unscaled_width * size / shp.unscaled_height, size)
    shp:draw(x + (size - shp.width)/2, y)
  end
end

function TexturePalette.draw(hr)
  if not TexturePalette.check_active() then return false end

  local hr = TexturePalette.hud_rect
  local tcount = Player.texture_palette.size
  local size
  if     tcount <=   5 then size = 128
  elseif tcount <=  16 then size =  80
  elseif tcount <=  36 then size =  53
  elseif tcount <=  64 then size =  40
  elseif tcount <= 100 then size =  32
  elseif tcount <= 144 then size =  26
  else                      size =  20
  end
  size = size * hr.scale

  local rows = math.floor(hr.height/size)
  local cols = math.floor(hr.width/size)
  local x_offset = hr.x + (hr.width - cols * size)/2
  local y_offset = hr.y + (hr.height - rows * size)/2

  for i = 0,tcount - 1 do
    TexturePalette.draw_shape(
      Player.texture_palette.slots[i],
      (i % cols) * size + x_offset + hr.scale/2,
      math.floor(i / cols) * size + y_offset + hr.scale/2,
      size - hr.scale)
  end

  if Player.texture_palette.highlight then
    local i = Player.texture_palette.highlight
    Screen.frame_rect(
      (i % cols) * size + x_offset,
      math.floor(i / cols) * size + y_offset,
      size, size,
      InterfaceColors["inventory text"],
      hr.scale)
  end

  return true
end

function TexturePalette.resize()
  if not TexturePalette.check_active() then return false end

  local ww = Screen.width
  local wh = Screen.height

  -- calculate HUD area
  TexturePalette.hud_rect = {}
  local hudsize = Screen.hud_size_preference
  TexturePalette.hud_rect.width = 640
  if hudsize == SizePreferences["double"] then
    if wh >= 960 and ww >= 1280 then
      TexturePalette.hud_rect.width = 1280
    end
  elseif hudsize == SizePreferences["largest"] then
    TexturePalette.hud_rect.width = math.min(ww, math.max(640, (4 * wh) / 3));
  end

  TexturePalette.hud_rect.height = TexturePalette.hud_rect.width / 4
  TexturePalette.hud_rect.x = math.floor((ww - TexturePalette.hud_rect.width) / 2)
  TexturePalette.hud_rect.y = math.floor(wh - TexturePalette.hud_rect.height)

  TexturePalette.hud_rect.scale = TexturePalette.hud_rect.width / 640

  -- remove HUD height from rest of calculations
  wh = TexturePalette.hud_rect.y

  -- calculate terminal area
  local termsize = Screen.term_size_preference
  Screen.term_rect.width = 640
  if termsize == SizePreferences["double"] then
    if wh >= 640 and ww >= 1280 then
      Screen.term_rect.width = 1280
    end
  elseif termsize == SizePreferences["largest"] then
    Screen.term_rect.width = math.min(ww, math.max(640, 2 * wh))
  end

  Screen.term_rect.height = Screen.term_rect.width / 2
  Screen.term_rect.x = math.floor((ww - Screen.term_rect.width) / 2)
  Screen.term_rect.y = math.floor((wh - Screen.term_rect.height) / 2)

  -- calculate world-view area
  Screen.world_rect.width = math.min(ww, math.max(640, 2 * wh))
  Screen.world_rect.height = Screen.world_rect.width / 2
  Screen.world_rect.x = math.floor((ww - Screen.world_rect.width) / 2)
  Screen.world_rect.y = math.floor((wh - Screen.world_rect.height) / 2)

  -- calculate map area
  if Screen.map_overlay_active then
    -- overlay just matches world-view
    Screen.map_rect.width = Screen.world_rect.width
    Screen.map_rect.height = Screen.world_rect.height
    Screen.map_rect.x = Screen.world_rect.x
    Screen.map_rect.y = Screen.world_rect.y
  else
    Screen.map_rect.width = ww
    Screen.map_rect.height = wh
    Screen.map_rect.x = 0
    Screen.map_rect.y = 0
  end

  Screen.clip_rect.width = Screen.width
  Screen.clip_rect.height = Screen.height
  Screen.clip_rect.x = 0
  Screen.clip_rect.y = 0

  return true
end

-- END texture palette utility
