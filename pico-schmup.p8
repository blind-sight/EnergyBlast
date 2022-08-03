pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--main

function _init()
	cls(0)
	
	--sprites
	flamespr=5
	heartspr=12
	emptyheartspr=13
	
	start_screen()
	
	blinkt=0
	t=0 --number of frames
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
end

function start_screen()
	mode="start"
	music(1)
end

function start_game()
	music(-1,1000)
	score=0
	muzzle=0
	bulltimer=0
	wave=0
	nextwave()
	
	ship={
		x=64,
		y=64,
		spr=2,
		spx=0,
		spy=0
	}
	
	lives={max=3,curr=2}
	invul=0 --invulnerability
	stars={}	
	bullets={}
	enemies={}
	particles={}	
	shockwaves={}
		
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
	--count backwards to not cause
	--issues with removing bullets
	--from the same array
	for i=#bullets,1,-1 do
		local bull=bullets[i]
		bull.y-=4
		
		if bull.y<-8 then
			del(bullets,bull)
		end
	end
	
	--moving enemies
	for enemy in all(enemies) do
		enemy.y+=1
		enemy.spr+=0.4
		
		if enemy.spr>25 then
			enemy.spr=21
		end
		
		if enemy.y>128 then
			del(enemies, enemy)
		end
	end
	
	--collision enemies x bullets
	for enemy in all(enemies) do
		for bull in all(bullets) do
			if collision(enemy,bull) then
				del(bullets,bull)
				shockwave(bull.x,bull.y,false)
				spark(bull.x+4,bull.y+4,false)
				enemy.hp-=1
				sfx(4)
				enemy.flash=2
				
				if enemy.hp<=0 then
					del(enemies,enemy)
					sfx(3)
					score+=1
					explode(enemy.x+4,enemy.y+4)
				
					if #enemies==0 then
						nextwave()
					end
				end
			end
		end
	end
	
	--collision ship x enemies
	if invul==0 then
		for enemy in all(enemies) do
			if collision(enemy,ship) then			
				explode(ship.x+4,ship.y+4,true)
				lives.curr-=1
				sfx(2)
				invul=60
			end
		end
	else 
		invul-=1
	end
	
	if lives.curr<=0 then
		mode="over"
		music(6)
		return
	end
	
	--animate flame
	flamespr=flamespr+1
	if flamespr>9 then
		flamespr=5
	end
	
	--animate muzzle flash
	if muzzle>0 then
		muzzle-=1
	end
	
	--checking edges
	if ship.x>120 then
		ship.x=0
		sfx(0)
	elseif ship.x<0 then
		ship.x=120
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
			start_screen()
			btnreleased=false
		end
	end
end

