pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
	--main
	
function _init()
	cls(0)
	cartdata("energy_blast_v1")
	
	version="v1"
	
	--sprites
	flamespr=21
	flameani=0
	emptyheartspr=13
	
	--blinking text anim
	whiteblink={5,6,7,6,5}
	greyblink={5,13,6,7,6,13}
	yellowblink={9,10,7,10,7,9}
	
	wave=0
	warp=0
 warp_time=0
	
	star_colors={
 	split("5,13,6,7"), --gray
  split("1,13,12,6,7"), --cool
  split("2,8,9,10,15,7"), --hot
  split("8,11,12,10,7"), --galaga
	}
	star_colors[0]=star_colors[1]
	start_screen()
	
	highscore=dget(0)
	shake=0
	flash=0
	btnlockout=0
	t=0 --number of frames

	energyicon=make_spr()
	energyicon.spr=48
	energyicon.x=100
	energyicon.y=1

	debug=""
		
	--highscore
 hs={}
 hs1={} --first char of name
 hs2={}
 hs3={}
 hsb={true,false,false,false,false} --blink of a score
 load_hs()
	hschars=split("a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z")	
	hs_x=128
 hs_dx=128 
end

-- (gameplay hard 30fps)
function _update()
	t+=1

	if mode=="game" then
		update_game()
	elseif mode=="start" then
		update_start()
	elseif mode=="wavetext" then
		update_wavetext()
	elseif mode=="over" then
		update_over()
	elseif mode=="win" then
		update_win()
	end
end

-- (soft 30 fps)
function _draw()
	shake_screen()
	
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="wavetext" then
		draw_wavetext()
	elseif mode=="over" then
		draw_over()
	elseif mode=="win" then
		draw_win()
	end

	camera()
	print(debug,2,9,7)
end

function start_screen()
	mode="start"
	create_stars()
	music(7)
end

function start_game()
 initials={1,1,1}
 initials_sel=1 --initials selection
 initials_conf=false
 loghs=false --log high score

	score=0
	energy=0
	energy_max=10
	muzzle=0
	bulltimer=0
	lastwave=9
	wave=0
	next_wave()
	
	ship=make_spr()
	ship.x=60
	ship.y=90
	ship.spr=2
	ship.spx=0
	ship.spy=0
	ship.lives={max=4,curr=4}
	ship.invul=0 --invulnerability
	
	bullets={}
	enembullets={}
	enemies={}
	particles={}	
	smallparticles={}
	shockwaves={}
	pickups={}
	floats={} --floating elements
	
	attackfreq=60
	firefreq=20
	nextfire=0
end

function create_stars()
	stars={}	
	for i=1,100 do
		add(stars,rand_star())
	end
end

