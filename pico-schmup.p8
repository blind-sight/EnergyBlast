pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--main

function _init()
	cls(0)
	
	--sprites
	shipspr=2
	bullspr=16
	flamespr=5
	heartspr=12
	emptyheartspr=13
	
	mode="start"
	blinkt=0
	
end

-- (gameplay hard 30fps)
function _update()
	blinkt+=1

	if mode=="game" then
		update_game()
	elseif mode=="start" then
		update_start()
	elseif mode=="over" then
		update_over()
	end
	
end

-- (soft 30 fps)
function _draw()
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="over" then
		draw_over()
	end
	
end

function start_game()
	score=0
	mode="game"
	muzzle=0
	
	ship={x=64,y=64,spx=0,spy=0}
	lives={max=3,curr=2}
	stars={}	
	bullets={}
	
	for i=1,100 do
		local newstar={}
		newstar.x=flr(rnd(128))
		newstar.y=flr(rnd(128))
		newstar.spd=rnd(1.5)+0.5
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
		bull.y=bull.y-4
		
		if bull.y<-8 then
			del(bullets,bull)
		end
	end
	
	--animate flame
	flamespr=flamespr+1
	if flamespr>9 then
		flamespr=5
	end
	
	--animate muzzle flash
	if muzzle>0 then
		muzzle=muzzle-1
	end
	
	--checking edges
	if ship.x>120 then
		ship.x=0
		sfx(0)
	elseif ship.x<0 then
		ship.x=120
		sfx(0)
	end
	
end


function update_start()
	if btnp(4) or btnp(5) then
		start_game()
	end

end

function update_over()
	if btnp(4) or btnp(5) then
		mode="start"
	end

end


function handle_ship_controls()
	shipspr=2
	ship.spx=0
	ship.spy=0
	if btn(0) then
		ship.spx=-2
		shipspr=1
	elseif btn(1) then
		ship.spx=2
		shipspr=3
	elseif btn(2) then
		ship.spy=-2
	elseif btn(3) then
		ship.spy=2
	end
	
	-- need to press btn
	-- each time to fire
	if btnp(5) then
		local bullet={
			x=ship.x,
			y=ship.y-3
		}
		
		add(bullets,bullet)
		sfx(1)
		muzzle=5
	end
	
	--moving the ship
	ship.x=ship.x+ship.spx
	ship.y=ship.y+ship.spy
end
-->8
--draw

function draw_game()
	cls(0)
	
	--ship
	spr(shipspr,ship.x,ship.y)
	spr(flamespr,ship.x,ship.y+8)
	
	--bullet
	for i=1,#bullets do
		local bull=bullets[i]
		spr(bullspr,bull.x,bull.y)
	end
	
	if muzzle>0 then
		circfill(ship.x+3,ship.y-1,
			muzzle,7)
	end
	
	print("score: "..score, 40,1,12)
	for i=1,lives.max do 
		if lives.curr>=i then
			spr(heartspr,i*9,1)
		else
			spr(emptyheartspr,i*9,1)
		end
	end
	
	draw_starfield()
	animate_starfield()

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

function draw_starfield()	
	for i=1,#stars do
		local star=stars[i]
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
	for i=1,#stars do
		local star=stars[i]
		
		star.y=star.y+star.spd
		if star.y>128 then
			star.y=star.y-128
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
__gfx__
00000000000330000003300000033000000000000000000000000000000000000000000000000000000000000000000008800880088008800000000000000000
000000000036630000366300003663000000000000077000000770000007700000c77c0000077000000000000000000088888888800880080000000000000000
00700700003bb300003bb300003bb3000000000000c77c000007700000c77c0001cccc1000c77c00000000000000000088888888800000080000000000000000
00077000036bb630036bb630036bb63000000000001cc100000cc000001cc10000111100001cc100000000000000000088888888800000080000000000000000
00077000037cbb3036b7cb6303bb7c300000000000011000000cc000000110000000000000011000000000000000000008888880080000800000000000000000
007007000311bb303bb11bb303bb1130000000000000000000011000000000000000000000000000000000000000000000888800008008000000000000000000
00000000035563303b6556b303365530000000000000000000000000000000000000000000000000000000000000000000088000000880000000000000000000
00000000006996000369963000699600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09a77a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09a77a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001e7301d7401d760127601177012770207701e7701d7701977019770187701777017770167701677016770197601b7601e760207502375024740247402373022730207301f7301e7301d7301b73017730
0102000032550305502c55026550215501c5501855014550115500f5500c550095500855006550035500155000000000000000000000000000000000000000000000000000000000000000000000000000000000
