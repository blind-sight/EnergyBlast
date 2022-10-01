pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
	--main

function _init()
	cls(0)
	cartdata("schmup")
	
	--sprites
	flamespr=5
	heartspr=12
	emptyheartspr=13
	
	start_screen()
	
	highscore=dget(0)
	shake=0
	flash=0
	btnlockout=0
	blinkt=0
	t=0 --number of frames
	
	debug=""
end

-- (gameplay hard 30fps)
function _update()
	blinkt+=1
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
	music(7)
end

function start_game()
	score=0
	energy=9
	muzzle=0
	bulltimer=0
	wave=0
	lastwave=9
	next_wave()
	
	ship=make_spr()
	ship.x=60
	ship.y=90
	ship.spr=2
	ship.spx=0
	ship.spy=0
	ship.lives={max=4,curr=4}
	ship.invul=0 --invulnerability
	
	stars={}	
	bullets={}
	enembullets={}
	enemies={}
	particles={}	
	shockwaves={}
	pickups={}
	floats={} --floating elements
	
	attackfreq=60
	firefreq=20
	nextfire=0
			
	for i=1,100 do
		local newstar={
			x=flr(rnd(128)),
			y=flr(rnd(128)),
			spd=rnd(1.5)+0.5
		}
		add(stars,newstar)
	end
end
-->8
--update

function update_game()
	handle_ship_controls()
	
	--moving bullets
	for bull in all (bullets) do
		move(bull)
		
		del_outside_screen(bull,bullets)
	end
	
	--moving pickups
	for pickup in all (pickups) do
		move(pickup)
		
		del_outside_screen(pickup,pickups)
	end
	
	--move enemy bullets
	for enembull in all (enembullets) do
		move(enembull)
		animate(enembull)		
		del_outside_screen(enembull,enembullets)
	end
	
	--moving enemies
	for enemy in all(enemies) do
	 execute_behavior(enemy)
		
		animate(enemy)
		
		--leaving screen
		if enemy.behavior!="flyin" then
			del_outside_screen(enemy,enemies)
		end
	end
	
	--collision enemies x bullets
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
	
	--collision 
	-- enemy bullets x bullets
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
	
	--collision ship x enemies
	if ship.invul==0 then
		for enemy in all(enemies) do
			if collision(enemy,ship) then			
				ship_hit()
			end
		end
	else 
		ship.invul-=1
	end
	
	--collision ship x pickups
	for pickup in all(pickups) do
		if collision(pickup,ship) then			
			decide_pickup(pickup)
			del(pickups,pickup)
		end
	end
	
	--collision ship x enemy bullets
	if ship.invul==0 then
		for enembull in all(enembullets) do
			if collision(enembull,ship) then			
				ship_hit()
			end
		end
	end
	
	if ship.lives.curr<=0 then
		mode="over"
		btnlockout=t+30
		music(6)
		return
	end
	
	pick_timer()
	
	--animate flame
	flamespr=flamespr+1
	if flamespr>9 then
		flamespr=5
	end
	
	--animate muzzle flash
	if muzzle>0 then
		muzzle-=1
	end
	
	--check if waves is over
	if mode=="game" and #enemies==0 then
		enembullets={}
		next_wave()
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

function ship_hit()
	explode(ship.x+4,ship.y+4,true)
	ship.lives.curr-=1
	shake=8
	flash=3
	sfx(1)
	ship.invul=60
end

function update_start()
	if btn(4)==false and btn(5)==false then
		btnreleased=true
	end

	if btnreleased then
		if btnp(4) or btnp(5) then
			start_game()
			btnreleased=false
		end
	end
end

function update_over()
	if btn(4)==false and btn(5)==false then
		btnreleased=true
	end

	if btnreleased then
		if btnp(4) or btnp(5) then
			if score>highscore then
				highscore=score
				dset(0,score)
			end
			start_screen()
			btnreleased=false
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
		if btnp(4) or btnp(5) then
			if score>highscore then
				highscore=score
				dset(0,score)
			end
			start_screen()
			btnreleased=false
		end
	end
end

function update_wavetext()
	update_game()
	wavetime-=1
	if wavetime<=0 then
		mode="game"
		spawn_wave()
	end
end