function rand_star(top)
 local vperc=rnd()
 local cols=star_colors[ceil(wave/3)]

 --phase in the new star colors
 if warp_time>0
	 and rnd(100)<warp_time then
  	cols=star_colors[ceil((wave-1)/3)]
 end

 local star={
  x=rnd(128),
  y=rnd(128),
  spd=vperc*2+.5,
  c=cols[flr(vperc*
      #star_colors)+1],
 }
 
 if top then 
 	star.y=-1 
 end
 
 return star
end
-->8
--update

function update_game()
	handle_ship_controls()
	move_bullets()
	move_pickups()
	move_enemy_bullets()	
	move_enemies()
	collision_enemies_x_bullets()
	collision_enem_bullets_x_bullets()
	collision_ship_x_enemies()
	collision_ship_x_pickups()
	collision_ship_x_enemy_bullets()
	pick_timer()
	move_small_particles()

	if ship.lives.curr<=0 then
		mode="over"
		btnlockout=t+30
		music(6)
		return
	end
	
	--check if waves is over
	if mode=="game" and #enemies==0 then
		enembullets={}
		next_wave()
	end
end

function move_bullets() 
	for bull in all (bullets) do
		move(bull)
		
		del_outside_screen(bull,bullets)
	end
end

function move_pickups() 
	for pickup in all (pickups) do
		move(pickup)
		
		del_outside_screen(pickup,pickups)
	end
end

function move_enemy_bullets() 
	for enembull in all (enembullets) do
		move(enembull)
		animate(enembull)		
		del_outside_screen(enembull,enembullets)
	end
end

function move_enemies() 
	for enemy in all(enemies) do
	 execute_behavior(enemy)
		
		animate(enemy)
		
		--leaving screen
		if enemy.behavior!="flyin" then
			del_outside_screen(enemy,enemies)
		end
	end
end

function collision_enemies_x_bullets() 
	for enemy in all(enemies) do
		for bull in all(bullets) do
			if collision(enemy,bull) then
				del(bullets,bull)
				shockwave(bull.x,bull.y,false)
				spark(bull.x+4,bull.y+4,false)
				if enemy.behavior!="flyin" then
					enemy.hp-=bull.dmg
				end
				sfx(3)

				if enemy.isboss then
					enemy.flash=5
				else
					enemy.flash=2
				end
		
				if enemy.hp<=0 then
					kill_enemy(enemy)
				end
			end
		end
	end
end

function collision_enem_bullets_x_bullets()
	for bull in all(bullets) do
		--check if energy bullet
		if bull.spr==17 then
			for enembull in all(enembullets) do
				if collision(enembull,bull) then
					del(enembullets,enembull)
					shockwave(enembull.x,enembull.y,false)
					score+=5
				end
			end
		end
	end
end

function collision_ship_x_enemies()
	if ship.invul==0 then
		for enemy in all(enemies) do
			if collision(enemy,ship) then			
				ship_hit()
			end
		end
	else 
		ship.invul-=1
	end
end

function collision_ship_x_pickups()
	for pickup in all(pickups) do
		if collision(pickup,ship) then			
			decide_pickup(pickup)
			del(pickups,pickup)
		end
	end
end

function collision_ship_x_enemy_bullets()
	if ship.invul==0 then
		for enembull in all(enembullets) do
			if collision(enembull,ship) then			
				ship_hit()
			end
		end
	end
end

function ship_hit()
	explode(ship.x+4,ship.y+4,true)
	ship.lives.curr-=1
	shake=8
	flash=3
	sfx(2)
	ship.invul=60
end

function update_start()
	animate_starfield(0.4)	
	
	if hs_x~=hs_dx then
   hs_x+=ease_in(hs_x,hs_dx,5)
	end
	
	if btn(4)==false and btn(5)==false then
		btnreleased=true
	end

	if btnreleased then
		if btnp(4) then
			start_game()
			btnreleased=false
		elseif btnp(0) then
			if hs_dx~=0 then
				hs_dx=0
				sfx(58)
			end
		elseif btn(1) then			
			if hs_dx~=128 then
				hs_dx=128
				sfx(58)
			end
		end
	end
end

function update_over()
	if btn(4)==false and btn(5)==false then
		btnreleased=true
	end

	if btnreleased then
		if btnp(4) or btnp(5) then
				start_screen()
				btnreleased=false
				reset_hsb()
		end
	end
end

function handle_hs()
	if btnp(0) then
		sfx(54)
		if initials_conf then
			initials_conf=false
			sfx(56)
		end
		initials_conf=false
		initials_sel-=1
		if initials_sel<1 then
			initials_sel=3
		end
	end
	if btnp(1) then
		sfx(54)
		if initials_conf then
			initials_conf=false
			sfx(56)
		end
		initials_conf=false
		initials_sel+=1
		if initials_sel>3 then
			initials_sel=1
		end
	end
	if btnp(2) then
		sfx(53)
		if initials_conf then
			initials_conf=false
			sfx(56)
		end
		initials_conf=false
		initials[initials_sel]-=1
		if initials[initials_sel]<1 then
			initials[initials_sel]=#hschars
		end
	end
	if btnp(3) then
		sfx(53)
		if initials_conf then
			initials_conf=false
			sfx(56)
		end
		initials[initials_sel]+=1
		if initials[initials_sel]>#hschars then
			initials[initials_sel]=1
		end
	end
	if btnp(4) then
		sfx(55)
		if initials_conf then
			add_hs(score,initials[1],initials[2],initials[3])
			start_screen()
		else
			initials_conf=true
		end
	end
	if btnp(5) then
		if initials_conf then
			sfx(56)
			initials_conf=false
		end
	end
end

function update_win()
	if t<btnlockout then
		return
	end
	
	if btn(4)==false and btn(5)==false then
		btnreleased=true
	end

	if btnreleased then
		if loghs then
			handle_hs()
		else	
			if btnp(4) or btnp(5) then
				start_screen()
				btnreleased=false
				reset_hsb()
			end
		end
	end
end

function update_wavetext()
	update_game()
	animate_starfield()

	if t>wavetime then
		mode="game"
		spawn_wave()
	end
end

function handle_ship_controls()
	ship.spr=2
	ship.spx=0
	ship.spy=0
	flamespr=21
	if btn(0) then
		ship.spx=-2
		ship.spr=1
	end
	if btn(1) then
		ship.spx=2
		ship.spr=3
	end
	if btn(2) then
		ship.spy=-2
		flamespr=37
	end
	if btn(3) then
		ship.spy=2
		flamespr=5
	end
	
	if btnp(4) then
		if energy>0 then
			energy_bomb()
			energy=0
		else
			sfx(32)
		end
	end
	
	if btn(5) then
		if bulltimer<=0 then
			local bullet=make_spr()
			bullet.x=ship.x+1
			bullet.y=ship.y-3
			bullet.spr=16
			bullet.colw=6
			bullet.spy=-4
			bullet.dmg=1
			
			add(bullets,bullet)
			sfx(1)
			muzzle=5
			bulltimer=4
		end
	end
	bulltimer-=1
	
	move(ship)

	--animate flame
	flameani+=0.5
	if flameani>3 then
		flameani=0
	end
	
	--animate muzzle flash
	if muzzle>0 then
		muzzle-=1
	end

	--checking edges
	if ship.x>120 then
		ship.x=120
		sfx(0)
	elseif ship.x<0 then
		ship.x=0
		sfx(0)
	end
	if ship.y<0 then
		ship.y=0
		sfx(0)
	end
	if ship.y>120 then
		ship.y=120
		sfx(0)
	end
end

function animate_starfield(spd)
	spd=spd or 1
       
	for i=1,#stars do
	 local star=stars[i]
	 star.y+=(star.spd+warp/3)*spd
	 if star.y>128+warp then
	  stars[i]=rand_star(true)
	 end
	end
   
 --sort stars
 for i=2,#stars do
  if stars[i].spd<stars[i-1].spd then
   local s=stars[i]
   stars[i]=stars[i-1]
   stars[i-1]=s
  end
 end
	
	--warp speed
	if warp_time>0 then
	 --shake=warp/5
	 warp_time-=1
	 
	 flame_spr=49
	 if warp_mode=="in" then
   warp+=1
   if warp>20 then
				warp_mode="hold"
   end
	 elseif warp_mode=="hold" then
   if warp_time<=warp then
    warp_mode="out"
   end
	 elseif warp_mode=="out" then
   if warp>0 then
    warp-=1
   end
	 end
 end
end

function move_small_particles()
	for particle in all(smallparticles) do
		particle.x+=particle.dx
		particle.y+=particle.dy
		particle.dx*=.9
		particle.dy*=.9
  particle.age+=1
  if particle.age>=particle.maxage then
  	del(smallparticles,particle)
  end		
	end
end
-->8
--draw

function draw_game()
	if flash>0 then
		flash-=1
		cls(2)
	else
		cls(0)
	end
	
	draw_starfield()	
	animate_starfield()
	draw_ship()
	draw_hyperspace_trail()
	draw_bullets()
	draw_pickups()
	draw_enemies()
	draw_particles()
	draw_shockwaves()
	draw_floats()
	draw_small_particles()
	draw_interface()
end

function draw_ship()
	if ship.lives.curr>0 then
		if ship.invul<=0 then
			draw_spr(ship)
			spr(flamespr+flameani,ship.x,ship.y+8)	
		else
			--invul state
			if sin(t/5)<0.1 then
				draw_spr(ship)
				spr(flamespr+flameani,ship.x,ship.y+8)
			end
		end
	end

	if muzzle>0 then
		circfill(ship.x+3,ship.y-1,
			muzzle,7)
		circfill(ship.x+4,ship.y-1,
			muzzle,7)
	end
end

function draw_hyperspace_trail()
  if warp_time>0 then
    local w=abs(3*sin(t/20))+.1
    rectfill2(ship.x+4-w,
    ship.y+9,w+1,200-warp_time,7)
  	rectfill2(ship.x+4,
   	ship.y+9,w+1,200-warp_time,7)
  end
end

function draw_pickups()
	for pickup in all(pickups) do
		local col=7
		if t%4<2 then
			col=14
		end
		
		for i=1,15 do
			pal(i,col)
		end
		draw_outline(pickup)
		pal()
		draw_spr(pickup)
	end
end

function draw_enemies()
	for enemy in all(enemies) do
		if enemy.flash>0 then
			enemy.flash-=1
			
			if enemy.isboss then
				enemy.spr=64
				if t%4<2 then
					pal(11,14)
					pal(3,8)			
				end
			else
				replace_colors(7)
			end
		end
		
		draw_spr(enemy)
		pal() --reset color
	end
end

function draw_particles()
	for part in all(particles) do
		local pc=7
		
		if part.col~=nil then
			pc=part.col
		else
				if part.blue then
					pc=part_col_blue(part.age)
				else
				pc=part_col_red(part.age)
			end
		end
	
		if part.spark then
			pset(part.x,part.y,7)
		else
	 	circfill(part.x,part.y,
	 		part.size,pc)
		end
		
		part.x+=part.spdx
		part.y+=part.spdy
		part.age+=1
		part.spdx*=0.85
		part.spdy*=0.85
		
		if part.age>part.maxage then
			part.size-=0.5
			if part.size<0 then
				del(particles,part)
			end
		end
	end
end

function draw_shockwaves()
	for shock in all(shockwaves) do
		circ(shock.x+4,shock.y+4,
			shock.r,shock.col)
		shock.r+=shock.spd
		if shock.r>shock.maxr then
			del(shockwaves,shock)
		end
	end
end

function draw_floats()
	for float in all(floats) do
		local col=7
		if t%4<2 then
			col=8
		end
		cprint(float.txt,float.x,
			float.y,col)
		float.y-=0.5
		float.age+=1
		if float.age>60 then
			del(floats,float)
		end
	end
end

function draw_interface()
	for i=1,ship.lives.max do 
		if ship.lives.curr>=i then
			local heartspr=12
			if ship.lives.curr<ship.lives.max 
				and t%25<11 then
					heartspr=11
			end
			spr(heartspr,i*9,1)
		else
			spr(emptyheartspr,i*9,1)
		end
	end
		
	fprint("score: "..make_score(score),
		50,2,7,1)	
	draw_energy_bar()
end

function draw_bullets()
	--bullets
	for bull in all(bullets) do
		draw_spr(bull)
	end
		--enemy bullets
	for enembull in all(enembullets) do
		draw_spr(enembull)
	end
end

function draw_energy_bar()
	local startx=105
 	rectfill2(startx+1,3,19,4,1)
 	rectfill2(startx+20,4,1,2,1)
 	draw_spr(energyicon)
 
 	for i=1,energy do
  		rectfill2(startx+i*2,4,1,2,9)
 	end
end

function rectfill2(x,y,w,h,c)
 	rectfill(x,y,x+w-1,y+h-1,c)
end

function make_score(val)
	if val==0 then
		return "0"
	end
	return val.."00"
end

function draw_hs()
	print_hs(0)
end

function draw_start()
	cls(0)
	draw_starfield()
	print(version,1,1,1)
		
	draw_start_screen(0)
		
	print_hs(hs_x)
end

function draw_start_screen()
	local shift=(hs_x-128)
	local sinval=sin(time()/3.5)
		
	spr(132,16+shift,20,12,5)
	cprint("a short shmup",
		64+shift,62,6)
	
	cprint("press ⬅️ for high score list",
		64+shift,100,12)
	cprint("press ➡️ for main screen",
		shift+193,100,12)
		
	cprint("press 🅾️ to start",
		64,90,blink(greyblink))
end

function draw_over()
	draw_game()
	cprint("game over",64,40,8)
	cprint("score: "..make_score(score),
			64,50,blink(yellowblink))
	cprint("press any key to continue",
			64,90,blink(greyblink))
end

function draw_win()
	draw_game()
	draw_score_section()
end

function draw_wavetext()
	draw_game()
	if wave==lastwave then
		cprint("final wave!",
			64,40,blink(whiteblink))
	else
		cprint("wave "..wave .." of "
		.. lastwave,64,40,blink(greyblink),1)
	end
end

function draw_score_section()
	if loghs then
		cprint("★congratulations!★",
			64,30,12)
		cprint("you have a new highscore!",
			64,40,blink(yellowblink))
		cprint(make_score(score),
			64,50,blink(yellowblink))
		cprint("enter your initials",
			64,60,2)
		local colors={10,10,10}
		
		if initials_conf then
			colors={10,10,10}
		else
			colors[initials_sel]=blink(whiteblink)
		end
		
		cprint(hschars[initials[1]],58,70,colors[1])
		cprint(hschars[initials[2]],62,70,colors[2])
		cprint(hschars[initials[3]],66,70,colors[3])
	
		if initials_conf then
			cprint("press ❎ to confirm",
				64,80,blink(whiteblink))
		else
			cprint("use ⬅️➡️⬆️⬇️❎",56,80,2)
		end
	else
		cprint("★congratulations!★",
			64,40,12)
		cprint("score: "..make_score(score),
			64,50,blink(yellowblink))
		cprint("press any key to continue",
			64,90,blink(greyblink))
	end
end

function draw_starfield()	
	for star in all(stars) do
  line(star.x,star.y-star.spd*
    warp,star.x,star.y,star.c)
	end
end

function draw_small_particles()
	for particle in all(smallparticles) do
		draw_particle(particle)
	end
end

function draw_particle(p)
 local c=p.color
 if p.age<=10
 	and (c==11 or c==12) then 
  c=7
 end
 circfill(p.x,p.y,p.radius,c)
end
-->8
--tools

--centered horizontally text
function cprint(txt,x,y,col,framecol)
	fprint(txt,x-#txt*2,y,col,framecol)
end

--text with frame
function fprint(txt,x,y,c,framecol)
	for _x=-1,1 do
		for _y=-1,1 do
			print(txt,x+_x,y+_y,framecol)
		end
	end
	print(txt,x,y,c)
end

function blink(blinkanim)
	if blinkanim==nil then
		blinkanim={1}
	end
	local animsize=#blinkanim
	
	return blinkanim[flr(t/animsize)%animsize+1]
end

function draw_spr(obj)
	local sprx=obj.x
	local spry=obj.y
	
	if obj.shake>0 then
		obj.shake-=1

		-- <2 to get even shake
		if t%4<2 then
			sprx+=1
		end
	end
	
	if obj.bulmode then
		sprx-=2
		spry-=2
	end
	
	spr(obj.spr,sprx,spry,
			obj.sprw,obj.sprh)
end

function draw_outline(obj)
	spr(obj.spr,obj.x+1,obj.y,
		obj.sprw,obj.sprh)
	spr(obj.spr,obj.x-1,obj.y,
		obj.sprw,obj.sprh)
	spr(obj.spr,obj.x,obj.y+1,
		obj.sprw,obj.sprh)
	spr(obj.spr,obj.x,obj.y-1,
		obj.sprw,obj.sprh)
end

function collision(a,b)
	if a.isghost or b.isghost then
		return false
	end

	local a_left=a.x
	local a_top=a.y
	local a_right=a.x+(a.colw-1)
	local a_bottom=a.y+(a.colh-1)
	
	local b_left=b.x
	local b_top=b.y
	local b_right=b.x+(b.colw-1)
	local b_bottom=b.y+(b.colh-1)
	
	if a_top>b_bottom then return false end
	if b_top>a_bottom then return false end
	if a_left>b_right then return false end
	if b_left>a_right then return false end
	
	return true
end

function replace_colors(color)
	for i=1,15 do
			pal(i,color)
	end
end

function explode(x,y,isblue)
	local bigparticle={
		x=x,
		y=y,
		spdx=0,
		spdy=0,
		age=0,
		maxage=0,
		size=10,
		blue=isblue
	}
	
	add(particles,bigparticle)

	for i=1,30 do
		local particle={
			x=x,
			y=y,
			spdx=(rnd()-0.5)*6,
			spdy=(rnd()-0.5)*6,
			age=rnd(2),
			maxage=10+rnd(10),
			size=1+rnd(4),
			blue=isblue
		}
		
		add(particles,particle)
	end
	
	spark(x,y,true)
	shockwave(x,y,true)
end

function part_col_red(age)
		local col=7
		
		if age>5 then
			col=10
		end
		if age>7 then
			col=9
		end
		if age>10 then
			col=8
		end
		if age>12 then
			col=2
		end
		if age>15 then
			col=5
		end
		
		return col
end

function part_col_blue(age)
		local col=7
		
		if age>5 then
			col=6
		end
		if age>7 then
			col=12
		end
		if age>10 then
			col=13
		end
		if age>12 then
			col=1
		end
		if age>15 then
			col=1
		end
		
		return col
end

function shockwave(x,y,col,isbig)
	local shock={
		x=x,
		y=y,
		r=3, --radius
		maxr=isbig and 25 or 6, --max radius
		col=isbig and 7 or 9,
		spd=isbig and 3.5 or 1
	}
	add(shockwaves,shock)
end

function spark(x,y,isbig)
	local no=2
	local tspdx=(rnd()-0.5)*8
	local tspdy=(rnd()-1)*3
	
	if isbig then
		no=20
		tspdx=(rnd()-0.5)*12
		tspdy=(rnd()-0.5)*12
	end
		
	for i=1,no do
		local particle={
			x=x,
			y=y,
			spdx=tspdx,
			spdy=tspdy,
			age=rnd(2),
			maxage=10+rnd(10),
			size=1+rnd(4),
			blue=isblue,
			spark=true
		}
		add(particles,particle)
	end
end

function make_spr()
	local spr={
		x=0,
		y=0,
		spx=0,
		spy=0,
		flash=0,
		shake=0,
		animframe=1,
		spr=0,
		sprw=1,
		sprh=1,
		colh=8,
		colw=8
	}
	
	return spr
end

function anim_easing(obj,n)
		--x+=(targetx-x)/n
		obj.y+=ease_in(obj.y,obj.posy,n)
		obj.x+=ease_in(obj.x,obj.posx,n)
end

function ease_in(val,dval,n)
		return (dval-val)/n
end

function del_outside_screen(obj,array)
	if obj.y>128 or obj.y<-8
		or obj.x>128 or obj.x<-8 then
		del(array,obj)
	end
end

function shake_screen()
	--minus (shake/2) to get only positive values
	local shakex=rnd(shake)-(shake/2)
	local shakey=rnd(shake)-(shake/2)
	
	camera(shakex,shakey)
	
	if shake>10 then
		shake*=0.9
	else
		shake-=1
		if shake<1 then
			shake=0
		end
	end
end

function pop_float(txt,x,y)
	local float={
		x=x,
		y=y,
		txt=txt,
		age=0
	}
	add(floats,float)
end
-->8
--waves and enemies

function spawn_wave() 
	if wave<lastwave then
		sfx(28)
	else
		music(10)
	end
	
	if wave==1 then
  --space invaders
  attacfreq=60
  firefreq=20
  place_enemies({
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0}
  })
 elseif wave==2 then
  --red tutorial
  attacfreq=60
  firefreq=20
  place_enemies({
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1}
  })
 elseif wave==3 then
  --wall of red
  attacfreq=50
  firefreq=20
  place_enemies({
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1},
   {2,2,2,2,2,2,2,2,2,2},
   {2,2,2,2,2,2,2,2,2,2}
  })
 elseif wave==4 then
  --spin tutorial
  attacfreq=50
  firefreq=30
  place_enemies({
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3}
  })
 elseif wave==5 then
  --chess
  attacfreq=50
  firefreq=30
  place_enemies({
   {3,1,3,1,2,2,1,3,1,3},
   {1,3,1,2,1,1,2,1,3,1},
   {3,1,3,1,2,2,1,3,1,3},
   {1,3,1,2,1,1,2,1,3,1}
  })
 elseif wave==6 then
  --yellow tutorial
  attacfreq=60
  firefreq=30
  place_enemies({
   {2,2,2,0,4,0,0,2,2,2},
   {2,2,0,0,0,0,0,0,2,2},
   {1,1,0,1,1,1,1,0,1,1},
   {1,1,0,1,1,1,1,0,1,1}
  })
 elseif wave==7 then
  --double yellow
  attacfreq=70
  firefreq=30
  place_enemies({
   {3,3,0,1,1,1,1,0,3,3},
   {4,0,0,2,2,2,2,0,4,0},
   {0,0,0,2,1,1,2,0,0,0},
   {1,1,0,1,1,1,1,0,1,1}
  })
 elseif wave==8 then
  --hell
  attacfreq=80
  firefreq=30
  place_enemies({
   {0,0,1,1,1,1,1,1,0,0},
   {3,3,1,1,1,1,1,1,3,3},
   {3,3,2,2,2,2,2,2,3,3},
   {3,3,2,2,2,2,2,2,3,3}
  })
 elseif wave==9 then
  --boss
  attacfreq=60
  firefreq=20
  place_enemies({
   {0,0,0,0,5,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0}
  })
 end  
