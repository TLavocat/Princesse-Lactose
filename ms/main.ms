init = function()
  played_map = "map2"
  mapw = 
  maph = 
  
  princess = new Princess(0, 10, played_map)
  prev_time = system.time()
  prevx = 0
  prevy = 0
end



update = function()
  if not maps[played_map].ready then
    return
  end
  now = system.time()
  timedelta = now - prev_time
  

  princess.update_me()
  
  //----------------------------------------------------------------------------
  //
  // Gestion des inputs

  wants_jump = keyboard.SPACE or gamepad.A
  stop_jump = keyboard.release.SPACE or gamepad.release.A
  wants_left = keyboard.LEFT or gamepad.LEFT_STICK_LEFT
  wants_climb = keyboard.UP or gamepad.LEFT_STICK_UP
  wants_right = keyboard.RIGHT or gamepad.LEFT_STICK_RIGHT
  wants_crouch =  keyboard.DOWN or gamepad.LEFT_STICK_DOWN
  wants_run = keyboard.SHIFT_LEFT or gamepad.X
  wants_dash = keyboard.ALT_LEFT or gamepad.RT
  
  // Sauter n'est possible que si l'on est pas déjà en train de sauter et que 
  // la princesse a les pieds au sol
  /*
  if (wants_jump and not princess_states.contains(JUMPING) and
    (on_ground or on_climbable)) then
    princess_states.push(JUMPING)
  end
  */
  if wants_right then
    princess.go_right()
  else
    princess.stop_going_right()
  end
  
  if wants_left then
    princess.go_left()
  else
    princess.stop_going_left()
  end
  
  if wants_jump then
    princess.do_jump()
  end 
  if stop_jump then
    princess.stop_jump()  
  end
  
  /*
  if wants_run and not princess_states.contains(RUNNING) then
    princess_states.push(RUNNING)
  end
  if not wants_run then
    princess_states.removeElement(RUNNING)
  end
  
  can_climbe = (on_climbable or heads_on_climbable)
  if wants_climb and not princess_states.contains(CLIMBING) and can_climbe then
    princess_states.push(CLIMBING)
  end
  if not wants_climb or not can_climbe then
    princess_states.removeElement(CLIMBING)
  end
  
  if wants_crouch and not princess_states.contains(CLIMBING_DOWN) and can_climbe then
    princess_states.push(CLIMBING_DOWN)
  end
  if not wants_crouch or not can_climbe then
    princess_states.removeElement(CLIMBING_DOWN)
  end
  */
  
  prev_time = now

end

draw = function()
  screen.fillRect(0,0,screen.width,screen.height,"rgb(171,255,255)")
  screen.drawMap(played_map,
                princess.xoffset,
                princess.yoffset,
                princess.map.width*princess.map.block_width,
                princess.map.height*princess.map.block_height)
  
  princess.draw_me()
end