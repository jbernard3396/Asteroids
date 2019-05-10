pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
 sfx(3, 1)
 create_player()
 create_asteroids()
 create_bullets()
 create_score()
end

function _update()
	update(p)
 update(asteroids)
	update(bullets)
	update(score_obj)
end

function _draw()
 cls()
 draw(p)
 draw(asteroids)
 draw(bullets)
 draw(score_obj)
 --debug()
 
 
end
	
-->8
//main functions

function draw(obj)
	for func in all(obj.draw) do
	 func()
	end
end

function update(obj)
 for func in all(obj.update) do
  func()
 end
end

function restart()
 _init()
end

-->8
//player object
function create_player()
 p = {}
 p.dead = false
	p.x = 64
	p.y = 64
	p.turn = 0
	p.spd_x = 0
	p.spd_y = 0
	p.clr_1 = 7
	p.clr_2 = 8
	p.head_x = function ()
	 return p.x+sin(p.turn)*4
	end
	p.head_y = function()
	 return  p.y + cos(p.turn)*4
	end
	p.update = {}
	p.draw = {}
	add(p.draw, draw_player)
	add(p.update, move_player)
end

function draw_player()
 pset(p.head_x(), p.head_y(), p.clr_2)
 pset(p.x+sin(p.turn)*-3, p.y + cos(p.turn)*1, p.clr_1)
 pset(p.x+sin(p.turn)*1, p.y + cos(p.turn)*-3, p.clr_1)
end

function move_player()
 p.x += p.spd_x
 p.x = wrap(p.x)
 p.y += p.spd_y
 p.y = wrap(p.y)
 p.spd_x *= .99
 if p.dead then
  if btnp(3) then
   restart()
  end
  return 
 end
 check_player_dead()
 if btn(2) then
 	p.spd_x += .1*sin(p.turn)
 	p.spd_y += .1*cos(p.turn)
 end
 if btn(0) then
  p.turn -= 1/30
 end 
 if btn(1) then
  p.turn += 1/30
 end
 if btnp(5) or btnp(6) then
  bullets.create_bullet() 
 end
end

function check_player_dead()
 for r in all(asteroids.rocks) do
  if point_in_circle({x=p.head_x(), y=p.head_y()}, r) then
   shatter_player(r)
  end
 end
end

function shatter_player(r)
 sfx(2,3)
 p.head_x = function() 
  return r.x 
 end
 p.head_y = function()
  return r.y
 end
 p.dead = true
end

-->8
//bullet objects
function create_bullets()
 bullets = {}
 bullets.create_bullet = create_bullet
 bullets.draw = {}
 bullets.update = {}
 add(bullets.draw, draw_bullets)
 add(bullets.update, move_bullets)
end

function draw_bullets()
 for b in all(bullets) do
  pset(b.x, b.y, b.clr)
  pset(b.x+sin(b.turn), b.y+cos(b.turn), b.clr)
 end
end

function move_bullets()
 for b in all(bullets) do
  b.x += b.spd*sin(b.turn)
  b.x = wrap(b.x)
  b.y += b.spd*cos(b.turn)
  b.y = wrap(b.y)
  b.life -= 1  
  if (b.life <= 0) then
   del(bullets, b)
  end
  for r in all (asteroids.rocks) do
   if point_in_circle(b, r) then
    del(bullets, b)
    shatter_rock(r)
   end
  end
 end
end

function create_bullet()
 sfx(0,1)
 new_bullet = {}
 new_bullet.x = p.head_x()
 new_bullet.y = p.head_y()
 new_bullet.spd = 2.5
 new_bullet.turn = p.turn
 new_bullet.clr = 7
 new_bullet.life = 40
 add(bullets, new_bullet) 
end


-->8
//asteroid object
function create_asteroids()
 asteroids = {}
 asteroids.rocks = {}
 asteroids.wave = 0
 asteroids.update = {}
 asteroids.draw = {}
 add(asteroids.update, update_asteroids)
 add(asteroids.draw, draw_asteroids)
end

function draw_asteroids()
 for r in all(asteroids.rocks) do
  circ(r.x, r.y, r.size, r.clr)
 end
end

function update_asteroids()
 check_spawn_asteroids()
 for r in all(asteroids.rocks) do 
  r.x += r.spd*sin(r.turn)
  r.x = wrap(r.x)
  r.y += r.spd*cos(r.turn)
  r.y = wrap(r.y)
 end
end

function check_spawn_asteroids()
 if #asteroids.rocks == 0 then
  new_wave(asteroids.wave)
 end
end

function new_wave(wave)
 spawn_num = wave + 5
 for i=1, spawn_num do
  create_asteroid(false, false, false)
 end
end

function create_asteroid(x, y, size)
 new_asteroid = {}
 new_asteroid.x = x or pick({0,rand_int(0,128), rand_int(0,128), 128})
 if new_asteroid.x == 0 or new_asteroid.x == 128 then
  new_asteroid.y = y or rand_int(0,128)
 else 
  new_asteroid.y = y or pick({0, 128})
 end
 new_asteroid.size = size or rand_int(3, 10)
 new_asteroid.clr = 7
 new_asteroid.spd = rnd(1,2)
 new_asteroid.turn = rnd(1)
 add(asteroids.rocks, new_asteroid)
end

function shatter_rock(r)
 sfx(1, 2)
 increase_score(r.size)
 del(asteroids.rocks, r)
 if r.size > 4 then
  for i=1, pick({2, 3, 4}) do
   create_asteroid(r.x, r.y, r.size/2)
  end
 end
end
-->8
//score and effects
function create_score()
 score_obj = {}
 score_obj.x = 0
 score_obj.y = 0
 score_obj.score = 0
 score_obj.draw = {}
 score_obj.update = {}
 score_obj.clr1 = 7
 score_obj.clr2 = 11
 score_obj.clr = score_obj.clr1
 score_obj.last_update = 0
 add(score_obj.draw, draw_score)
 add(score_obj.update, update_score)
end

function draw_score()
 test = 'drawing score'
 print(score_obj.score, score_obj.x, score_obj.y, score_obj.clr)
end

function update_score()
 if score_obj.last_update >0 then
  score_obj.last_update -= 1
  if flr(mod(score_obj.last_update/4,2)) == 1 then
   score_obj.clr = score_obj.clr2
  else
   score_obj.clr = score_obj.clr1
  end
 end
end

function increase_score(num)
 score_obj.score+=flr(num)
 score_obj.last_update = flr(num)*2
end
-->8
//helpers
function wrap(int)
 if int > 128 then
  int = 0
 end
 if int < 0 then
  int = 128
 end
 return int
end

function pick(list)
 return list[rand_int(0, #list)]
end

function rand_int(lo,hi)
 return flr(rnd(hi-lo))+lo+1
end

function sqr(x)
 return x*x
end

function point_in_circle(blt, atd)
 return sqr(atd.x - blt.x)+sqr(atd.y-blt.y) <= sqr(atd.size)
end

function mod(x, y)
 while x > y do
  x -= y
 end
 return x
end
-->8
//debug

function debug()
 print(test, 120, 0)
 print(pick({1, 2}), 120, 10)
 print(flr(rnd(1,3)), 120, 20)
end
__sfx__
00010000000000000000000000001d0501f0502105024050260500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000000000000000000001a0501e0502105022050220502805028050280502805028050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000000000000000000000000000023050000001a05000000160500000000000110500b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007000000000000000000026050260501b0501b050150501505019050190501f0501f05025050250502d0502d050010002a0002a0502a0502d0502d0502d0002d0002d0002d0002d00000000000000000000000