end

function place_enemies(lvl)
	for y=1,4 do
		local line=lvl[y]
		for x=1,10 do 
			if line[x]!=0 then
				spawn_enemy(line[x],
					x*12-6,4+y*12,x*3)
			end
		end
	end
end

function next_wave()
	wave+=1
	music(-1)

	if wave>lastwave then
		mode="win"
		btnlockout=t+30
		music(4)
		
		if score>hs[5] then
			loghs=true
			initials_conf=false
			initials_sel=1
		else
			reset_hsb()
		end
	else
  wavetime=t+200
		mode="wavetext"
		initialize_warp()
	end
end

function initialize_warp()
	warp=0
 	warp_mode="in"
 	warp_time=200
 	sfx(52)
end

function spawn_enemy(type,x,y,w)
	local enemy=make_spr()
	enemy.posx=x --intended pos
	enemy.posy=y
	enemy.behavior="flyin"
	enemy.wait=w
	enemy.x=x*1.25-16
	enemy.y=y-64
	enemy.type=type
	enemy.animsp=0.4
	
	if type==nil or type==1 then
		enemy.spr=21
		enemy.hp=3
		enemy.anim={144,144,145,145,144,146,146,147,147,146,146}
		enemy.score=1
	elseif type==2 then
		enemy.spr=148
		enemy.hp=2
		enemy.anim={160,161}
		enemy.score=2
	elseif type==3 then
		enemy.spr=184
		enemy.hp=4
		enemy.anim={128,129,130,131}
		enemy.score=3
	elseif type==4 then
		enemy.spr=208
		enemy.hp=20
		enemy.sprw=2
		enemy.sprh=2
		enemy.anim={208,210}
		enemy.colw=16
		enemy.colh=16
		enemy.score=5
	elseif type==5 then
		enemy.spr=68
		enemy.hp=2
		enemy.sprw=4
		enemy.sprh=3
		enemy.anim={68,72,76,72}
		enemy.colw=32
		enemy.colh=24		
		enemy.x=48
		enemy.y=-24
		enemy.posx=48
		enemy.posy=25
		enemy.isboss=true
	end
	
	add(enemies,enemy)
