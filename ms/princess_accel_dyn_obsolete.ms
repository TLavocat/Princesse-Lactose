PrincessOld = class
  // globals
  LEFT = 0
  RIGHT= 1
  
  // taille de la princess
  X_SIZE = 7.68
  Y_SIZE = 16
  
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
  
  // Définitions statiques
  ONE_METER = 16 //nombre de pixels par mètre
  // accélérations
  WALK_ACCEL = 6 // exrimé en m/s/s
  FLIGHT_WALK_ACCEL = 3
  RUN_ACCEL = 9  // exprimé en m/s/s
  FLIGHT_RUN_ACCEL = 6
  AIR_CONTROL_DIVIDER = 2.4 // diviseur pour limiter le contrôle de trajectoire en l'air
  GRAVITY = 1.5 // exprimé en m/s/s
  JUMP_ACCEL =  5

  //frictions
  GROUND_FRICTION = 0.3 // coefficient de friction du sol
  GROUND_X_DIV = 10
  AIR_FRICTION = 0.3 //coefficient de friction dans l'air
  WALL_FRICTION = 0.3
  
  // Quand la princesse est en friction sur le mur
  // de combien est-elle propulsée du côté opposé
  // lorsqu'elle saute à ce moment là
  WALL_KICK = 4
  JUMP_KICK = 8 
  
  // Nombre d'inréments composant un saut
  JUMPING_COUNTER = 7
  // Nombre d'incrément à rajouter lorsque la touche de saut est maintenue
  JUMPING_COUNTER_REFILL = 2
  // Tous les combien d'incréments rajouter un refill sur le compteur
  JUMPING_KEY_COUNTER_THRESHOLD = 3
  
  
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

  touch_wall = function()
    // renvoie vrai si le block sous les pieds de la princesse est une plateforme
    return get_touching("plateformes", this.x-X_SIZE/2-1, this.y)[0] > -1 or
           get_touching("plateformes", this.x+X_SIZE/2+1, this.y)[0] > -1 
  end
  
  head_on_ceiling = function()
    // renvoie vrai si le block au dessus de la tête de la princesse est une plateforme
    return get_touching("plateformes", this.x, this.y+Y_SIZE/2)[0] > -1
  end
  
  walk = function(timedelta)
    /*
    Met le personnage en mouvemment à gauche ou à droite
    timedelta, nombre de milisecondes depuis le dernier appel
    */
    accel = 0
    
    if this.states.contains(WALKING_L) or this.states.contains(WALKING_R) then
      accel = WALK_ACCEL
      if this.states.contains(RUNNING) then
        accel = RUN_ACCEL
      end
      // si le personnage n'est pas au sol, diviser l'accélération latérale
      if not feet_on_ground() then
        accel = FLIGHT_WALK_ACCEL
        if this.states.contains(RUNNING) then
          accel = FLIGHT_RUN_ACCEL
        end
      end
    end
    
    
    // Inverser le vecteur de déplacement si l'on va à gauche
    if this.states.contains(WALKING_L) then
      accel = accel * -1
    end
    
    td_in_s = timedelta /1000
    
    this.x_accel = this.x_accel + accel*td_in_s
  end
  
  gravity = function(timedelta)
    /*
    Applique la gravité au personnage
    timedelta, nombre de milisecondes depuis le dernier appel
    */
    if not this.feet_on_ground() then
      td_in_s = timedelta /1000
      this.y_accel = this.y_accel - GRAVITY*td_in_s
    end
  end
  
  jump = function(timedelta)
    if this.states.contains(JUMPING) then
      // initialiser les variables du saut
      if this.jumping_counter == 0 then
        this.jump_started_wall_kick = 0
        this.jumping_counter = JUMPING_COUNTER
      end
      
      // si l'utilisateur appuie longtemps sur la touche espace, alors sauter un peu plus loni 
      if this.jump_key_counter > 0 and   this.jump_key_counter % JUMPING_KEY_COUNTER_THRESHOLD == 0 then
        this.jumping_counter += JUMPING_COUNTER_REFILL
        
        // besoin d'étendre le kick de départ si le saut a été initié contre un mur
        // la valeur à rajouter est plus petite que le kick de départ
        if this.jump_started_wall_kick then
          if this.states.contains(WALKING_L) then
            this.x_speed = WALL_KICK/2
          end
          if this.states.contains(WALKING_R) then
            this.x_speed = -WALL_KICK/2
          end
        end
      end

      // Donner un petit kick pour le wall jump
      if this.states.contains(PRESSING_WALL) then
        this.jump_started_wall_kick = 1
        if this.states.contains(WALKING_L) then
          this.x_speed = WALL_KICK
        end
        if this.states.contains(WALKING_R) then
          this.x_speed = -WALL_KICK
        end
      end
      
      // calculer l'accélération
      //td_in_s = timedelta /1000
      //this.y_accel = this.y_accel + JUMP_ACCEL * td_in_s
      this.y_speed = JUMP_KICK * (this.jumping_counter/JUMPING_COUNTER)
      
      // traiter la fin du saut
      this.jumping_counter -=1
      if this.jumping_counter == 0 then
        this.states.removeElement(JUMPING)
        return
      end
    end
  end
  
  
  move = function()
    /*
    Cette fonction applique les accélérations calculées à ce tour sur la princesse et les applique
    */
    // calculer la friction qui s'oppose au déplacement
    // c'est grâce à la friction que le personnage atteindra sa vélocité maximum
    // et freinera losqu'il n'aura plus d'accélération
    // La quantité de friction s'applique au sol et en l'air et elle augmente avec le carré de la vitesse
    // il en resulte un vecteur opposé au déplacement qui vient contrer celui ci.
    
    x_friction = AIR_FRICTION
    if this.feet_on_ground() then
      x_friction += GROUND_FRICTION 
    end
    
    x_friction = pow(this.x_speed * x_friction, 2)
    if this.x_speed < 0 then
      x_friction = x_friction * -1
    end
    
    this.x_speed = this.x_speed + (this.x_accel * ONE_METER) - x_friction
    
    
    y_friction = AIR_FRICTION
    
    if(
        this.y_speed < 0 and 
        touch_wall() and
        (this.states.contains(WALKING_L) or this.states.contains(WALKING_R))
      )then
      if not this.states.contains(PRESSING_WALL) then
        this.states.push(PRESSING_WALL)
      end
      y_friction += WALL_FRICTION
    else
      this.states.removeElement(PRESSING_WALL)
    end
    
    y_friction = pow(this.y_speed * y_friction, 2)

    if this.y_speed < 0 then
      y_friction = y_friction * -1
    end
    

    befiore_speed =  this.y_speed

    this.y_speed = this.y_speed + (this.y_accel * ONE_METER) - y_friction

    
    
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
    
    // éviter de glisser trop longtemps quand la force de friction est trop faible pour arrêter le personnage
    if abs(this.x_speed) < WALK_ACCEL/GROUND_X_DIV then
      this.x_speed = 0
    end

    
    // déplace la princesse uniquement de la distance totale si elle à la place de le faire
    futur_x = this.x + this.x_speed
    touching =  get_touching("plateformes", futur_x + x_add, this.y + -Y_SIZE/2)
    if touching[0] > -1 then
       // Si la princesse va toucher son collisioneur, alors la placer au bord de l'élément
      if this.x_speed > 0 then
        colisioner_x = touching[0]+1
        colisioner_left_border = mapx_to_x(colisioner_x * this.map.block_width - this.map.block_width)
        futur_x = floor(colisioner_left_border - X_SIZE/2)
      elsif this.x_speed < 0 then
        colisioner_x = touching[0]
        colisioner_left_border = mapx_to_x(colisioner_x * this.map.block_width + this.map.block_width)
        futur_x = ceil(colisioner_left_border + X_SIZE/2)
      end
      this.x_speed = 0 //arrêt brutal
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
      this.y_speed = 0 //arrêt brutal
    end
    
    dispy = abs(futur_y - this.y)
    this.yoffset -= dispy*signy

    // remise à zéro de l'accélération
    this.x_accel = 0
    this.y_accel = 0
    


  end
  
  update_me = function(timedelta)
    walk(timedelta)
    jump(timedelta)
    gravity(timedelta)
    
    move()
  end
  
  draw_me = function()
    /*
    Dessine la Princesse à l'écran
    */
    
    
    if this.last_direction == LEFT then
      screen.setDrawScale(-1,1)
    end
    if this.states.contains(JUMPING) or this.states.contains(FALLING) then
      screen.drawSprite(
        "princess.1",
        this.x,
        this.y,
        X_SIZE,
        Y_SIZE)
    elsif states.contains(WALKING_L) then
      screen.drawSprite(
        "princess",
        this.x,
        this.y,
        X_SIZE,
        Y_SIZE)
    elsif states.contains(WALKING_R) then
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
    
    if this.last_direction == LEFT then
      screen.setDrawScale(1,1)
    end
  end
  
  go_right = function()
    this.last_direction = RIGHT
    if not this.states.contains(WALKING_R) then
      this.states.push(WALKING_R)
    end
      
  end
  
  stop_going_right = function()
    this.states.removeElement(WALKING_R)
  end
  
  go_left = function()
    this.last_direction = LEFT
    if not this.states.contains(WALKING_L) then
      this.states.push(WALKING_L)
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
      if (feet_on_ground() or this.states.contains(PRESSING_WALL)) then
        this.states.push(JUMPING)
      end
      // lorsqu'un saut est démarré, mettre à zéro le compteur de frames
      this.jump_key_counter = 0
    else
      // dans tous les cas incrémenter le compteur de frames
      this.jump_key_counter += 1
    end
  end
  
  stop_jump = function()
    this.jump_key_counter = 0
  end
end