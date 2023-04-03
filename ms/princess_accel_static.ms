// TODO régler les collisions!!!!

Princess = class
  // globals
  LEFT = 0
  RIGHT= 1
  
  // taille de la princess
  X_SIZE = 12
  Y_SIZE = 23
  
  // états
  IDLING = 0
  WALKING_R = 1
  WALKING_L = 2
  JUMPING = 3
  CROUCHING = 4
  FARTING = 5
  DASHING = 6
  FALLING = 7
  RUNNING = 8
  CLIMBING_UP = 9
  CLIMBING_DOWN = 10
  PRESSING_WALL = 11
  JUMP_KICKING = 12
  
  X_SPEED_TABLE    = [0, 0.2, 0.4, 0.6, 1, 1.6, 2.4, 3]
  X_SPEED_DECEL    = [0, 0.2, 0.6, 1.6, 3]
  X_SPEED_AIR_DECEL =[0, 0.2, 0.6, 0.8, 0.9, 0.9, 1,  
                      1.1, 1.1, 1.1, 1.2, 1.2, 1.2,
                      1.2, 1.2, 1.3, 1.4, 1.5, 1.6, 
                      1.8, 1.9, 3]
  FALL_SPEED_TABLE = [0, 0.4, 0.8, 1.2, 1.6, 2, 2.4, 2.8, 3, 4, ]
  JUMP_SPEED_TABLE = [0, 0.4, 0.8, 1.2, 1.6, 2, 2.4, 2.8, 3, 3, 4, 5]
  KICK_SPEED_TABLE = [0, 0.2, 0.4, 0.6, 1, 1.6, 2.4, 3]
   
  
  // Nombre d'inréments composant un saut
  JUMPING_COUNTER = 20
  // Nombre d'incrément à rajouter lorsque la touche de saut est maintenue
  JUMPING_COUNTER_REFILL = 2
  // Tous les combien d'incréments rajouter un refill sur le compteur
  JUMPING_KEY_COUNTER_THRESHOLD = 3
  
  COYOTE_LENGTH = 20
  
  
  constructor = function(x, y, map_name)
    this.x = x
    this.y = y -10 // décaler le srpite car sinon 0,0 est en son centre
    this.map = maps[map_name]
    this.states = []
    
    this.x_speed = 0
    this.y_speed = 0
    
    this.x_accel = 0
    this.y_accel = 0
    this.last_direction = RIGHT
    
    this.xoffset=0
    this.yoffset=0
    
    // jumping states
    this.jumping_counter = 0 // compte le nombre d'étape à faire pour sauter
    // compte le nombre de frames dans le saut, utilisé pour savoir
    // si le bouton a été enfoncé longtemps ou non
    this.jump_key_counter = 0
    // mis à 1 si le saut à démarré avec un kick pour pouvoir
    // rajouter un peu de kick en cours de saut si la touche de saut
    // est maintenue.
    this.jump_started_wall_kick = 0
    this.jump
    
    this.coyote = []
    this.coyote_pressing = []
  end

  
  x_in_map = function(x)
    /*
    transforme une coordonée x avec une référence au centre de la carte
    en une coordonnée où le point de référence est en bas à gauche de la carte
    */
    map_half_width = (this.map.width/2)*this.map.block_width
    return x+map_half_width-this.xoffset
  end
  
  x_to_block = function(x_in_map)
    // Transforme une coordonée x en numéro de block correspondant
    return floor(x_in_map / this.map.block_width)
  end
  
  mapx_to_x = function(mapx)
    return mapx-((this.map.width/2)* this.map.block_width)+this.xoffset
  end

  y_in_map = function(y)
    /*
    transforme une coordonée y avec une référence au centre de la carte
    en une coordonnée où le point de référence est en bas à gauche de la carte
    */
    map_half_height = (this.map.height/2)* this.map.block_height
    return y+map_half_height-this.yoffset
  end
  
  mapy_to_y = function(mapy)
    return mapy-((this.map.height/2)* this.map.block_height)+this.yoffset
  end
  
  y_to_block = function(y_in_map)
    // Transforme une coordonée y en numéro de block correspondant
    return floor(y_in_map / this.map.block_height)
  end
  
  get_touching = function(name, x, y)
    /*
    Renvoie les coordonées en unité block du block pointé aux coordonnées du personnage.
    */
    block_x = x_to_block(x_in_map(x))
    block_y =  y_to_block(y_in_map(y))
    
    block = map.get(block_x,block_y)
    if block != 0 then
      if block.startsWith(name) then
        return [block_x, block_y]
      else
        return [-1, -1]
      end
    end
    return [-1, -1]
  end
  
  feet_on_ground = function()
    // renvoie vrai si le block sous les pieds de la princesse est une plateforme
    return get_touching("plateformes", this.x, this.y-Y_SIZE/2-1)[0] > -1
  end
  
  futur_feet_on_ground = function(x)
    // renvoie vrai si le block sous les pieds de la princesse est une plateforme
    return get_touching("plateformes", x, this.y-Y_SIZE/2-1)[0] > -1
  end
  
  coyote_touch = function()
    return coyote[0]
  end
  coyote_pressing_touch = function()
    return coyote_pressing[0]
  end

  touch_wall = function()
    // renvoie vrai si le block sous les pieds de la princesse est une plateforme
    return get_touching("plateformes", this.x-X_SIZE/2-1, this.y)[0] > -1 or
           get_touching("plateformes", this.x+X_SIZE/2+1, this.y)[0] > -1 
  end
  
  head_on_ceiling = function()
    // renvoie vrai si le block au dessus de la tête de la princesse est une plateforme
    return get_touching("plateformes", this.x, this.y+Y_SIZE/2)[0] > -1
  end
  
  get_speed_table = function(table, index)
    speed_table_len = table.length
    if index < speed_table_len then
      return table[index]
    else
      return table[speed_table_len-1]
    end
  end
  
  walk = function(timedelta)
    if this.states.contains(JUMP_KICKING) then
      return
      print("can't walk")
    end
    
    if this.states.contains(WALKING_L) or this.states.contains(WALKING_R) then
      table = X_SPEED_TABLE
      this.walking_step = min(table.length, this.walking_step+1)
    else
      if feet_on_ground() then
        table = X_SPEED_DECEL
        this.start_air_decel = 0
        if this.walking_step >= X_SPEED_DECEL.length -1 then
            this.walking_step = X_SPEED_DECEL.length -1
        end
      else
        table = X_SPEED_AIR_DECEL
        if this.start_air_decel == 0 then
          if this.walking_step >= X_SPEED_DECEL.length -1 then
            this.walking_step = X_SPEED_AIR_DECEL.length -1
          end
          this.start_air_decel = 1
        end
      end
      if this.walking_step >= 0 then
        if this.walking_step > table.length-1 then
          this.walking_step = table.length-1
        end
        this.walking_step-=1
      end
    end
    if this.walking_step >= 0 then
      this.x_speed = get_speed_table(table, this.walking_step)
      if this.last_direction == LEFT then
        this.x_speed *= -1
      end
    end
    if abs(x_speed) > 0 then
      print(x_speed)
    end
  end
  
  gravity = function(timedelta)
    if(
        not feet_on_ground() and 
        touch_wall() and
        not this.states.contains(JUMPING) and
        (this.states.contains(WALKING_L) or this.states.contains(WALKING_R))
    )then
      if not this.states.contains(PRESSING_WALL) then
        this.states.push(PRESSING_WALL)
        print("pressing wall")
      end
    else
      if this.states.contains(PRESSING_WALL) then
        this.states.removeElement(PRESSING_WALL)
        print("stop pressing wall")
      end
    end
    
    max_speed = FALL_SPEED_TABLE.length
    if this.states.contains(PRESSING_WALL) then
      max_speed = 4
    end
    
    if this.feet_on_ground() or this.states.contains(JUMPING) then
      this.falling_step = -1
      this.states.removeElement(FALLING)
    else
      if not this.states.contains(JUMPING) then
        this.falling_step = min(max_speed, this.falling_step+=1)
        if not this.states.contains(FALLING) then
          this.states.push(FALLING)
        end
      end
    end

    if this.falling_step >= 0 then
      this.y_speed = - get_speed_table(FALL_SPEED_TABLE, this.falling_step)
    end
  end
  
  jump = function(timedelta)
    if this.states.contains(JUMPING) then
      // initialiser les variables du saut
      if this.jumping_counter == 0 then
        this.jump_started_wall_kick = 0
        this.jumping_counter = JUMP_SPEED_TABLE.length
        this.kick_counter = KICK_SPEED_TABLE.length -1
        
        // Donner un petit kick pour le wall jump
        if this.states.contains(PRESSING_WALL) then
          if not this.states.contains(JUMP_KICKING) then
            print("jump kicking")
            this.states.push(JUMP_KICKING)
          end
        end
      end
      // si l'utilisateur appuie longtemps sur la touche espace, alors sauter un peu plus loni 
      if this.jump_key_counter > 0 and this.jump_key_counter % JUMPING_KEY_COUNTER_THRESHOLD == 0 then
        this.jumping_counter += JUMPING_COUNTER_REFILL
        
        if this.states.contains(JUMP_KICKING) then
          this.kick_counter += JUMPING_COUNTER_REFILL
        end
      end
      
      if this.states.contains(JUMP_KICKING) then
        this.x_speed = get_speed_table(KICK_SPEED_TABLE, this.kick_counter)
        if this.last_direction == RIGHT then
          this.x_speed *= -1
        end
        this.kick_counter -=1
        print("kick "+this.x_speed)
        
        if this.kick_counter <= 0 then
          this.states.removeElement(JUMP_KICKING)
          this.walking_step=0
        end
      end
      
      this.y_speed = get_speed_table(JUMP_SPEED_TABLE, this.jumping_counter)

      this.jumping_counter -= 1
      if this.jumping_counter == 0 then
        this.states.removeElement(JUMPING)
        print("jump cycle done")
      end
    end
  end
  
  next_collision_x = function(futur_x, y, right, left)
    ret_futur_x = futur_x
    for i=(y - Y_SIZE/2) to (y + Y_SIZE/2) by 8
      point = get_touching("plateformes", futur_x, i)
      hypothesis = -1
      
      if point[0] > 0 then
        if right then
          colisioner_x = point[0]+1
          colisioner_left_border = mapx_to_x(colisioner_x * this.map.block_width - this.map.block_width)
          hypothesis = floor(colisioner_left_border - X_SIZE/2)
        elsif left then
          colisioner_x = point[0]
          colisioner_left_border = mapx_to_x(colisioner_x * this.map.block_width + this.map.block_width)
          hypothesis = ceil(colisioner_left_border + X_SIZE/2)
        end
      end
      if hypothesis != -1 and abs(hypothesis) < abs(ret_futur_x) then
        ret_futur_x = hypothesis
      end
    end
    return ret_futur_x
  end
  
  next_collision_y = function(x, futur_y, top, bottom)
    ret_futur_y = futur_y
    for i=(x - X_SIZE/2) to (x + X_SIZE/2) by 4
      point = get_touching("plateformes", i, futur_y)
      hypothesis = -1
      
      if point[0] > 0 then
        if top then
          colisioner_y = point[1]
          colisioner_bottom_border = mapy_to_y(colisioner_y * this.map.block_height)
          futur_y = floor(colisioner_bottom_border - Y_SIZE/2)
        elsif bottom then
          colisioner_y = point[1]
          colisioner_top_border = mapy_to_y(colisioner_y * this.map.block_height + this.map.block_height)
          hypothesis = ceil(colisioner_top_border + Y_SIZE/2)
        end
      end
      if hypothesis != -1 and abs(hypothesis) < abs(ret_futur_y) then
        ret_futur_y = hypothesis
      end
    end
    return ret_futur_y
  end


  move = function()
    signx = 1
    signy = 1
    
    // gérer la collision sur x
    if this.x_speed > 0 then
      x_add = X_SIZE/2
    else
      x_add = -X_SIZE/2
      signx = -1
    end
    if this.y_speed > 0 then
      y_add = Y_SIZE/2
    else
      y_add = -Y_SIZE/2
      signy = -1
    end
    
    // déplace la princesse uniquement de la distance totale si elle à la place de le faire
    futur_x = this.x + this.x_speed
    if abs(this.x_speed) !=0 then
      futur_x_with_collision = next_collision_x(futur_x+x_add, this.y, this.x_speed > 0, this.x_speed < 0)
      if futur_x_with_collision != futur_x+x_add then
        futur_x = futur_x_with_collision
        this.x_speed = 0
      end
    end
 
    dispx = abs(futur_x - this.x)
    this.xoffset -= dispx*signx
    
 
    futur_y = this.y + this.y_speed 
    touching = get_touching("plateformes", this.x + x_add, futur_y + y_add)         
    if touching[1] > -1 then
       // Si la princesse va toucher son collisioneur, alors la placer au bord de l'élément
      if this.y_speed > 0 then
        colisioner_y = touching[1]
        colisioner_bottom_border = mapy_to_y(colisioner_y * this.map.block_height)
        futur_y = floor(colisioner_bottom_border - Y_SIZE/2)
      elsif this.y_speed < 0 then
        colisioner_y = touching[1]
        colisioner_top_border = mapy_to_y(colisioner_y * this.map.block_height + this.map.block_height)
        futur_y = ceil(colisioner_top_border + Y_SIZE/2)
      end
      cancel_jump()
      this.y_speed = 0 //arrêt brutal
    end
    
    dispy = abs(futur_y - this.y)
    this.yoffset -= dispy*signy

    // remise à zéro de l'accélération
    this.x_accel = 0
    this.y_accel = 0
    


  end
  
  update_me = function(timedelta)
    coyote.push(feet_on_ground())
    coyote_pressing.push(this.states.contains(PRESSING_WALL))
    
    walk(timedelta)
    jump(timedelta)
    gravity(timedelta)
    move()
    
    if coyote.length > COYOTE_LENGTH then
      coyote.removeAt(0)
    end
    if coyote_pressing.length > COYOTE_LENGTH then
      coyote_pressing.removeAt(0)
    end
  end
  
  draw_me = function()

    
    reverse = (not this.states.contains(PRESSING_WALL) and this.last_direction == LEFT) or (this.states.contains(PRESSING_WALL) and this.last_direction == RIGHT)
    if reverse then
      screen.setDrawScale(-1,1)
    end
    if this.states.contains(JUMPING) and not this.states.contains(PRESSING_WALL) then
      if this.jumping_counter <= JUMP_SPEED_TABLE.length-1 and  this.jumping_counter >= JUMP_SPEED_TABLE.length-3  then
        screen.drawSprite(
          "princess_jumping_impulsion",
          this.x,
          this.y,
          X_SIZE,
          Y_SIZE)
      else
        screen.drawSprite(
        "princess_jumping",
        this.x,
        this.y,
        X_SIZE,
        Y_SIZE)
      end
    elsif this.states.contains(FALLING) and not this.states.contains(PRESSING_WALL) then
      if states.contains(WALKING_L) or states.contains(WALKING_R) then
        screen.drawSprite(
          "princess_falling_direction",
          this.x,
          this.y,
          X_SIZE,
          Y_SIZE)
      else
        screen.drawSprite(
          "princess_falling",
          this.x,
          this.y,
          X_SIZE,
          Y_SIZE)
      end
    elsif this.states.contains(PRESSING_WALL) then
      screen.drawSprite(
        "princess_wall_stick",
        this.x,
        this.y,
        X_SIZE,
        Y_SIZE)
    elsif states.contains(WALKING_L) and not this.states.contains(FALLING) then
      screen.drawSprite(
        "princess",
        this.x,
        this.y,
        X_SIZE,
        Y_SIZE)
    elsif states.contains(WALKING_R) and not this.states.contains(FALLING)then
      screen.drawSprite(
        "princess",
        this.x,
        this.y,
        X_SIZE,
        Y_SIZE)
    else
      screen.drawSprite(
        "princess.0",
        this.x,
        this.y,
        X_SIZE,
        Y_SIZE)
    end
    
    if reverse then
      screen.setDrawScale(1,1)
    end
  end
  
  go_right = function()
    this.last_direction = RIGHT
    if not this.states.contains(WALKING_R) then
      print("right")
      this.states.push(WALKING_R)
      this.walking_step = this.kick_counter
      //this.kick_counter = -1
    end
      
  end
  
  stop_going_right = function()
    this.states.removeElement(WALKING_R)
  end
  
  go_left = function()
    this.last_direction = LEFT
    if not this.states.contains(WALKING_L) then
      print("left")
      this.states.push(WALKING_L)
      this.walking_step = this.kick_counter
      //this.kick_counter = -1
    end
  end
  
  stop_going_left = function()
    this.states.removeElement(WALKING_L)
  end
  
  do_jump = function()
    // Un nouveau saut est déclenché uniquement si le cycle d'un saut
    // précédent n'est pas fini.
    // Pour terminer, la princesse doit avoir touché le sol ou être accrochée au mur
    // mais l'utilisateur doit également avoir relâché la touche saut
    if not this.states.contains(JUMPING) and this.jump_key_counter == 0 then
      if (feet_on_ground() or this.states.contains(PRESSING_WALL) or coyote_touch() or coyote_pressing_touch()) then
        this.states.push(JUMPING)
        print("jump")
      end
    else
        this.jump_key_counter += 1
    end
  end
  
  stop_jump = function()
    print("stop jump")
    this.jump_key_counter = 0
  end

  cancel_jump = function()
    print("cancel jump")
    this.jumping_counter = 0
    this.states.removeElement(JUMPING)
    this.kick_counter = 0
    this.states.removeElement(JUMP_KICKING)
  end
end