end
-->8
--behavior

function execute_behavior(enemy)
	if enemy.wait>0 then
		enemy.wait-=1
		return
	end
	
	if enemy.behavior=="flyin" then
		if enemy.isboss then
			local dy=(enemy.posy-enemy.y)/7	
			enemy.y+=min(dy,1)
		else
			anim_easing(enemy,7)
		end
		
		if abs(enemy.y-enemy.posy)<0.7 then
			enemy.y=enemy.posy
			enemy.x=enemy.posx
			if enemy.isboss then
				sfx(50)
				enemy.shake=20
				enemy.wait=28
				enemy.behavior="boss-p1"
				enemy.phasebegin=t
			else
				enemy.behavior="hover"
			end
		end
	elseif enemy.behavior=="hover" then
		--do nothing
	elseif enemy.behavior=="attack" then
		behavior_attack(enemy)
	elseif enemy.behavior=="boss-p1" then
		boss_phase_1(enemy)
	elseif enemy.behavior=="boss-p2" then
		boss_phase_2(enemy)
	elseif enemy.behavior=="boss-p3" then
		boss_phase_3(enemy)
	elseif enemy.behavior=="boss-p4" then
		boss_phase_4(enemy)
	elseif enemy.behavior=="boss-p5" then
		boss_phase_5(enemy)
	end
end

function behavior_attack(enemy)
	if enemy.type==1 then
		enemy.spy=1.7
		enemy.spx=sin(t/45)
		
		--if near the edge of screen
		--move more to center
		if enemy.x<32 then
			enemy.spx+=1-(enemy.x/32)
		end
		if enemy.x>88 then
			enemy.spx-=(enemy.x-88)/32
		end
	elseif enemy.type==2 then
		enemy.spy=2.5
		enemy.spx=sin(t/20)
		
		--if near the edge of screen
		--move more to center
		if enemy.x<32 then
			enemy.spx+=1-(enemy.x/32)
		end
		if enemy.x>88 then
			enemy.spx-=(enemy.x-88)/32
		end
	elseif enemy.type==3 then
		if enemy.spx==0 then
			enemy.spy=2
			if ship.y<=enemy.y then
				enemy.spy=0
				if ship.x<enemy.x then
					enemy.spx=-2
				else
					enemy.spx=2
				end
			end
		end		
	elseif enemy.type==4 then
		enemy.spy=0.35
		
		if enemy.y>110 then
			enemy.spy=1
		else
			if t%20==0 then
				firespread(enemy,8,1.3,
					time()/16)
			end
		end
	end
	
	move(enemy)	
end

function pick_timer()
	if mode!="game" then
		return
	end
	
	if t%attackfreq==0 then
		pick_attack()
	end
	
	if t>nextfire then
		pick_fire()
		nextfire=t+firefreq+rnd(firefreq)
	end
end

