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
	
	shipx=64
	shipy=64
	
	--speed
	shipsx=0
	shipsy=0
	
		--bullet
	bullx=40
	bully=-10
	
	--muzzle
	muzzle=0
	
	maxlives=3
	lives=2
	
	--stars
	starx={}
	stary={}
	starspd={}
	for i=1,100 do
		add(starx,flr(rnd(128)))
		add(stary,flr(rnd(128)))
		add(starspd,rnd(1.5)+0.5)
	end
	
end
-->8
--update

function update_game()
	handle_ship_controls()
	
	--moving the bullet
	bully=bully-4
	
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
	if shipx>120 then
		shipx=0
		sfx(0)
	end
	if shipx<0 then
		shipx=120
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
	shipsx=0
	shipsy=0
	if btn(0) then
		shipsx=-2
		shipspr=1
	elseif btn(1) then
		shipsx=2
		shipspr=3
	elseif btn(2) then
		shipsy=-2
	elseif btn(3) then
		shipsy=2
	end
	
	-- need to press btn
	-- each time to fire
	if btnp(5) then
		bully=shipy-3
		bullx=shipx
		sfx(1)
		muzzle=5
	end
	
	--moving the ship
	shipx=shipx+shipsx
	shipy=shipy+shipsy
end
-->8
--draw

function draw_game()
	cls(0)
	
	--ship
	spr(shipspr,shipx,shipy)
	spr(flamespr,shipx,shipy+8)
	
	--bullet
	spr(bullspr,bullx,bully)
	if muzzle>0 then
		circfill(shipx+3,shipy-1,
			muzzle,7)
	end
	
	print("score: "..score, 40,1,12)
	for i=1,maxlives do 
		if lives>=i then
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
	for i=1,#starx do
		local starcol=6
		
		if starspd[i]<1 then
			starcol=1
		elseif starspd[i]<1.5 then
			starcol=13
		end
		
		pset(starx[i],stary[i],
			starcol)
	end
	
end

function animate_starfield()
	for i=1,#stary do
		local sy=stary[i]
		
		sy=sy+starspd[i]
		if sy>128 then
			sy=sy-128
		end
		
		stary[i]=sy
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