function update_win()
	if btn(4)==false and btn(5)==false then
		btnreleased=true
	end

	if btnreleased then
		if btnp(4) or btnp(5) then
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
		spawnwave()
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
	
	-- need to press btn
	-- each time to fire
	if btn(5) then
		if bulltimer<=0 then
			local bullet={
				x=ship.x,
				y=ship.y-3,
				spr=16
			}
			
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
	cls(0)
	draw_starfield()
	animate_starfield()
	
	--ship
	if invul<=0 then
		drawspr(ship)
		spr(flamespr,ship.x,ship.y+8)	
	else
		--invul state
		if sin(t/5)<0.1 then
			drawspr(ship)
			spr(flamespr,ship.x,ship.y+8)
		end
	end
	
	--bullets
	for bull in all(bullets) do
		drawspr(bull)
	end
	
	--enemies
	for enemy in all(enemies) do
		if enemy.flash>0 then
			enemy.flash-=1
			replacecolors(7)
		end
		
		drawspr(enemy)
		pal() --reset color
	end
	
	if muzzle>0 then
		circfill(ship.x+3,ship.y-1,
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
	
	print("score: "..score, 40,1,12)
	
	for i=1,lives.max do 
		if lives.curr>=i then
			spr(heartspr,i*9,1)
		else
			spr(emptyheartspr,i*9,1)
		end
	end
end

function draw_start()
	cls(1)
	print("pico schmup",40,40,12)
	print("press any key to start",
		20,80,blink())
end

function draw_over()
	cls(8)
	print("game over",45,40,12)
	print("press any key to continue",
		15,80,blink())
end

function draw_win()
	cls(11)
	print("congratulations",40,
		40,2)
	print("press any key to continue",
		15,80,blink())
end

function draw_wavetext()
	draw_game()
	print("wave "..wave,56,40,blink())
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

function blink()
	local blinkanim={5,5,6,6,7,7,6,
		6,5,5}
	
	if blinkt>#blinkanim then
		blinkt=1
	end
	
	return blinkanim[blinkt]
end

function drawspr(obj)
		spr(obj.spr,obj.x,obj.y)
end

function collision(a,b)
	local a_left=a.x
	local a_top=a.y
	local a_right=a.x+7 --not 8
	local a_bottom=a.y+7
	
	local b_left=b.x
	local b_top=b.y
	local b_right=b.x+7
	local b_bottom=b.y+7
	
	if a_top>b_bottom then return false end
	if b_top>a_bottom then return false end
	if a_left>b_right then return false end
	if b_left>a_right then return false end
	
	return true
end

function replacecolors(color)
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
-->8
--waves and enemies

function spawnwave() 
	spawnenemy()
end

function nextwave()
	wave+=1
	
	if wave>1 then
		mode="win"
	else
		mode="wavetext"
		wavetime=80
	end
end

function spawnenemy()
	local enemy={
		x=rnd(120),
		y=-8,
		spr=21,
		hp=5,
		flash=0
	}
	add(enemies,enemy)
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
00999900000000000000000000000000000000000330033003300330033003300330033000000000000000000000000000000000000000000000000000000000
099aa9900000000000000000000000000000000033b33b3333b33b3333b33b3333b33b3300000000000000000000000000000000000000000000000000000000
99aaaa99000000000000000000000000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb300000000000000000000000000000000000000000000000000000000
9aa77aa9000000000000000000000000000000003b7717b33b7717b33b7717b33b7717b300000000000000000000000000000000000000000000000000000000
9aa77aa9000000000000000000000000000000000b7117b00b7117b00b7117b00b7117b000000000000000000000000000000000000000000000000000000000
99aaaa99000000000000000000000000000000000037730000377300003773000037730000000000000000000000000000000000000000000000000000000000
099aa990000000000000000000000000000000000303303003033030030330300303303000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000300003030000003030000300330033000000000000000000000000000000000000000000000000000000000
__sfx__
000100001e7301d7401d760127601177012770207701e7701d7701977019770187701777017770167701677016770197601b7601e760207502375024740247402373022730207301f7301e7301d7301b73017730
0002000032550305502c55026550215501c5501855014550115500f5500c550095500855006550035500155000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002c650346502f65027650216501b650156501365011650106500f6500b6500965008650056500365003650000000000000000000000000000000000000000000000000000000000000000000000000000
0001000034750096502f530206200f620085200552002720007100060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000e6102b620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050000010501605019050160501905001050160501905016050190601b0611b0611b061290001d0001700026000350002d000250001f0002900030000000000000000000000000000000000000000000000000
01050000205401d540205401d540205401d540205401d540225402255022550225502255000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001972020720227201b730207301973020740227401b7402074022740227402274000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f5501f5501b5501d5501d550205501f5501f5501b5501a5501b5501d5501f5501f5501b5501d5501d550205501f5501b5501a5501b5501d5501f5502755027550255502355023550225502055020550
011000000f5500f5500a5500f5501b530165501b5501b550165500f5500f5500a5500f5500f5500a550055500a5500e5500f5500f550165501b5501b550165501755017550125500f5500f550125501055010550
011000001e5501c5501c550175501e5501b550205501d550225501e55023550205501c55026550265500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000017550145501455010550175500b550195500d5501b5500f5501c550105500455016550165500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090d00001b0301b0001b0201d0201e0302003020040200401b7001d700227001a7001b7001b700227001b7001b7001d7001b7001b7001b7001d700227001a7001b7001b700167001b7001b7001b7001c7001c700
050d00001f5301f0001f52021520225302453024530245301e7001e70020700237002070022700227001670000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d000022030220002203024030250302703027030270301b0001b0001b0001d0001e00020000200002000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d1000002b0202b0202b0202b0202b0202b0202b0202b0202b020290202b0202c0202b0202b0202b0202602026020260202702027020270202b0202b0202b0202a0302a0302a0302703027030270302003020030
4d1000002003028030280302c0302a0302a0302a0302703027030270302c0302a030290302e0302e0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00001e050000001e0501d0501b0501a0601a0621a062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050f00001b540070001b5401a54018540175501755217562075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002b55030550305002e54027550225501d5501b550185501655016500165501655018550185501b5501d55022550275002b5302e5502b550295502752027500225501b5501b5501d550245502755028500
011000000a5530000000000000000a5530000000000000000a5530000000000000000a5530000000000000000a5530000000000000000a5530000000000000000a5530000000000000000a553000000000000000
__music__
04 05060744
00 08094749
04 0a0b484a
04 0c0d0e44
00 0f094344
04 100b4344
04 11124e44