function handle_ship_controls()
	ship.spr=2
	ship.spx=0
	ship.spy=0
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
	end
	if btn(3) then
		ship.spy=2
	end
	
	if btnp(4) then
		if energy>0 then
			energybomb()
			energy=0
		else
			sfx(32)
		end
	end
	
	-- need to press btn
	-- each time to fire
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
	
	--moving the ship
	ship.x+=ship.spx
	ship.y+=ship.spy
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
	
	--ship
	if ship.lives.curr>0 then
		if ship.invul<=0 then
			draw_spr(ship)
			spr(flamespr,ship.x,ship.y+8)	
		else
			--invul state
			if sin(t/5)<0.1 then
				draw_spr(ship)
				spr(flamespr,ship.x,ship.y+8)
			end
		end
	end
	
	--bullets
	for bull in all(bullets) do
		draw_spr(bull)
	end
	
	--pickups
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
	
	--enemies
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
	
	if muzzle>0 then
		circfill(ship.x+3,ship.y-1,
			muzzle,7)
		circfill(ship.x+4,ship.y-1,
			muzzle,7)
	end
	
	--particles
	for part in all(particles) do
		local pc=7
		
		if part.blue then
			pc=part_col_blue(part.age)
		else
			pc=part_col_red(part.age)
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
	
	--shockwaves
	for shock in all(shockwaves) do
		circ(shock.x+4,shock.y+4,
			shock.r,shock.col)
		shock.r+=shock.spd
		if shock.r>shock.maxr then
			del(shockwaves,shock)
		end
	end
	
	--enemy bullets
	for enembull in all(enembullets) do
		draw_spr(enembull)
	end
		
	for i=1,ship.lives.max do 
		if ship.lives.curr>=i then
			spr(heartspr,i*9,1)
		else
			spr(emptyheartspr,i*9,1)
		end
	end
	
	--floats
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
	
	print("score: "..make_score(score),
		50,2,12)
	spr(48,110,0)
	print(energy,120,1,14)
		
end

function make_score(val)
	if val==0 then
		return "0"
	end
	return val.."00"
end

function draw_start()
	cls(1)
	cprint("pico schmup",64,45,12)
	if highscore>0 then
		cprint("high score:",64,63,12)
		cprint(make_score(highscore),
			64,69,12)
	end

	cprint("press any key to start",
		64,90,blink())
end

function draw_over()
	draw_game()
	cprint("game over",64,40,8)
	draw_score_section()
end

function draw_win()
	draw_game()
	cprint("congratulations",
		64,40,2)
	draw_score_section()
end

function draw_wavetext()
	draw_game()
	if wave==lastwave then
		cprint("final wave!"..wave .." of "
		.. lastwave,64,40,blink())
	else
		cprint("wave "..wave .." of "
		.. lastwave,64,40,blink())
	end
end

function draw_score_section()
	cprint("score: "..make_score(score),
		64,60,12)
	if score>highscore then
		local col=7
		if t%4<2 then
			col=10
		end
		cprint("new highscore!",
			64,66,col)
	end
	
	cprint("press any key to continue",
		64,90,blink())
end

function draw_starfield()	
	for star in all(stars) do		
		local starcol=6

		if star.spd<1 then
			starcol=1
		elseif star.spd<1.5 then
			starcol=13
		end
		
		pset(star.x,star.y,starcol)
	end
end

function animate_starfield()
	for star in all(stars) do		
		star.y+=star.spd
		if star.y>128 then
			star.y-=128
		end	
	end
end
-->8
--tools