function pick_attack()
			--select bottom row enemies
		local maxnum=min(10,#enemies)
		local index=flr(rnd(maxnum))	
		index=#enemies-index
		
		local enemy=enemies[index]	
		if enemy==nil then return end
		
		if enemy.behavior=="hover" then
			enemy.behavior="attack"
			enemy.animsp*=3
			enemy.wait=60
			enemy.shake=60
		end
end

function pick_fire()
	--select bottom row enemies
	local maxnum=min(10,#enemies)
	local index=flr(rnd(maxnum))
	
	for enemy in all(enemies) do
		if enemy.type==4 and 
			enemy.behaviour=="hover" then
			if rnd()<0.5 then
				firespread(enemy,12,1.3,rnd())
				return
			end
		end
	end
		
	index=#enemies-index
	
	local enemy=enemies[index]
	if enemy==nil then return end
	
	if enemy.behavior=="hover" then
		if enemy.type==4 then
			firespread(enemy,12,1.3,rnd())
		elseif enemy.type==2 then
			aimed_fire(enemy,2)
		else
			fire(enemy,0,2)
		end
	end
end

function move(obj)
	obj.x+=obj.spx
	obj.y+=obj.spy
end

function kill_enemy(enemy)
	if enemy.isboss then
		enemy.behavior="boss-p5"
		enemy.phasebegin=t
		enemy.isghost=true
		enembullets={} --bullet cancelling
		music(-1)
		sfx(51)
		return
	end

	del(enemies,enemy)
	sfx(2)
	explode(enemy.x+4,enemy.y+4)
	
	local diamondchance=0.1
	local scoremulti=1

	if enemy.behavior=="attack" then
		if rnd()<0.5 then
			pick_attack()
		end
		diamondchance=0.2
		scoremulti=2
	end
	
	local calcscore=enemy.score*scoremulti
	score+=calcscore
	
	if scoremulti!=1 then
		pop_float(make_score(calcscore),
			enemy.x+4,enemy.y+4)
	end
	
	if rnd()<diamondchance then
		drop_pickup(enemy.x,enemy.y)	
	end
	
end

function drop_pickup(x,y)
	local pickup=make_spr()
	pickup.x=x
	pickup.y=y
	pickup.spy=0.75
	if energy==energy_max-1 then
		pickup.spr=49
	else
		pickup.spr=48
	end
	add(pickups,pickup)
end

function add_particle(x,y,dx,dy,radius,color,maxage)
	add(smallparticles,{
		x=x,y=y,
		dx=dx,dy=dy,
		radius=radius,
		color=color,
		maxage=maxage,
		age=0
	})
end

function decide_pickup(pickup)
	energy+=1
	shockwave(pickup.x,pickup.y,
		false)
		
	local part_col=10

	if energy>=energy_max-1 then
		if ship.lives.curr<ship.lives.max then
			ship.lives.curr+=1
			sfx(31)
			energy=0
			pop_float("1up!",pickup.x,
				pickup.y)
			part_col=11
		else
			pop_float(make_score(50),pickup.x,
				pickup.y)
			sfx(30)
			score+=50
			energy=0
		end
	else
		sfx(30)
	end
	
	for j=1,16 do
  local rn=rnd()
  local rn2=rnd(.5)
 	add_particle(pickup.x,pickup.y,
 		sin(rn)*rn2*3,cos(rn)*rn2*3,
 		1,part_col,32)
 end	
end

function animate(enemy)
	enemy.animframe+=enemy.animsp
	if flr(enemy.animframe)>#enemy.anim then
		enemy.animframe=1
	end

	enemy.spr=enemy.anim[flr(enemy.animframe)]
end

-->8
--bullets

function fire(enemy,ang,spd) 
		local enembull=make_spr()
		enembull.spr=32
		enembull.x=enemy.x+3
		enembull.y=enemy.y+6
		
		if enemy.type==4 then
			enembull.x=enemy.x+7
			enembull.y=enemy.y+13
		elseif enemy.isboss then
			enembull.x=enemy.x+15
			enembull.y=enemy.y+23
		end
		
		enembull.anim={32,33,34,32}
		enembull.animsp=0.5
		
		enembull.spx=sin(ang)*spd
		enembull.spy=cos(ang)*spd

		enembull.colw=2
		enembull.colh=2
		enembull.bulmode=true
		
		if not enemy.isboss then
			enemy.flash=4
			sfx(29)
	 else
	 	sfx(34)
	 end
		
		add(enembullets,enembull)
		
		return enembull
end

function firespread(enemy,num,
	spd,baseang) 
		
		if baseang==nill then
			baseang=0
		end
		
		for i=1,num do
			fire(enemy,1/num*i+baseang,spd)
		end
end

function aimed_fire(enemy,spd)
	local enemybull=fire(enemy,0,spd)
	
	--angle between two points
	local ang=atan2((ship.y+4)-enemybull.y,
		(ship.x+4)-enemybull.x)
	
	enemybull.spx=sin(ang)*spd
	enemybull.spy=cos(ang)*spd
end

function energy_bomb()
	local spacing=0.25/(energy*2)
	for i=0,energy*2 do
		local ang=0.375+spacing*i
		local bullet=make_spr()
		bullet.x=ship.x
		bullet.y=ship.y-3
		bullet.spr=17
		bullet.spx=sin(ang)*4
		bullet.spy=cos(ang)*4
		bullet.dmg=3
		add(bullets,bullet)
	end
	
	shockwave(ship.x+3,ship.y+3,true)
	muzzle=5
	shake=5
	flash=3
	sfx(33)
	ship.invul=30
end
-->8
--boss

function boss_phase_1(boss)
	--movement
	local spd=2
	
	if boss.spx==0 or boss.x>=93 then
		boss.spx=-spd
	end
	if boss.x<3 then
		boss.spx=spd
	end

	--shooting
	if t%30>3 then
		if t%3==0 then
			fire(boss,0,2)
		end
	end
	
	--transition
	--8*30=8 seconds
	if boss.phasebegin+8*30<t then	
		boss.behavior="boss-p2"
		boss.phasebegin=t
		boss.subphase=1
	end
	move(boss)
end

function boss_phase_2(boss)
	--movement
	local spd=1.5
	
	if boss.subphase==1 then
		boss.spx=-spd
		if boss.x<=4 then
			boss.subphase=2
		end
	elseif boss.subphase==2 then
		boss.spx=0
		boss.spy=spd
		if boss.y>=100 then
			boss.subphase=3
		end	
	elseif boss.subphase==3 then
		boss.spx=spd
		boss.spy=0
		if boss.x>=91 then
			boss.subphase=4
		end
	elseif boss.subphase==4 then
		boss.spx=0
		boss.spy=-spd
		if boss.y<=25 then
			--transition
			boss.behavior="boss-p3"
			boss.phasebegin=t
		end	
	end
	
	--shooting
	if t%10==0 then
		aimed_fire(boss,spd)
	end
	
	move(boss)
end

function boss_phase_3(boss)
	--movement
	local spd=0.5
	boss.spy=0
	
	if boss.spx==0 or boss.x>=93 then
		boss.spx=-spd
	end
	if boss.x<3 then
		boss.spx=spd
	end
	
	--shooting
	if t%10==0 then
		firespread(boss,8,2,time()/2)
	end
	
	--transition
	if boss.phasebegin+8*30<t then
		boss.behavior="boss-p4"
		boss.phasebegin=t
		boss.subphase=1
	end
	move(boss)
end

function boss_phase_4(boss)
	--movement
	local spd=1.5
	
	if boss.subphase==1 then
		boss.spx=spd
		if boss.x>=91 then
			boss.subphase=2
		end
	elseif boss.subphase==2 then
		boss.spx=0
		boss.spy=spd
		if boss.y>=100 then
			boss.subphase=3
		end	
	elseif boss.subphase==3 then
		boss.spx=-spd
		boss.spy=0
		if boss.x<=4 then
			boss.subphase=4
		end
	elseif boss.subphase==4 then
		boss.spx=0
		boss.spy=-spd
		if boss.y<=25 then
			--transition
			boss.spy=0
			boss.behavior="boss-p1"
			boss.phasebegin=t
		end	
	end
	
	--shooting
	if t%12==0 then		
		if boss.subphase==1 then
			fire(boss,0,2)
		elseif boss.subphase==2 then
			fire(boss,0.25,2)
		elseif boss.subphase==3 then
			fire(boss,0.5,2)
		elseif boss.subphase==4 then
			fire(boss,0.75,2)		
		end
	end
	
	move(boss)
end

function boss_phase_5(boss)
	boss.shake=10
	boss.flash=10
	
	if t%8==0 then		
		explode(boss.x+rnd(32),boss.y+rnd(24))
		sfx(2)
		shake=2
	end
	
	--increase explosions at the end
	if boss.phasebegin+3*30<t then
		if t%4==2 then
			explode(boss.x+rnd(32),boss.y+rnd(24))
			sfx(2)
			shake=2
		end
	end
	
	if boss.phasebegin+6*30<t then
		score+=100
		pop_float(make_score(100),
			boss.x+16,boss.y+12)
		explode_boss(boss.x+16,boss.y+12)
		shake=15
		flash=3
		sfx(35)
		del(enemies,boss)
	end
end

function explode_boss(x,y)
	local bigparticle={
		x=x,
		y=y,
		spdx=0,
		spdy=0,
		age=0,
		maxage=0,
		size=25,
	}
	
	add(particles,bigparticle)

	for i=1,60 do
		local particle={
			x=x,
			y=y,
			spdx=(rnd()-0.5)*12,
			spdy=(rnd()-0.5)*12,
			age=rnd(2),
			maxage=20+rnd(20),
			size=1+rnd(6),
		}
		
		add(particles,particle)
	end
	
	--sparks
	local tspdx=(rnd()-0.5)*30
	local tspdy=(rnd()-0.5)*30
	
	for i=1,100 do
		local particle={
			x=x,
			y=y,
			spdx=tspdx,
			spdy=tspdy,
			age=rnd(2),
			maxage=20+rnd(20),
			size=1+rnd(4),
			spark=true
		}
		add(particles,particle)
	end
	shockwave(x,y,true)
end
-->8
--highscore
 
function reset_hs()
 --create default values
 hs={10,300,400,200,1000}
 hs1={1,1,8,1,1}
 hs2={1,6,1,1,14}
 hs3={10,1,1,12,1}
 hsb={true,false,false,false,false}
 save_hs()
end

function add_hs(score,c1,c2,c3)
	add(hs,score)
	add(hs1,c1)
	add(hs2,c2)
	add(hs3,c3)
	for i=1,#hsb do
		hsb[i]=false
	end
	add(hsb,true)
	save_hs()
end
 
function load_hs()
 local slot=0
 
 if dget(0)==1 then
  --load the data
  slot+=1
  for i=1,5 do
   hs[i]=dget(slot)
   hs1[i]=dget(slot+1)
   hs2[i]=dget(slot+2)
   hs3[i]=dget(slot+3)
   slot+=4
  end
 else
  --file is empty
  reset_hs()
 end
end
 
function save_hs()
	sort_hs()
 local slot
 dset(0, 1)
 --load the data
 slot=1
 for i=1,5 do
  dset(slot,hs[i])
  dset(slot+1,hs1[i])
  dset(slot+2,hs2[i])
  dset(slot+3,hs3[i])
  slot+=4
 end
end
 
function print_hs(x)
 rectfill(x+29,8,x+99,16,8)
 cprint("high score list",
 	x+65,10,7)
 
 for i=1,5 do
  fprint(i.." - ",x+30,14+7*i,5)
  local col=7
  if hsb[i] then
  	col=blink(greyblink)
  end
  local name=hschars[hs1[i]]
  name=name..hschars[hs2[i]]
  name=name..hschars[hs3[i]]  
  fprint(name,x+45,14+7*i,col)

  local score=" "..hs[i]
  fprint(score,(x+100)-(#score*4),14+7*i,col)  
 end
end

function reset_hsb()
	for i=1,#hsb do
		hsb[i]=false
	end
	hsb[1]=true
end

--insertion sort
function sort_hs()
 for i=1,#hs do
  local j=i
  while j>1 and hs[j-1]<hs[j] do
   hs[j],hs[j-1]=hs[j-1],hs[j]
   hs1[j],hs1[j-1]=hs1[j-1],hs1[j]
   hs2[j],hs2[j-1]=hs2[j-1],hs2[j]
   hs3[j],hs3[j-1]=hs3[j-1],hs3[j]
   hsb[j],hsb[j-1]=hsb[j-1],hsb[j]
   j=j-1
  end
 end
end
__gfx__
00000000000110000001100000011000000000000000000000000000000000000000000000000000000000000220022008800880055005500000000000000000
00000000001dd100001dd100001dd100000000000007700000077000000770000097790000000000000000002882288288888888566556650000000000000000
00700700001cc100001cc100001cc10000000000009aa900000aa000009aa90008999980000000000000000028888e8288888788566667650000000000000000
0007700001dccd1001dccd1001dccd10000000000089980000099000008998000088880000000000000000002888888288888888566666650000000000000000
000770000176cc101dc76cd101cc6710000000000008800000099000000880000000000000000000000000000288882008888880056666500000000000000000
007007000166cc101cc66cc101cc6610000000000000000000088000000000000000000000000000000000000028820000888800005665000000000000000000
000000000155d1101cd55dc1011d5510000000000000000000000000000000000000000000000000000000000002200000088000000550000000000000000000
0000000000d44d0001d44d1000d44d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0997799009aaaa900000000000000000000000000007700000077000000770000097790000000000000000000000000000000000000000000000000000000000
09a77a909aa77aa9000000000000000000000000009aa900000aa000009aa9000099990000000000000000000000000000000000000000000000000000000000
09a77a909a7777a900000000000000000000000000999900000aa000009999000008800000000000000000000000000000000000000000000000000000000000
09a77a909a7777a90000000000000000000000000089980000099000008998000000000000000000000000000000000000000000000000000000000000000000
09aaaa909aa77aa90000000000000000000000000008800000099000000880000000000000000000000000000000000000000000000000000000000000000000
009aa90009aaaa900000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000
00099000009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ee000000ee000000770000000000000000000000077000000770000007700000a77a0000000000000000000000000000000000000000000000000000000000
0e22e0000e88e00007cc70000000000000000000009aa900000aa000009aa90009aaaa9000000000000000000000000000000000000000000000000000000000
e2e82e00e87e8e007c77c7000000000000000000009aa90000aaaa00009aa900089aa98000000000000000000000000000000000000000000000000000000000
e2882e00e8ee8e007c77c700000000000000000000999900009aa900009999000899998000000000000000000000000000000000000000000000000000000000
0e22e0000e88e00007cc700000000000000000000089980000999900008998000089980000000000000000000000000000000000000000000000000000000000
00ee000000ee00000077000000000000000000000088880000899800008888000088880000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008800000088000000880000008800000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008800000088000000880000000000000000000000000000000000000000000000000000000000000000000
000dd000033003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d66d003bb33bb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa9003bbbb7b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d1ff1d03bbbbbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d9aa9d03bbbbbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d1ff1d003bbbb300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa900003bb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dffd00000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee00000
ee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000ee
e7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7e
8e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e8
08e813bbbbbbbba77abbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e80
088811bbbbbbbbbaabbbbbbbbb11888008881133b33bbbbbbbbbb33b3311888008881133b33bbbbbbbbbb33b3311888008881133b33bbbbbbbbbb33b33118880
0011133bbbbb33bbbb33bbbbb331110000113b11bbb3333333333bbb11b3110000113b11bbb3333333333bbb11b3110000113b11bbb3333333333bbb11b31100
00bb113bbabbb33bb33bbbabb311bb0000bb13bb13bbb333333bbb31bb31bb0000bb13bb13bbb333333bbb31bb31bb0000bb13bb13bbb333333bbb31bb31bb00
bb333113bbabbbbbbbbbbabb311333bbbb3331333333bba77abb3333331333bbbb3331333333bba77abb3333331333bbbb3331333333bba77abb3333331333bb
bbbb31333bbaa7bbbb7aabb33313bbbbb7713ee6633333bbbb3333366ee3177bb7713ee6633333bbbb3333366ee3177bb7713ee6633333bbbb3333366ee3177b
3b333313333bbb7777bbb333313333b337113eefff663333333366fffee3117337113eefff663333333366fffee3117337113eefff663333333366fffee31173
c333333bb33333bbbb33333bb333333cc3773efff77f17711111f77fffe3773cc3773efff77f17711111f77fffe3773cc3773efff77f17711111f77fffe3773c
0c3bb3b3bbb3333333333bbb3b3bb3c00c3b3eff777717711c717777ffe3b3c00c3b3eff777717711c717777ffe3b3c00c3b3eff777717711c717777ffe3b3c0
00c1bb3b33bbbb3333bbbb33b3bb1c0000c1b3ef7777711cc7177777fe3b1c0000c1b3ef7777711cc7177777fe3b1c0000c1b3ef7777711cc7177777fe3b1c00
00013bb3bb333bbbbbb333bb3bb3100000013b3eff777711117777ffe3b3100000013b3eff777711117777ffe3b3100000013b3eff777711117777ffe3b31000
0331c3bb33aaa333333aaa33bb3c13300331c3b3eef7777777777fee3b3c13300031c3b3eef7777777777fee3b3c13000031c3b3eef7777777777fee3b3c1300
3bb31c3bbb333a7777a333bbb3c13bb33bb31c3b33eee777777eee33b3c13bb303b31c3b33eee777777eee33b3c13b30003b1c3b33eee777777eee33b3c1b300
3ccc13c3bbbbb333333bbbbb3c31ccc33ccc13c3bb333eeeeee333bb3c31ccc33bcc13c3bb333eeeeee333bb3c313cb303bc13c3bb333eeeeee333bb3c31cb30
00003b3c33bbbba77abbbb33c3b3000000003b3c33bbb333333bbb33c3b300003c003b3c33bbb333333bbb33c3b300cc03c0333c33bbb333333bbb33c3330c30
0003b3ccc333bbbbbbbb333ccc3b30000003b3ccc333bba77abb333ccc3b300000003b3cc333bba77abb333cc3b3000000003b3cc333bba77abb333cc3b30000
00033c003bc33bbbbbb33cb300c3300000033c003bc33bbbbbb33cb300c33000000033c03bc33bbbbbb33cb30c33000000003bc03bc33bbbbbb33cb30cb30000
0003c0003b3c3cb22bc3c3b3000c30000003c0003b3c3cb22bc3c3b3000c300000003c003b3c3cb22bc3c3b300c30000000003c0c3bc3cb22bc3cb3c0c300000
0000000033c0cc2112cc0c33000000000000000033c0cc2112cc0c330000000000000000c330cc2112cc033c00000000000000000c30cc2112cc03c000000000
00000000cc0000c33c0000cc0000000000000000cc0000c33c0000cc00000000000000000cc000c33c000cc0000000000000000000cc00c33c00cc0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d89d00001891000018910000198100cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
0d5115d000d515000011110000515d00cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
d51aa15d0151a11000155100011a1510ccccc1111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000
d51aa15d0d51a15000d55d00051a15d0ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6d5005d6065005d0006dd6000d500560ccccc0000000000000cccccccccccccc0cccccccccccccc00cccccccccccccc00ccccccccccccccc0ccccc00cccccccc
66d00d60006d0d600066660006d0d600ccccc0000000000000cccccccccccccc0cccccccccccccc00cccccccccccccc00ccccccccccccccc0ccccc00cccccccc
07600670006606000006600000606600ccccc0000000000000ccccc1111ccccc0ccccc1110ccccc00ccccc1111ccccc00ccccc11111ccccc0ccccc00cccccccc
00700700000707000007700000707000cccccccccccccc0000ccccc1000ccccc0ccccc0000ccccc00ccccc1000ccccc00ccccc10000ccccc0ccccc00cccccccc
03300330033003300330033003300330cccccccccccccc0000ccccc0000ccccc0ccccc0000ccccc00ccccc0000ccccc00ccccc10000ccccc0ccccc00cccccccc
33b33b3333b33b3333b33b3333b33b33ccccccc11111100000ccccccc00ccccc0cccccccccccccc00ccccccc00ccccc00ccccc00cccccccc0ccccc00cccccccc
3bbbbbb33bbbbbb33bbbbbb33bbbbbb3ccccccc00000000000ccccccc00ccccc0cccccccccccccc00ccccccc00ccccc00ccccc00cccccccc0ccccc00cccccccc
3b7bb7b33b7bb1b33b7bb7b33b1bb7b3ccccccc00000000000ccccccc00ccccc0cccccccccccccc00ccccccc00ccccc00ccccc00cccccccc0ccccc00cccccccc
0b7117b00b7711b00b7117b00b1177b0ccccccc00000000000ccccccc00ccccc0ccccccc111111000ccccccc001111000ccccc00cccccccc0ccccc00111ccccc
00377300003773000037730000377300ccccccc00000000000ccccccc00ccccc0ccccccc000000000ccccccc000000000ccccc00cccccccc0ccccc00000ccccc
03033030030330300303303003033030ccccccc00000000000ccccccc00ccccc0ccccccc000000000ccccccc000000000ccccc00cccccccc0ccccc00000ccccc
03000030300000030300003003300330cccccccccccccccc00ccccccc00ccccc0cccccccccccccc00ccccccc000000000ccccccccccccccc0ccccccccccccccc
20000002020000200000000000000000cccccccccccccccc00ccccccc00ccccc0cccccccccccccc00ccccccc000000000ccccccccccccccc0ccccccccccccccc
22000022220000220000000000000000111111111111111000111111000111100111111111111100011111100000000001111111111ccccc01111111111ccccc
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc00000000001ccccc
282222822822228200000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccc000ccccccccccccc
288888822888888200000000000000000000900000000900000000900000000000000000000000000000000000000000000ccccccccccccc000ccccccccccccc
2878878228788782000000000000000000000900aaaa090aaaa00900000000000000000000000000000000000000000000011111111111110001111111111110
28888882080000800000000000000000000000900000090000009000000000000000000000000000000000000000000000000000000000000000000000000000
080000800000000000000000000000000000000900009990000900000000000cccccccccccccc000000000000000000000000000000000000000000000000000
0008800000099000000890000008900000000a0090009a9000900a000000000cccccccccccccc000000000000000000000000000000000000000000000000000
7066660507666650006766000066560000000a0009099a9909000a000000000ccccc1111ccccc0000ccccc00000000000000000000000000000000000ccccc00
1661c66101616610006666000016660000000a000009aaa900000a000000000ccccc1000ccccc0000ccccc00000000000000000000000000000000000ccccc00
7066660507666650006766000066560000000a000999a7a999000a000000000ccccc0000ccccc0000ccccc000000ccccccccccccccccccccccccc0000ccccccc
007665000076650000766500007665000000000999aaa7aaa99900000000000ccccc0000ccccc0000ccccc000000ccccccccccccccccccccccccc0000ccccccc
0007500000075000000750000007500000009999aaa77777aaa999990000000ccccc0000ccccc0000ccccc00000011111111cccccccccc11111100000ccccc11
000750000007500000075000000750000000000999aaa7aaa99900000000000cccccccccccccccc00ccccccc000000000000cccccccccc00000000000ccccc10
0006000000060000000600000006000000000a000999a7a999000a000000000cccccccccccccccc00ccccccc000000000000cccccccccc00000000000ccccc00
0000000000000000000000000000000000000a000009aaa900000a000000000ccccccc1111ccccc00ccccccc00ccccccccccccccccccccccccccccc00ccccc00
0000000000000000000000000000000000000a0009099a9909000a000000000ccccccc1000ccccc00ccccccc00ccccccccccccccccccccccccccccc00ccccc00
0000000000000000000000000000000000000a0090009a9000900a000000000ccccccc0000ccccc00ccccccc00ccccc11cccccccc1111111ccccccc00ccccc00
000000000000000000000000000000000000000900009990000900000000000ccccccc0000ccccc00ccccccc00ccccc10cccccccc1000000ccccccc00ccccccc
000000000000000000000000000000000000009000000900000000000000000ccccccc0000ccccc00ccccccc00ccccc00cccccccc0000000ccccccc00ccccccc
0000000000000000000000000000000000000900aaaa090aaaaa00000000000cccccccccccccccc00ccccccc00ccccccccccccccccccccccccccccc00ccccccc
000000000000000000000000000000000000900000000900000000900000000cccccccccccccccc00ccccccc00ccccccccccccccccccccccccccccc00ccccccc
00000000000000000000000000000000000000000000000000000000000000011111111111111100011111100011111111111111111111111111110001111110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000149aa94100000000012222100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00019777aa921000000029aaaa920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d09a77a949920d00d0497777aa920d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0619aaa9422441600619a77944294160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07149a922249417006149a9442244160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07d249aaa9942d7006d249aa99442d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
067d22444422d760077d22244222d770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d666224422666d00d776249942677d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
066d51499415d66001d1529749251d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0041519749151400066151944a151660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a001944a100a0000400149a4100400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000049a400090000a0000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001e7301d7401d760127601177012770207701e7701d7701977019770187701777017770167701677016770197601b7601e760207502375024740247402373022730207301f7301e7301d7301b73017730
0002000032520305202c5202952025520225201e5201b5201652012520105200d5200b52009520075200552004520035200251001510000000000000000000000000000000000000000000000000000000000000
000100002c650346502f65027650216501b650156501365011650106500f6500b6500965008650056500365003650000000000000000000000000000000000000000000000000000000000000000000000000000
0001000034750096502f530206200f620085200552002720007100060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000010501605019050160501905001050160501905016050190601b0611b0611b061290001d000170002600001050160501905016050190500105016050190501b0611b0611b0501b0501b0401b0301b025
00060000205401d540205401d540205401d540205401d54022540225502255022550225500000000000000000000025534225302553022530255301d530255302253019531275322753027530275322753027530
000600001972020720227201b730207301973020740227401b74020740227402274022740000000000000000000001672020720257201b730257301973025740227401b740277402274027740277402774027740
001000001f5501f5501b5501d5501d550205501f5501f5501b5501a5501b5501d5501f5501f5501b5501d5501d550205501f5501b5501a5501b5501d5501f5502755027550255502355023550225502055020550
011000000f5500f5500a5500f5501b530165501b5501b550165500f5500f5500a5500f5500f5500a550055500a5500e5500f5500f550165501b5501b550165501755017550125500f5500f550125501055010550
001000001e5501c5501c550175501e5501b550205501d550225501e55023550205501c55026550265500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000017550145501455010550175500b550195500d5501b5500f5501c550105500455016550165500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080d00001b0001b0001b0001d0001b0301b0001b0201d0201e0302003020040200401e0002000020000200001b7001d7001b7001b7001b7001d700227001a7001b7001b700167001b7001b7001b7001c7001c700
040d00001f5001f0001f500215001f5301f0001f52021520225302453024530245302250024500245002450000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d00002200022000220002400022030220002203024030250302703027030270302500027000270002700000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d1000002b0202b0202b0202b0202b0202b0202b0202b0202b020290202b0202c0202b0202b0202b0202602026020260202702027020270202b0202b0202b0202a0302a0302a0302703027030270302003020030
4d1000002003028030280302c0302a0302a0302a0302703027030270302c0302a030290302e0302e0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00001e050000001e0501d0501b0501a0601a0621a062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050f00001b540070001b5401a54018540175501755217562075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000
010c0000290502c0002a00029055290552a000270502900024000290002705024000240002400027050240002a05024000240002a0552a055240002905024000240002400029050240002a000290002405026200
510c00001431519315203251432519315203151432519325203151431519325203251431519315203251432519315203151432519325203151431519325203251431519315203251432519315203151432518325
010c00000175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750
010c0000195502c5002a50019555195552a500185502950024500295001855024500245002450018550245001b55024500245001b5551b555245001955024500245002450019550245002a500295001855026500
010c0000290502c0002a00029055290552a000270502900024000290002000024000240352504527050240002a050240002f0052d0552c0552400029050240002400024000240002400024030250422905026200
010c0000195502c5002a50019555195552a500185502950024500295002050024500145351654518550245001b550245002f5051e5551d5552450019550245002450024500245002450014530165401955026500
010c00002c05024000240002a05529055240002e050240002400029000270502400024000240002e050240003005024000240002e0552d05524000300502400024000290002905024000270002a0002900028000
510c0000143151931520325143251931520315163251932516315183151932516325183151931516325183251b3151e315183251b3251e315183151b3251e325183151b3151d325183251b3151d315183251b325
010c00000175001750017500175001750017500175001750037500375003750037500375003750037500375006750067500675006750067500675006750067500575005750057500575005750057500575005750
010c00001d55024500245001b55519555245001e550245002450029500165502450024500245001e550245001e55024500245001d5551b555245001d5502450024500295001855024500275002a5002950028500
110400003e5723d5723b572385723457231572305622d5622b562285622556223562215621f5521e5521c5521b55218552165421454212532115220f5220e5220d5220c5120a5120851207512055120351202512
000200001835202302123420932206322053220535200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302
10020000095520a5520b5620c5620e5421253216522145221a5221a5221d5120950201502005021d5020a50200502105020050200002000020000200002000020000200002000020000200002000020000200002
00090000050560a0660f076150761906621056240472a03734037340373b0373f0573500700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000744007420074200040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
4a0200002b6512e661306613166133661346612f6612e6612d6612d6612d6712866125651226511f6511e6511d641146411a641106410b6411064114641066310562104621036310262101621016210061100611
01010000091400a1500a1600f160131400d1400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020400003a670376303567032670306702e6102c6702a6702965026650246502365022650206501f6501d6501c6501b65019640176401564012640116400f6400d6200a620086200662004620026200060000600
010a00000c4200c4200c4200c4200c4200c4200c4200c4200f4200f4200f4200f4200f4200f4200f4200f42010420104201042010420104201042010420104201442014420144201442014420144201442014420
010a00000532105320053200532005320053200532005320083200832008320083200832008320083200832009320093200932009320093200932009320093200d3200d3200d3200d3200d3200d3200d3200d320
000a002034615296152b6161e6061c6401d6452b6152760528615296152b6151e6001c6401d6452b6152761534615296152b6161e6061c6401d6452b6152760528615356152b6151e6051c6401d6452b61527615
050a00200232002320023200232002320023200232002320023200230502325023250232002325023200232503320033200332003320033200332003320033200732007320073200732007320073200732007320
010a000002320023200232002320023200232002320023200a3200a3200a3200a3200a3200a3200a3200a32005320053200532005320053200532005320053200332003320033200332003320033200332003320
010a000009220092200922009220092200922009220092200e2200e2200e2200e2200e2200e2200e2200e2200a2200a2200a2200a2200a2200a2200a2200a2200022000220002200022001220012200122001220
010a000005220052200522005220052200522005220052200e2200e2200e2200e2200e2200e2200e2200e2200a2200a2200a2200a2200a2200a2200a2200a2200022000220002200022001220012200122001220
010a00000d2200d2200d2200d2200d2200d2200d2200d220052200522005220052200522005220052200522011220112201122011220112201122011220112200322003220032200322003220032200322003220
150a00001522015220152201522015220152201522015220152201522015220152201322013220152201522016220162201622016220162201622016220162201922019220192201922019220192201922019220
150a00001a2201a2201a2201a2201a2201a2201a2251a2251d2201d2201d2201d2201d2201d2201d2201d22019220192201922019220192201922019220192201622016220162201622016220162201622016220
150a0000192201922019220192201922019220192251922511220112201122011220112201122011220112201d2201d2201d2201d2201d2201d2201d2201d22018220192211a2211d22121221252212622126221
090a00001d2171a217212172221729217262172d2172e2171d2171a2172121722217112170e21715217162171d2171a217212172221729217262172d2172e2171d2171a2172121722217112170e2171521716217
090a000029217262172d2172e2173521732217392173a21729217262172d2172e2171d2171a2172121722217112170e21715217162171d2171a2172121722217112170e21715217162170521702217092170a217
010a00000e003296000e0031e600286151d6052b605276150e003296052b6151e600286151d6452b615276051f6501f6301f6201e6001f6251f6251f625276050e003356052b6051e605106111c6112862133631
5c030000131212513131151381711b1613b1513b1413c14116141291413913135131321312d13228132221321c13216132131321d1320e1320d1320a132091320813206122051220412203122031220312201120
5c0400000817120161181610f17108171171711017109171071710d1610f161091510715106151051410514105132041320313202132021320113201132001320113201132011320112200122001220012200122
7a0c000003610076200a6300b6400c6400c6500c6500c6500c6600c6600c6600c6600c6600c6600c6600c6600c6600c6600c6600c6600c6600c6600c6600c6600c6500c6500c6500b6400a640076300562001610
00030000344503d450004000040000400004000040000400004000040000400004002140000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000200000d42012420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002805128051310303103036000390001f0001f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002e0502e050280302803000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002805128051310303103036030390301f0301f0302803128031310303103036030390301f0101f01028010280103101031010360103901010010100102801028010310103101036010390161001610016
000100000c6101061012610176101c6101f61021610256102c610336203a6203a620396203762037620256201c61019610186101661014610116100c610096100261012600006001160011600116000000000000
__music__
00 04050644
00 07084749
04 090a484a
04 0b0c0d44
00 0e084344
04 0f0a4344
04 10114e44
01 12131415
00 16131417
02 18191a1b
00 24256844
01 26272844
00 26282966
00 26272a65
00 262a2b65
00 26272c44
00 26292d44
00 26272c44
00 262a2e44
00 28292f44
00 28293044
00 272b2f44
02 25243144