--centered horizontally text
function cprint(txt,x,y,col)
	print(txt,x-#txt*2,y,col)
end

function blink()
	local blinkanim={5,5,6,6,7,7,6,
		6,5,5}
	
	if blinkt>#blinkanim then
		blinkt=1
	end
	
	return blinkanim[blinkt]
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
		obj.y+=(obj.posy-obj.y)/n
		obj.x+=(obj.posx-obj.x)/n
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
	
	if wave>lastwave then
		mode="win"
		btnlockout=t+30
		music(4)
	else
	 if wave==1 then
   music(0)
  else
   music(3)  
  end
  
		mode="wavetext"
		wavetime=80
	end
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
		enemy.anim={21,22,23,24}
		enemy.score=1
	elseif type==2 then
		enemy.spr=148
		enemy.hp=2
		enemy.anim={148,149}
		enemy.score=2
	elseif type==3 then
		enemy.spr=184
		enemy.hp=4
		enemy.anim={184,185,186,187}
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
		enemy.hp=200
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
		-- do nothing
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
			aimedfire(enemy,2)
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
		debug="killed"
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
	pickup.spr=48
	add(pickups,pickup)
end

function decide_pickup(pickup)
	energy+=1
	shockwave(pickup.x,pickup.y,false)
	
	if energy>=10 then
		if ship.lives.curr<ship.lives.max then
			ship.lives.curr+=1
			sfx(31)
			energy=0
			pop_float("1up!",pickup.x,
				pickup.y)
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

function aimedfire(enemy,spd)
	local enemybull=fire(enemy,0,spd)
	
	--angle between two points
	local ang=atan2((ship.y+4)-enemybull.y,
		(ship.x+4)-enemybull.x)
	
	enemybull.spx=sin(ang)*spd
	enemybull.spy=cos(ang)*spd
end

function energybomb()
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
		aimedfire(boss,spd)
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
			enemy.x+16,enemy.y+12)
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
__gfx__
00000000000330000003300000033000000000000000000000000000000000000000000000000000000000000000000008800880088008800000000000000000
000000000036630000366300003663000000000000077000000770000007700000c77c0000077000000000000000000088888888800880080000000000000000
00700700003bb300003bb300003bb3000000000000c77c000007700000c77c0001cccc1000c77c00000000000000000088888888800000080000000000000000
00077000036bb630036bb630036bb63000000000001cc100000cc000001cc10000111100001cc100000000000000000088888888800000080000000000000000
00077000037cbb3036b7cb6303bb7c300000000000011000000cc000000110000000000000011000000000000000000008888880080000800000000000000000
007007000311bb303bb11bb303bb1130000000000000000000011000000000000000000000000000000000000000000000888800008008000000000000000000
00000000035563303b6556b303365530000000000000000000000000000000000000000000000000000000000000000000088000000880000000000000000000
00000000006996000369963000699600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900009999000000000000000000000000000330033003300330033003300330033000000000000000000000000000000000000000000000000000000000
0997799009aaaa9000000000000000000000000033b33b3333b33b3333b33b3333b33b3300000000000000000000000000000000000000000000000000000000
09a77a909aa77aa90000000000000000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb300000000000000000000000000000000000000000000000000000000
09a77a909a7777a90000000000000000000000003b7717b33b7717b33b7717b33b7717b300000000000000000000000000000000000000000000000000000000
09a77a909a7777a90000000000000000000000000b7117b00b7117b00b7117b00b7117b000000000000000000000000000000000000000000000000000000000
09aaaa909aa77aa90000000000000000000000000037730000377300003773000037730000000000000000000000000000000000000000000000000000000000
009aa90009aaaa900000000000000000000000000303303003033030030330300303303000000000000000000000000000000000000000000000000000000000
00099000009999000000000000000000000000000300003030000003030000300330033000000000000000000000000000000000000000000000000000000000
00ee000000ee00000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e22e0000e88e00007cc700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2e82e00e87e8e007c77c70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2882e00e8ee8e007c77c70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e22e0000e88e00007cc700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ee000000ee00000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00079000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00779900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07779990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77779999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99994444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09994440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00994400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00094000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000070000020000200200002002000020020000205555555555555555555555555555555502222220022222200222222002222220
000bb000000bb0000007700000077000022ff220022ff220022ff220022ff2200578875005788750d562465d0578875022e66e2222e66e2222e66e2222e66e22
0066660000666600606666066066660602ffff2002ffff2002ffff2002ffff2005624650d562465d05177150d562465d27761772277617722776177227716772
0566665065666656b566665bb566665b0077d7000077d700007d77000077d700d517715d051771500566865005177150261aa172216aa162261aa612261aa162
65637656b563765b056376500563765008577580085775800857758008577580056686500566865005d24d50056686502ee99ee22ee99ee22ee99ee22ee99ee2
b063360b006336000063360000633600080550800805508008055080080550805d5245d505d24d500505505005d24d5022299222229999222229922222299222
006336000063360000633600006336000c0000c007c007c007c00c7007c007c05005500505055050050000500505505020999902020000202099990202999920
0006600000066000000660000006600000c7c7000007c0000077cc000007c000dd0000dd0dd00dd005dddd500dd00dd022000022022002202200002202200220
00ff880000ff88000000000000000000200000020200002000000000000000003350053303500530000000000000000000000000000000000000000000000000
0888888008888880000000000000000022000022220000220000000000000000330dd033030dd030005005000350053000000000000000000000000000000000
06555560076665500000000000000000222222222222222200000000000000003b8dd8b3338dd833030dd030030dd03003e33e300e33e330033e333003e333e0
6566665576555565000000000000000028222282282222820000000000000000032dd2300b2dd2b0038dd830338dd833e33e33e333e33e333e33e333e33e333e
57655576555776550000000000000000288888822888888200000000000000003b3553b33b3553b3033dd3300b2dd2b033300333333003333330033333300333
0655766005765550000000000000000028788782287887820000000000000000333dd333333dd33303b55b303b3553b3e3e3333bbe33333ebe3e333be3e3333b
0057650000655700000000000000000028888882080000800000000000000000330550330305503003bddb30333dd3334bbbbeb44bbbebb44bbbbeb44bbbebe4
00065000000570000000000000000000080000800000000000000000000000000000000000000000003553000305503004444440044444400444444004444440
0066600000666000006660000068600000888000002222000022220000222200002222000cccccc00c0000c00000000000000000000000000000000000000000
055556000555560005585600058886000882880002eeee2002eeee2002eeee2002eeee20c0c0c0ccc000000c0000000000000000000000000000000000000000
55555560555855605588856058828860882228802ee77ee22ee77ee22eeeeee22ee77ee2c022220ccc2c2c0cc022220c00222200000000000000000000000000
55555550558885505882885088222880822222802ee77ee22ee77ee22ee77ee22ee77ee2cc2cac0cc02aa20cc0cac2ccc02aa20c000000000000000000000000
15555550155855501588855018828850882228802eeeeee22eeeeee22eeeeee22eeeeee2c02aa20cc0cac2ccc02aa20ccc2cac0c000000000000000000000000
01555500015555000158550001888500088288002222222222222222222222222222222200222200c022220ccc2c2c0cc022220c000000000000000000000000
0011100000111000001110000018100000888000202020200202020220202020020202020000000000000000c000000cc0c0c0cc000000000000000000000000
00000000000000000000000000000000000000002000200002000200002000200002000200000000000000000c0000c00cccccc0000000000000000000000000
000880000009900000089000000890000000000001111110011111100000000000d89d0000189100001891000019810000005500000050000005000000550000
706666050766665000676600006656000000000001cccc1001cccc10000000000d5115d000d515000011110000515d0000055000000550000005500000055000
1661c6610161661000666600001666000000000001cccc1001cccc1000000000d51aa15d0151a11000155100011a151005555550055555500555555005555550
7066660507666650006766000066560000000000017cc710017cc71000000000d51aa15d0d51a15000d55d00051a15d022222222222222222222222222222222
0076650000766500007665000076650000000000017cc710017cc710000000006d5005d6065005d0006dd6000d50056026060602260606022666666226060602
000750000007500000075000000750000000000001111110011111100000000066d00d60006d0d600066660006d0d60020000002206060622222222020606062
00075000000750000007500000075000000000001100001101100110000000000760067000660600000660000060660020606062222222200000000022222220
00060000000600000006000000060000000000001100001101100110000000000070070000070700000770000070700022222220000000000000000000000000
0007033000700000007d330003330333000000000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d3300000d33000028833003bb3bb3000000000888882000000000000000000000000000000000000000000000000000000000000000000000000000000000
0778827000288330071ffd1000884200002882000888882000288200000000000000000000000000000000000000000000000000000000000000000000000000
071ffd10077ffd700778827008ee8e800333e33308ee8e80088ee883000000000000000000000000000000000000000000000000000000000000000000000000
00288200071882100028820008ee8e8003bb4bb308ee8e8008eeee83000000000000000000000000000000000000000000000000000000000000000000000000
07d882d00028820007d882d00888882008eeee800088420008eeee80000000000000000000000000000000000000000000000000000000000000000000000000
0028820007d882d000dffd0008888820088ee88003bb3bb3088ee880000000000000000000000000000000000000000000000000000000000000000000000000
00dffd0000dffd000000000000222200002882000333033300288200000000000000000000000000000000000000000000000000000000000000000000000000
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

