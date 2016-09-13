pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


--math
function range(v)
 return rnd(max(0,v[2]-v[1]))+v[1]
end

function lerp(from,to,t)
 return from+t*(to-from)
end

-- cubic in-out
function ease(t)
 if t >= 0.5 then
  return (t-1)*(2*t-2)*(2*t-2)+1
 else
  return 4*t*t*t
 end
end

function fract(v)
 return v-flr(abs(v))*sgn(v)
end

function v_add(a,b)
 return {a[1]+b[1],a[2]+b[2]}
end
function v_sub(a,b)
 return {a[1]-b[1],a[2]-b[2]}
end
function v_mul(v,s)
 return {v[1]*s,v[2]*s}
end
function v_div(v,s)
 if s != 0 then
  return {v[1]/s,v[2]/s}
 else
  return {0,0}
 end
end
function v_len2(v)
 return v[1]*v[1]+v[2]*v[2]
end
function v_len(v)
 return sqrt(v_len2(v))
end
function v_lenm(v)
 return abs(v[1])+abs(v[2])
end
function v_normalize(v)
 return v_div(v,v_len(v))
end
function v_lerp(a,b,t)
 return{lerp(a[1],b[1],t),lerp(a[2],b[2],t)}
end
function v_dist(a,b)
 return v_len(v_sub(a,b))
end
function v_distm(a,b)
 return v_lenm(v_sub(a,b))
end


function add_biome(
 colour,tree_range,bush_props,transition,footprints)
 local b={}
 b.tree_range=tree_range
 b.transition=transition
 b.bush_props = bush_props
 b.footprints=footprints[1]
 b.foot_sfx=footprints[2]
 b.building_freq=0
 
 biomes[colour]=b
end

function _init()
 srand(200) --for testing
 seed=rnd()
 palt(0,false)
 palt(14,true)
 
 shadow_offset=v_normalize({2,3})
 
 shadow_offset=v_mul(shadow_offset,0.2)
 
 perspective_offset={64,80}
 height_mult=0.015
 
 cells={}
 cells.w=32
 cells.h=32
 cells.fill_x=flr(128/cells.w+0.5)
 cells.fill_y=flr(128/cells.h+0.5)
 cells.bounds={128,64}
 cells.bound_str=2
 
 biomes={}
 --empty biomes
 for i=0,15 do
  add_biome(i,{0,0},{0,0,{}},false,{true,3})
 end
 add_biome(14,{0,0},{0,0,{}},true,{true,0})
 add_biome(1,{0,0},{0,0,{}},true,{false,1})
 add_biome(12,{0,0},{0,0,{}},false,{false,1})
 add_biome(3,{0.25,0.5},{0.5,05,{8,12,13,10}},true,{true,0})
 add_biome(4,{0,0},{0,0,{}},true,{true,3})
 add_biome(5,{0,0},{0,0,{}},false,{false,2})
 add_biome(6,{0,0},{0,0,{}},false,{false,2})
 add_biome(11,{0.1,0.3},{0.5,0.8,{8,12,13,10}},true,{true,0})
 add_biome(15,{0,0.2},{0.2,0.2,{11,13}},true,{true,3})
 
 add_biome(10,{0,0},{0,0,{}},true,{true,3})
 biomes[10].building_freq=0.8
 biomes[15].building_freq=0.01
 
 trees={}
 trees.height_range={10,25}
 trees.girth_range={4,10}
 trees.gap=16
 
 clouds={}
 clouds.a={}
 clouds.height_range={32,64}
 clouds.count_range={20,40}
 clouds.radius_range={5,15}
 clouds.cluster_range={5,7}
 clouds.w=256
 clouds.h=256
 
 
 bushes={}
 bushes.height_range={0.5,1.5}
 bushes.count_range={10,30}
 bushes.radius_range={1,2.5}
 bushes.cluster_range={2,4}
 
 buildings={}
 buildings.height_range={10,35}
 buildings.w_range={8,min(cells.w,cells.h)-16}
 buildings.h_range={8,min(cells.w,cells.h)-16}
 buildings.colours={8,9,6}
 
 --player
 p={}
 p.p={64,64}
 p.v={0,0}
 p.speed={0.7,0.7}
 p.max_speed=3
 p.cur_speed=0
 p.damping=0.8
 p.a=0
 p.a_o=0
 p.stride_w=4
 p.stride_l=12
 p.stride_alt=false
 p.height=4
 p.quack_timer=0
 
 p.r=4 
 -- camera
 cam={}
 cam.p=v_sub(p.p,{64,64})
 cam.c={0,0}
 cam.p_o=cam.p
 cam.offset={64,64}
 cam.sway={0.25,0.25,8,9}
 
 cells.current={
  flr(cam.p[1]/cells.w),
  flr(cam.p[2]/cells.h)
 }
 init_cells()
 
 
 
 footprints={
  {p.p[1],p.p[2]+p.stride_w,p.p[1],p.p[2]+p.stride_w},
  {p.p[1],p.p[2]-p.stride_w,p.p[1],p.p[2]-p.stride_w}
 }
 footprints.max=64
 footprints.remove_delay=0.25
 footprints.remove_last=time()
 for i=3,footprints.max-1,2 do
  footprints[i]=footprints[1]
  footprints[i+1]=footprints[2]
 end
 
 
 
 
 -- clouds init
 for i=1,range(clouds.count_range) do
  local x=rnd(clouds.w*2)
  local y=rnd(clouds.h*2)
  local r=0
  for j=1,range(clouds.cluster_range) do
   local c={}
   c.r=range(clouds.radius_range)
   c.p={
    x+range({1,(c.r+r)/2})-range({1,(c.r+r)/2}),
    y+range({1,(c.r+r)/2})-range({1,(c.r+r)/2})
   }
   if rnd() > 0.5 then
    x=c.p[1]
    y=c.p[2]
    r=c.r
   end
   c.height=range(clouds.height_range)
   c.s=c.p
   
   add(clouds.a,c)
  end
 end
 
 
 
 
 -- npc sprite
 npcs={
 	{who="dumb alien",spr=15,mouth=10,mouth_offset=-4},
 	{who="spooky ghost",spr=14,mouth=7,mouth_offset=0},
 	{who="giddy girl",spr=13,mouth=0,mouth_offset=2},
 	{who="hipster",spr=12,mouth=0,mouth_offset=0},
 	{who="thumbs up",spr=11,mouth=0,mouth_offset=0},
 	{who="swimmer",spr=10,mouth=0,mouth_offset=-4},
 	{who="bouncer",spr=9,mouth=0,mouth_offset=-4},
 	{who="pupper",spr=8,mouth=0,mouth_offset=0},
 	{who="?",spr=7,mouth=0,mouth_offset=0},
 	{who="blondie",spr=6,mouth=2,mouth_offset=0},
 	{who="buddy boy",spr=5,mouth=0,mouth_offset=2},
 	{who="ranger",spr=4,mouth=0,mouth_offset=0},
 	{who="scarf mcgee",spr=3,mouth=0,mouth_offset=0},
 	{who="duckling",spr=2,mouth=-1,mouth_offset=0},
 	{who="drake",spr=1,mouth=-1,mouth_offset=0},
 	{who="hen",spr=0,mouth=-1,mouth_offset=0}
 }
end

function init_cells()
 cells.a={}
 for a=0,cells.fill_x do
 cells.a[a]={}
 for b=0,cells.fill_y do
 local c={}
 cells.a[a][b]=c
 
 local x=a+cells.current[1]
 local y=b+cells.current[2]
 
 -- seed the rng based on cell position
 c.seed=seed+x*(cells.bounds[1]*2)+y
 srand(c.seed)
 
 c.c=sget(x,y+64)
 if x<0 or x>127 or y<0 or y>63 then
  c.c=14
 end
 c.biome=biomes[c.c]
 
 -- get colours for edge transition
 c.edges={}
 for u=-1,1 do
  c.edges[u]={}
 for v=-1,1 do
  c.edges[u][v]=sget(x+u,y+v+64)
  if x+u<0 or x+u>127 or y+v<0 or y+v>63 then
   c.edges[u][v]=14
  end
  if c.edges[u][v]==14 then
   c.edges[u][v]=3
  end
 end
 end
 
 
 c.trees={}
 local tree_freq=ease(range(c.biome.tree_range))
 
 c.bushes={}
 
 if c.c==14 then
  -- boundaries
  c.c=3
  local t={}
  t.height=range(trees.height_range)
  t.girth=min(cells.w,cells.h)*2/5
  t.p={
   cells.w/2,
   cells.h/2
  }
  t.s=t.p
   
  t.leaves={{0,0},{0,0},{0,0}}
  add(c.trees,t)
 else
  -- normal cell
  
  --trees
  for x=0,cells.w-trees.gap,trees.gap do
  for y=0,cells.h-trees.gap,trees.gap do
   if rnd() < tree_freq then
    local t={}
    t.height=range(trees.height_range)
    t.girth=range(trees.girth_range)
    t.p={
     x+rnd(trees.gap),
     y+rnd(trees.gap)
    }
    t.p[1]=mid(t.girth,t.p[1],cells.w-t.girth)
    t.p[2]=mid(t.girth,t.p[2],cells.h-t.girth)
    
    t.s=t.p
    t.leaves={{0,0},{0,0},{0,0}}
    add(c.trees,t)
   end
  end
  end
  
  --bushes
  if rnd() < c.biome.bush_props[1] then
   local x=rnd(cells.w)
   local y=rnd(cells.h)
   local r=0
   local bloom_colours=c.biome.bush_props[3]
   local colour=bloom_colours[flr(rnd(#bloom_colours))%#bloom_colours+1]
   for j=1,range(bushes.cluster_range) do
    local b={}
    b.r=range(bushes.radius_range)
    b.p={
     x+range({1,(b.r+r)})-range({1,(b.r+r)/2}),
     y+range({1,(b.r+r)})-range({1,(b.r+r)/2})
    }
    if rnd() > 0.5 then
     x=b.p[1]
     y=b.p[2]
     r=b.r
    end
    b.height=range(bushes.height_range)
    b.c=colour
    
    if rnd() < c.biome.bush_props[2] then
     local bloom={}
     local a=rnd()
     local r=rnd(b.r/2)+b.r/4
     bloom.p={
      r*cos(a),
      r*sin(a)
     }
     b.bloom = bloom
    else
     b.bloom=nil
    end
    b.s=b.p
   
    add(c.bushes,b)
   end
  end
 
  -- buildings
  if
   #c.bushes + #c.trees == 0 and
   rnd() < c.biome.building_freq
  then
   c.building={}
   c.building.size={
    range(buildings.w_range),
    range(buildings.h_range)
   }
   c.building.p={cells.w/2,cells.h/2}
   c.building.height=range(buildings.height_range)
   c.building.s=v_sub(c.building.p,p.p)
   c.building.c=buildings.colours[flr(rnd(16))%#buildings.colours+1]
  end
 
 end
 
 end
 end
end

function _update()
 
 if btnp(4) then
  sfx(5,2)
  p.quack_timer=10
 elseif btnp(5) then
  sfx(6,2)
  p.quack_timer=10
 end
 
 if p.quack_timer>0 then
  p.quack_timer-=1
 end
 
 perspective_offset[1]=64+sin(time()/9)*4
 perspective_offset[2]=80+sin(time()/11)*4
 
 local v_dif={0,0}
 if btn(0) then v_dif[1] -= p.speed[1] end
 if btn(1) then v_dif[1] += p.speed[1] end
 if btn(2) then v_dif[2] -= p.speed[2] end
 if btn(3) then v_dif[2] += p.speed[2] end
 
 if abs(v_dif[1])+abs(v_dif[2]) > 0.01 then
  p.v=v_add(p.v,v_dif)
  p.a_o=p.a
  p.a=atan2(p.v[1],p.v[2])
 end
 
 p.v=v_mul(p.v,p.damping)
 
 if abs(p.v[1]) < 0.01 then
  p.v[1]=0
 end
 if abs(p.v[2]) < 0.01 then
  p.v[2]=0
 end
 
 p.cur_speed=v_len(p.v)
 if p.cur_speed > p.max_speed then
  p.v=v_mul(p.v,p.max_speed/p.cur_speed)
  p.cur_speed=p.max_speed
 end
 
 p.p=v_add(p.p,p.v)
 
 -- camera
 cam.offset=v_add(v_mul(p.v,-15),{64,64})
 
 cam.p_o=cam.p
 local sway={
  cam.sway[1]*cos(time()/cam.sway[3]),
  cam.sway[2]*sin(time()/cam.sway[4])
 } 
 cam.p=v_add(
 v_lerp(cam.p,v_sub(p.p,cam.offset),0.1),
 sway
 )
 cam.v=v_sub(cam.p,cam.p_o)

 cam.c[1]=cam.p[1]%cells.w
 cam.c[2]=cam.p[2]%cells.h

 local cell={
 flr(cam.p[1]/cells.w),
 flr(cam.p[2]/cells.h)
 }
 if cell[1]!=cells.current[1] or cell[2]!=cells.current[2] then
  cells.current=cell
  init_cells()
 end
 
 
 blobs={}
 
 update_trees()
 update_clouds()
 update_bushes()
 update_buildings()
 update_collision()
 
 
 local pcell={
 flr(p.p[1]/cells.w),
 flr(p.p[2]/cells.h)
 }
 
 pcell=v_sub(pcell,cell)
 
 p.cell=cells.a[pcell[1]][pcell[2]]

 update_footprints()
end

function update_footprints()
 if
  btn(0) != btn(1) or
  btn(2) != btn(3)
 then
  if stat(16) != p.cell.biome.foot_sfx then
   sfx(p.cell.biome.foot_sfx,0)
  end
 else
  sfx(-1,0)
 end
 
 if p.cell.biome.footprints then
  -- footprints
  local fa=p.a
  if p.stride_alt then
   fa+=0.5
  end
  local fw=p.stride_w*(1-p.cur_speed/p.max_speed*0.8)*(1-abs(p.a-p.a_o))
  local fl=p.stride_l*(0.5+p.cur_speed/p.max_speed*0.5)
  local fp={
   p.p[1]+fw*cos(fa+0.25),
   p.p[2]+fw*sin(fa+0.25)
  }
  fp[3]=fp[1]-p.v[1]
  fp[4]=fp[2]-p.v[2]
  
  if v_distm(fp,footprints[footprints.max-1]) > fl then
   -- add footprints
   -- (actually just recycle existing ones)
   for i=1,footprints.max-1 do
    footprints[i]=footprints[i+1]
   end
   footprints[footprints.max]=fp
   p.stride_alt = not p.stride_alt
  end
 end
end


function update_collision()
 -- blobs
 for b in all(blobs) do
  local d=v_sub(p.p,b.p)
  local l2=v_len2(d)
  if l2 < b.r2 then
   b.hit=true
   p.v=v_add(p.v,v_div(d,sqrt(l2)))
  else
   b.hit=false
  end
 end
 
 -- boundaries
 local x=p.p[1]/cells.w
 local y=p.p[2]/cells.h
 if x > cells.bounds[1] then
  p.v[1] -= (x-cells.bounds[1])*cells.bound_str
 elseif x < 0 then
  p.v[1] -= x*cells.bound_str
 end
 
 if y > cells.bounds[2] then
  p.v[2] -= (y-cells.bounds[2])*cells.bound_str
 elseif y < 0 then
  p.v[2] -= y*cells.bound_str
 end
end

function update_trees()
 
 for x=0,cells.fill_x do
 for y=0,cells.fill_y do
 
 local ts=cells.a[x][y].trees
 
 local cellp = {
 cam.p[1]%cells.w-x*cells.w,
 cam.p[2]%cells.h-y*cells.h
 }
 
 for t in all(ts) do
  t.s=v_sub(t.p,v_add(cellp,perspective_offset))
  t.s=v_mul(t.s,t.height*height_mult)
  
  t.s=v_add(t.p,t.s)
  
  t.leaves[1]=v_lerp(t.p,t.s,0.5)
  t.leaves[2]=v_lerp(t.p,t.s,0.75)
  t.leaves[3]=t.s
  
  
  local blob={}
  blob.hit = false
  blob.p = v_add({(cells.current[1]+x)*cells.w,(cells.current[2]+y)*cells.h},t.p)
  blob.r = t.girth
  blob.r2=blob.r*blob.r
  add(blobs,blob)
 end
 
 end
 end
end

function update_clouds()
 for c in all(clouds.a) do
  c.p[1]+=0.1-cam.v[1]
  c.p[2]+=0.1-cam.v[2]
  
  if c.p[1] > clouds.w+clouds.radius_range[2] then
   c.p[1] -= clouds.w*2+clouds.radius_range[2]
  elseif c.p[1] < -clouds.w-clouds.radius_range[2] then
   c.p[1] += clouds.w*2+clouds.radius_range[2]
  end
  if c.p[2] > clouds.h+clouds.radius_range[2] then
   c.p[2] -= clouds.h*2+clouds.radius_range[2]
  elseif c.p[2] < -clouds.h-clouds.radius_range[2] then
   c.p[2] += clouds.h*2+clouds.radius_range[2]
  end
  
   
  
  c.s=v_sub(c.p,perspective_offset)
  c.s=v_mul(c.s,c.height*height_mult)
  c.s=v_add(c.p,c.s)
  
  c.ps=v_add(c.p,v_mul(shadow_offset,c.height))
 end
end

function update_bushes()
 for x=0,cells.fill_x do
 for y=0,cells.fill_y do
 
 local bs=cells.a[x][y].bushes
 
 local cellp = {
  cam.p[1]%cells.w-x*cells.w,
  cam.p[2]%cells.h-y*cells.h
 }
 
 for b in all(bs) do
  b.s=v_sub(b.p,v_add(cellp,perspective_offset))
  b.s=v_mul(b.s,b.height*height_mult)
  
  b.s=v_add(b.p,b.s)
 end
 
 end
 end
end


function update_buildings()
 for x=0,cells.fill_x do
 for y=0,cells.fill_y do
 
 local b=cells.a[x][y].building
 
 if b then
  local cellp = {
   cam.p[1]%cells.w-x*cells.w,
   cam.p[2]%cells.h-y*cells.h
  }
  b.s=v_sub(b.p,v_add(cellp,perspective_offset))
  
  local s1=max(b.size[1],b.size[2])
  local s2=min(b.size[1],b.size[2])
  for i=-s1+s2/2,s1-s2/2,s2 do
   local blob={}
   blob.hit = false
   blob.p = v_add({(cells.current[1]+x)*cells.w,(cells.current[2]+y)*cells.h},b.p)
   if s1==b.size[1] then
    blob.p[1]+=i
   else
    blob.p[2]+=i
   end
   blob.r = s2
   blob.r2=blob.r*blob.r
   add(blobs,blob)
  end
  local blob={}
  blob.hit = false
  blob.p = v_add({(cells.current[1]+x)*cells.w,(cells.current[2]+y)*cells.h},b.p)
  if s1==b.size[1] then
   blob.p[1]+=s1-s2/2
  else
   blob.p[2]+=s1-s2/2
  end
  blob.r = s2
  blob.r2=blob.r*blob.r
  if v_dist(blob.p,blobs[#blobs].p)>2 then
   add(blobs,blob)
  end
 end
 
 end
 end
end



function _draw()
 draw_bg()
 
 camera(cam.p[1],cam.p[2])
 
 draw_footprints()
 
 draw_bushes(true)
 draw_player(true)
 draw_trees(true)
 draw_buildings(true)
 draw_clouds(true) 
 
 draw_bushes(false)
 draw_player(false)
 draw_trees(false)
 draw_buildings(false)
 draw_clouds(false)
 
 --draw_debug()
 
 draw_title()
 draw_duckface()
 draw_npcface()
 
 
 
 draw_dialog()
 
end

function draw_bg()
 camera(cam.p[1],cam.p[2])
 
 for a=0,cells.fill_x do
 for b=0,cells.fill_y do
 
 x=(cells.current[1]+a)*cells.w
 y=(cells.current[2]+b)*cells.h
 
 local cell=cells.a[a][b]
 
 rectfill(x,y,x+cells.w,y+cells.h,cell.c)
 
 if cell.biome.transition then
 srand(cell.seed)
 
 local c=cell.edges[1][0]
 if c!=cell.c then
  pal(7,c)
  for v=0,cells.h/8 do
   spr(4+flr(rnd(4))*16,x+cells.w-8, y+v*8)
  end
 end
 c=cell.edges[-1][0]
 if c!=cell.c then
  pal(7,c)
  for v=0,cells.h/8 do
   spr(3+flr(rnd(4))*16,x, y+v*8)
  end
 end
 c=cell.edges[0][-1]
 if c!=cell.c then
  pal(7,c)
  for u=0,cells.w/8 do
   spr(2+flr(rnd(4))*16,x+u*8, y)
  end
 end
 c=cell.edges[0][1]
 if c!=cell.c then
  pal(7,c)
  for u=0,cells.w/8 do
   spr(1+flr(rnd(4))*16,x+u*8, y+cells.h-8)
  end
 end
 
 end
 end
 
 pal(7,7)
 end
 
end

function draw_footprints()
 color(5)
 for f=2,#footprints,2 do
  local f1=footprints[f-1]
  local f2=footprints[f]
  
  line(f1[1],f1[2],f1[3],f1[4])
  line(f2[1],f2[2],f2[3],f2[4])
  
  circfill(f1[1],f1[2],1)
  circfill(f2[1],f2[2],1)
 end
end

function draw_player(shadow)
 camera(cam.p[1],cam.p[2])
 
 if shadow then
  circfill(
  p.p[1]+shadow_offset[1]*p.height,
  p.p[2]+shadow_offset[2]*p.height,
  p.r,5)
 else
  local s=p.cur_speed/p.max_speed*p.r/5+0.5
  local p1={p.p[1],p.p[2]}
  local p2={
   p1[1]+p.height*cos(p.a)*s,
   p1[2]+p.height*sin(p.a)*s
  }
  
  circfill(p1[1],p1[2],p.r*3/4,4)
  circfill(p2[1],p2[2],p.r/2,10)
  p2=v_lerp(p1,p2,0.75)
  circfill(p2[1],p2[2],p.r/2,3)
  p2=v_lerp(p1,p2,0.5)
  pset(p2[1],p2[2],0)
  end
end

function draw_trees(shadows)
 for a=0,cells.fill_x do
 for b=0,cells.fill_y do
 
 local trees=cells.a[a][b].trees
 camera(
  cam.c[1]-a*cells.w,
  cam.c[2]-b*cells.h
 )
 
 if shadows then
 -- shadows
 color(5)
 for t in all(trees) do
  circfill(
  t.p[1]+shadow_offset[1]*t.height/2,
  t.p[2]+shadow_offset[2]*t.height/2,
  t.girth)
 end
 else
 -- trunks
 color(4)
 for t in all(trees) do
  for x=-1,1 do
  for y=-1,1 do
  if abs(x)+abs(y)!=2 then
   line(t.p[1]+x,t.p[2]+y,t.s[1],t.s[2])
  end
  end
  end
 end
 -- leaves
 c={{3,1},{11,0.7},{7,0.4}}
 for i=1,3 do
 color(c[i][1])
 for t in all(trees) do
  circfill(t.leaves[i][1],t.leaves[i][2],t.girth*c[i][2])
 end
 end
 
 end
 
 end
 end
end

function draw_buildings(shadows) 
 for x=0,cells.fill_x do
 for y=0,cells.fill_y do
 
 local b=cells.a[x][y].building
 
 if b then
 
 camera(
  cam.c[1]-x*cells.w,
  cam.c[2]-y*cells.h
 )
 
 if shadows then
 color(5)
 for i=0,b.height/2,4 do
  local t={b.s[1],b.s[2]}
  t=v_mul(t,i*height_mult)
  t=v_add(b.p,t)
  rectfill(t[1]-b.size[1],t[2]-b.size[2],t[1]+b.size[1],t[2]+b.size[2])
 end
 else
  color(5)
  for i=b.height/2,b.height-1,4 do
   local t={b.s[1],b.s[2]}
   t=v_mul(t,i*height_mult)
   t=v_add(b.p,t)
   rectfill(t[1]-b.size[1],t[2]-b.size[2],t[1]+b.size[1],t[2]+b.size[2])
  end
 
  local s=v_mul(b.s,b.height*height_mult)
  s=v_add(b.p,s)
  rectfill(s[1]-b.size[1],s[2]-b.size[2],s[1]+b.size[1],s[2]+b.size[2],b.c)
 end
 end
 
 end
 end
end

function draw_clouds(shadows)
 camera(0,0)
 if shadows then
  color(5)
  for c in all(clouds.a) do
   circfill(c.ps[1],c.ps[2],c.r)
  end
 else
  color(7)
  for c in all(clouds.a) do
   circfill(c.s[1],c.s[2],c.r)
  end
 end
end
 
function draw_bushes(shadows)
 for a=0,cells.fill_x do
 for b=0,cells.fill_y do
 
 local bushes=cells.a[a][b].bushes
 camera(
  cam.c[1]-a*cells.w,
  cam.c[2]-b*cells.h
 )
 
 if shadows then
  color(5)
  for b in all(bushes) do
   circfill(
   b.p[1]+shadow_offset[1]*b.height,
   b.p[2]+shadow_offset[2]*b.height,
   b.r)
  end
 else
  color(3)
  for b in all(bushes) do
   circfill(b.s[1],b.s[2],b.r)
  end
  for b in all(bushes) do
   if b.bloom!=nil then
    local p=v_add(b.s,b.bloom.p)
    pset(p[1],p[2],b.c)
   end
  end
 end
 
 end
 end
end


function draw_debug()
 --cells
 camera(cam.p[1],cam.p[2])
 for x=cells.current[1],cells.current[1]+cells.fill_x do
 for y=cells.current[2],cells.current[2]+cells.fill_y do
 
 local cell=cells.a[x-cells.current[1]][y-cells.current[2]]
 
 if x==cells.current[1] and y==cells.current[2] then
  color(10)
 elseif
  x>=cells.bounds[1] or
  y>=cells.bounds[2] or
  x<=-1 or
  y<=-1 then
  color(8)
 else
  color(6)
 end
 rect(
 x*cells.w+1,
 y*cells.h+1,
 (x+1)*cells.w-1,
 (y+1)*cells.h-1
 )
 print(x.." "..y,
 x*cells.w+3,
 y*cells.h+3)
 print("ts:"..#cell.trees,
 x*cells.w+3,
 y*cells.h+10)
 print("bs:"..#cell.bushes,
 x*cells.w+3,
 y*cells.h+17)
 end
 end
 
 
 for b in all(blobs) do
  if b.hit then
   color(8)
  else
   color(6)
  end
  circ(b.p[1],b.p[2],b.r)
 end
 
 color(6)
 circ(p.p[1],p.p[2],p.r)
 line(p.p[1],p.p[2],
 p.p[1]+p.r*cos(p.a),
 p.p[2]+p.r*sin(p.a))
 
 print_ol(p.cell.c,p.p[1]+3,p.p[2]+3,0,7)
 
 
 
 camera(0,0)
 
 print_ol("mem:"..stat(0)/1024,1,1,0,7)
 print_ol("cpu:"..stat(1),1,7,0,7)
 print_ol("pos:"..p.p[1].." "..p.p[2],1,22,0,7)

 --crosshair
 circ(64,64,1,0)
 
 
end


function draw_title()
 local t=time()
 local t2=t
 for i=0,3 do
  pal(0,(i+t2)%2+2)
  sspr(40+8*i,16,8,11,12+12*i,10+sin(t+i/3)*1.2,16,22)
 end
 for i=0,3 do
  pal(0,(i+t2+4)%2+2)
  sspr(40+8*i,16,8,11,9+12*(i+4)+8,10+sin(t+(i+1)/3)*1.2,16,22)
 end
 local s=" on the"
 for i=1,#s do
  pal(0,(i+t2)%2+2)
  print_ol(sub(s,i,i),64+(i-1)*4-#s*2+2,35+sin(t/2+i/#s)+2,5,5)
  print_ol(sub(s,i,i),64+(i-1)*4-#s*2,35+sin(t/2+i/#s),7,0)
 end
 
 for i=0,4 do
  pal(0,(i+t2)%2+2)
  sspr(72+8*i,16,8,11,9+12*(i+2),44+sin(t+(i+2)/3)*1.2,16,22)
 end
 pal(0,0)
end

function draw_duckface()
 local a=abs(sin(p.quack_timer/40))*5-abs(sin(time()/2))*3
 a=flr(a)
 sx=72
 if p.quack_timer > 0 then
  sx+=16
 end
 sspr(sx,0,16,16,0,128-32-a,32,32+a)
end

function draw_npcface()
 local a=abs(sin(p.quack_timer/40))*5-abs(sin(time()/2))*3
 a=flr(a)
 sx=0
 sy=32
 npc=npcs[15]
 sx+=npc.spr*16
 while(sx >= 128) do
  sx-=128
  sy+=16
 end
 sspr(sx,sy,16,16,128-32,128-32-a,32,32+a)
 
 -- npc mouth
 if npc.mouth >= 0 then
  pal(0,npc.mouth)
  sx=40
  if p.quack_timer > 0 and time()%0.2 > 0.1 then
   sx+=16
  end
  sspr(sx,0,16,16,128-32,128-32-a+npc.mouth_offset,32,32+a)
  pal(0,0)
 end
end

function draw_dialog()
 -- quack text
 if btn(4) then
  print_ol("Ž • quack •",35,127-16,0,7)
 else
  print_ol("Ž • quack •",35,127-16,7,0)
 end
 if btn(5) then
  print_ol("— – quack – ",35,127-8,0,7)
 else 
  print_ol("— – quack – ",35,127-8,7,0)
 end
end

function print_ol(s,x,y,c1,c2)
 color(c1)
 for u=x-1,x+1 do
 for v=y-1,y+1 do
  print(s,u,v)
 end
 end
 print(s,x,y,c2)
end
__gfx__
eeeeeeeeeeeeeeee77e777ee7e7eeeeeeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777eeeeeeeeee777777eeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeee7eee7eeeeeeeee7e7e7eeee7eee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77333377eeeeeeee77333377eeeeeeeeeeeeeeeeeeeeeeeeeee
ee7ee7eeeeeeeeeee77e7e777eeeee7eeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee73333337eeeeeeee73333337eeeeeeeeeeeeeeeeeeeeeeeeeee
eee77eeee7e7e7e7eeeeeeee7e7e7eeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee73333337eeeeeeee73333337eeeeeeeee444444eeeeeeeeeeee
eee77eeeeeeeeeee7e7e7e7e7eeeeeeeeee7e7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee73303307eeeeeeee73303307eeeeeeee44ffff44eeeeeeeeeee
ee7ee7ee77e7e77eeeeeeeeeee7e7eeee7eeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee73303307eeeeeeee73303307eeeeeeee4f0f0ff4eeeeeeeeeee
eeeeeeeeeeeeeeeee7eee7eeee7eee7eeee7e7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee73303307eeeeeeee7330330777eeeeeeff0f0fffeeeeeeeeeee
eeeeeeee77777e77eeeeeeee7eee7eeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee73333aa777eeeeee73333aaaa7eeeeeeff0f0fffeeeeeeeeeee
eeeeeeeeeeeeeeee77e777777eeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7333aaaaa7eeeeee7333aaa777eeeeeefffffffffeeeeeeeeee
eeeeeeeeeee7eeeeeeeeeeee7eee7eeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeee000eeeeeeeeeee7333333777eeeeee73330037eeeeeeeefffffffffeeeeeeeeee
eeeeeeeeeeeeeeeee7eee7ee7e7eeeeeeee7eeeeeeeeeee000eeeeeeeeeeeee000eeeeee7777773333337eee777777333aa377eeeeeeeff000fffeeeeeeeeeee
eeeeeeeee7eee7eeeeeeeeee7eeeee7eeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7444773333337eee7444773333aaa7eeeeeeeffffffffeeeeeeeeeee
eeeeeeeeeeeeeeeeee7eee7e7eeeeeeee7eeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444443333337eee44444433333377eeeeeeeeeffffeeeeeeeeeeeee
eeeeeeeeee7eee7eeeeeeeeeeeee7eeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44444443333477ee44444443333477eeeeeeee11ff11eeeeeeeeeeee
eeeeeeeeeeeeeeeeeeee7eee7e7eeeeeeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44444444444447ee44444444444447eeeeeeee111111eeeeeeeeeeee
eeeeeeee77777e77eeeeeeee7eeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44444444444447ee44444444444447eeeeeee111111eeeeeeeeeeee
eeeeeeeeeeeeeeee7ee7ee777eeeeeeeeeeee7e7777777ee7777777e7777777e7777777e7777eeeee77777eee77777eee777777e7777777eeeeeeeeeeeeeeeee
eeeeeeeeeeeeee7eeeeeeeeeee7eee7eeee7eee77000077e70077075770000757007707570075eee7700077e7700077e7700007570000075eeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee7ee7ee7eeeeeeeeeeeeeeee7007707570077075700777757007707570075eee70077075700770757007777570077775eeeeeeeeeeeeeeee
eeeeeeeee7e7eeeeeeeeeeee7eeeeeeeeee7e7ee7007707570077075700755557007077570075eee70077075700770757007555570075555eeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeee7e7eee7e7eeeeeeeeee7700770757007707570075eee7000775570075eee7007707570077075700777ee700777eeeeeeeeeeeeeeeeee
eeeeeeee7ee7ee7eeeeeeeeeeeeeeeeeeeeeeeee700770757007707570075eee7007077e70075eee70077075700770757700077e7000075eeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee7eeeeee7eee7eeee7eee7ee700770757007707570075eee7007707570075eee7007707570077075577700757007775eeeeeeeeeeeeeeeee
eeeeeeee77ee7ee7eeeeeeee7e7eeeeeeeeeeee770077075700770757007777e700770757007777e7007707570077075777700757007777eeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee77e77eeeeeee7eeee7eeee700007757700077577000075700770757000007577000775770007757000077570000075eeeeeeeeeeeeeeee
eeeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeee7e777777755e7777755e77777757777777577777775e7777755e77777557777775577777775eeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeee7e7eeeeeeeeeeeeee7e555555eee55555eee555555e5555555e5555555ee55555eee55555ee555555ee5555555eeeeeeeeeeeeeeee
eeeeeeee7eee7eeeeeeeeeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeee7eee7eeeeeeeeeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee7eeeeeeeeeeeeee7eeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee7eeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee77e77eeeeeeeeeeeeee7eeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee777777eeeeeeeeee777777eeeeeeeeeeeeeeeeeeeeeeeeeeee777777eeeeeeeee77777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777777eee
eee77444477eeeeeeee77333377eeeeeeeeeeeeeeeeeeeeeeeeeee755557eeeeeeee7773333777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee770000000777e
eee74444447eeeeeeee73333337eeeeeeeeeeeeeeeeeeeeeeeee7776666777eeeeee7333333337eeeeeeeeeeeeeeeeeeeeeee77777777eeeee77000000000077
eee74444447eeeeeeee73333337eeeeeeeeeeeee77777eeeeeee7555555557eee777755555555777eeeee77777777eeeeeee77aaaaaa777eee70000400000007
eee70440447eeeeeeee70330337eeeeeeeeeeee7799977eeeeee7724444227eee7333f66f66ff333eeee7744444477eeeeee7aafaaaaaa7eee70004444400007
eee70440447eeeeeeee70330337eeeeeeeeeeee7999997eeeeeee740404427eee7777ff0f0fff777eeee744ffff447eeeeee7af0faaaaa7eee70004040400007
eee70440447eeeeeeee70330337eeeeeeeeeeee7999997eeeeeee740404427eeeeee7ff0f0fff77eeeee74f0f0ff47eeeeee7af0f0fffa7eee70004040400007
e777aa44447eeeeee777aa33337eeeeeeeeeeee7090997eeeeeee740404427eeeeee7ff0f0ffff7eeeee7ff0f0fff7eeeeee7af0f0fffa77ee70004040440077
e7aaaaa4447eeeeee7aaaaa3337eeeeeeeeeeee7090997eeeeeee744444447eeeeee7fffffffff7eeeee7ff0f0fff77eeeee7ffffffffaa7ee7000444444047e
e7774444447eeeeee7773333337eeeeeeeeeee77aa9997eeeeeee744444447eeeeee7f66666ff77eeeee7fffffffff7eeeee7fffffffffa7ee7704444444047e
eee7444444777777eee7333333777777eeeeee7aaaa99777eeeee740004427eeeeee7760006f77eeeeee78ffff0f8f7eeeee7ff222ffffa7eee774400044407e
eee7444444775557eee7333333774447eeeeee7799999779eeeee744444477eeeeee777ffff777eeeeee7ff000fff77eeeee7ffffffffaa7eeee74444444407e
eee7444444555555eee7333333444444eeeeee7999999999eeeee77666677eeeeeee7739553377eeeeee77ffffff77eeeeee7aaffffaaaa7eeee77044440077e
ee77544445555555ee77433334444444eeeee77996699999eeeee75665557eeeeeee73339aa337eeeeee7777ff7777eeeeee7788ff88aa77eeeee766446677ee
ee75555555555555ee74444444444444eeeee79966669999eeeee75655557eeeeeee7f335933f7eeeeeee7ccffcc7eeeeee77f888888fa7eeeeee76666667eee
ee75555555555555ee74444444444444eeeee79666666999eeeee75555557eeeeeee7f335593f7eeeeeee7cccccc7eeeeee7ff888888ff7eeeeee72222227eee
eeee777eeeee777eeeeeeeeeeeeeeeeeeeeee77777777eeeeee777eeeeeeeeeeeeeee777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777eeeee
eeee7077eee7707eeeeeee777777eeeeeeee77dddddd77eeeee74777777777eeeeee77555555577eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777bb777eee
eeee74477777447eeeeee77ffff77eeeeeee7ddffffdd7eeeee744444444477eeeee75555555557eeee7777eee77777eeeeee77777777eeeeeee737bbbb37eee
eeee74444444467eeeee7744f44f77eeeeee7d11f11fd7eeeee774444444447eeeee7555ff55557eee77887777788877eeee77eeeeee77eeeeee773bbb377eee
eeee77404044667eeeee7ff040fff7eeeee771cc1cc1177eeeee77ffffff447eeeee75ffffff557ee778228888828887eeee7eeeeeeee7eeeeeee77abab7eeee
eeeee7404044677eeee77ff0f0fff77eeee71fccfccff17eeeeee744f44f447eeeee77f5f5ff557ee788288ffff82888eeee7ee7e7eee7eeeeeee77abab7eeee
eeeee740404447eeeee7ffffffffff7eeee7dfffffffff7eeeeee744f44f447eeeeee7f0f0ff557ee78878f0f0ff8788eeee7ee7e7eee7eeeeeee733bbb7eeee
ee777744444447eeeee7affffffffa7eeee7dfffffffff7eeeeee7f0f0ff447eeeeee7f0f0fff57ee7877ff0f0fff778eeee7ee7e7eee77eeeeee77bbbb7eeee
ee700666664447eeeee77ff000fff77eeee7dff000fffd7eeeeee7ffffff4f7eeeeee7fffffff77ee7777ff0f0fff777eeee7eeeeeeeee7eeeeeee7aaab7eeee
ee700666666447eeeeee77ff4fff77eeeee77ffffffff77eeeeee7ffff0fff7eeeeee7ffffff57eeeeee7fffffffff7eeeee7eeeeeeeee7eeeeeee7bbbb7eeee
ee7766600064477eeeeee77ffff77eeeeeee777ffff777eeeeeee7f000fff47eeeeee7f000ff77eeeeee79ffff0f9f7eeeee7ee777eee77eeeeee77bbbb77eee
eee7776666644477eeee7749ff9477eeeeee77a8ff8a77eeeeeee7fffffff77eeeeee7ffffff7eeeeeee7ff000fff77eeeee7eeeeeeee7eeeeeee7b7bb7b7eee
eeeee77466644447eeee7f499994f7eeeeee7f888888f7eeeeeee777ffff7777eeeee777ff777eeeeeee77ffffff77eeeeee777eeee777eeeeeee70700707eee
eee7774466644447eeee7ffaf9fff7eeeee77faaaaaaf77eeeee7711fff11117eeeee77555577eeeeeee7777ff7777eeeeeee7eeeeee7eeeeeeee70000007eee
e777474666664444eeee7ffaf9fff7eeee77998888889977eeee71111f111f11eeeee7dddddd7eeeeeeee7aaffaa7eeeeeeee7eeeeee7eeeeeeee77700777eee
e744474666664444eeee7749999477eeee7cccccccccccc7eeee71111111ff11eeeee7dddddd7eeeeeeee7aaaaaa7eeeeeeee7eeeeee7eeeeeeeeee7cc7eeeee
333bbb44411184444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
333bbb4441118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4
333bbb444111811111111111cccccccccccfffffffffffffffffffff44333e33334443333e33e333333444444fffffbbbbbffffffffbbbbbbcbbbb33333333e4
eeeaa6ffffff811111111111cc1111cccccffffffffffffffffffff444433333334444333333333e33444444fffffbbbfbbfffffffffbbfbbcbbb33bb33333e4
eeeaa6ffffff811111111111cc11111ccc4ffffffffffffffffffff44444333333344444333e33334444444fffffbbbbfbfffffffffffbbbbc3333bbbb3333e4
eee666ffaaaf8111111111111cc1111cc4fffffffffffffffffffff4444444333344444443333334444444fffffbbbbbffffaaf6aaafffbbcc3333bbbb3333e4
fffcccffafff81111111111111ccc1cccfffffffffffffffffffffff444444433444444444444444444433333ffbbbbbffff6666666ffffbc3333333333333e4
fffcccfaafff81111111111111ccccccfffffffffffffffffffffffff44444444444444444444ccccccc344433bbbbbbffff6aa6faaffffcc34443e3333333e4
fffcccffffff81111111111cccc1ccccccccccccccffffffffffffffff444444444444444444ccccccccccc443bbbbbfffff6666666666666664aa33333333e4
88888888888881111ccccccccccccccccccccccccccccccccccccccfffff44444444444444cccccccccccccc43bbbbbfffffff6aaa644fcc33444333e33333e4
4e11111111111111ccccccccccccccccccccccccccccccccccccccccccccff44444444ccccccccccc44ccccc43bbbbbfffff666666644fc334333333333333e4
4e111111111111cccccccccccfbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccc44bbcccc33bbbbbbff3bb44bb44bbfc334333333333333e4
4e1111111111cccccccccccfbbbffffffffffffffff4f4444cccccccccccccccccccccc4ffccccc33ebbbcccc3bbbbbbb33bb44bb44bbcc33333333333333fe4
4e111111111cccccccccbbbbbffffffffffffaffffffffffffffffffffbfffffffff44ffffcccc43bbbbcccccffbbbbb3f33fffffffffc33333333333e33ffe4
4e111111111cccccbbbbbbbbfaafafaaaaaaf6ffaaaaaaaafafffafffbbfffffffffffffffccc4433bbcccccffffbbbbbb33fffffffffc33333333333333ffe4
4e111111111cccffbbbbbbbbfa66666666666666666666666666666fbb333fffffffffffffcccc433cccccccbffffbbbb3bb3ffffffffc333343333e3333ffe4
4e111111111cccfffbfbbbbbfa6aaaaaaaaaa6aaaa6aafaa6fffaffbb33333fffffff333334cccc3ccccccccbb3333bbbbfbbfffffffccf333333333333fffe4
4ecc1111111cccfffbbbbbbbfa6aaaaaaaaaa6aaaa6aaffa6afffffb3333333fffff33333344cccccccccccb333b33bbbbbbbfffffffcffbb33333333bbfffe4
4ecccccc111ccccfffbbbbbbaa6aaaaebbeaa6aaaa6aaffa6afffbbb3333e33333ff333e33344ccccccccbb33bbb33bbbbbbbfffffffcfffb3333333bbbfffe4
4eccccccc11ccccffffbbbbfa6666aabccb666afaa6aaffa6ffffbb3333b333333334433333344443ffffb33bbbb333bbbbbbffffffccfffbb33333bbbbfffe4
4ecccccccc11cccfffffffffaa6aaaaebbeaa6afaa6aaffaafffbb3333bb33333334444b333333333ffff33bbbbb333bbbbfbffffffcfffffbbb33bbbfffffe4
4eccccccccccccccfffffffffa6aaaaaaaaaaaafaa6aaffffffbb333bbbb333334444bbbbbbbfffffffff3bbbbbe333bbbbbbffffffcffffffbbbbbbbbffffe4
4ecccccbccc1ccccbbfffffffa6affffaaaaaaafaa6aafffffbbbbbbbbb333333344bbbbbbbfffffffffb33bbbe3333bbbbbbfffffccffffffbbbbbbffffffe4
4eccccbbbcccccccbbbbfffffa6afaaaa66666afaa6aafffbbbbbbbbbb3333e33333bbfbbbffffffffbbbb33333333bbbbbbbfffffcfffffffffffffffffffe4
4ecbbb33bbccc1ccbbbbbbfffa6afa6aa6bbb6afaa6aaffbbb3333bbbb3333333333bbffbfffffffffbbbbb3333333bbbbbbbbfffccfffffffffffffffffffe4
4ebbb3333bccccccbbb4b44afa6aaa6aa6beb6afaa6aafbbbbb333bbbb333333333bbbfbffffffffffffbbfbbbbbbbbbbbbbbbfffcfffffffffffffffffff3e4
4eb333333bbcccccbbbb44666666666aa6bbb6aaaa6aabbbbbbbb33bbbbb333333bbbbbffffffffffffbbbbbbbbbbbbbb333bbffccfffffffffffffbbfff33e4
4eb33e333bbcccccbbbbb444aa6aaa6aa6666666666aabbbbbbbb33ebbbbbb3bbbbbbbbff3e3e3fffffbfbbbbbbbbbbb3333bbffcfffffffffffffbbbb3333e4
4eb333333bbfcccccbbbb4bffa6aaa6aaaaaaaaaaa6aa3bbbbbbbbbbbbbbbbbbbbbbfffffeaaaeffffbbbbbfbbbbbbb33333bbfccfffffffffffffbbb33333e4
4ebb3333bbffcccccbbbbbbffa6aaa6affffffffaa633333bbbbbbbbbbbbbbbbbbbbbffff3aea3ffffbbbffffbbbbb333333bbfcffffffffffffffbb333333e4
4e3bbbbbbbfffccccbbbfbbffa6aaaaaaaaaaaaaaa3333aaafbbbbbbbbbbbbbbffbffffffeaeaefffffffffffbbbb3333333bbccfffffffffffffff3333333e4
4ebbbbbebbbfffcccbbbfbbffa6aaaaaaaaaaaaab3e33aaaaaaaaaffbbbbbbbbbffffffff3aea3fbbbfffbbfbbbbb3333333bbcfffffffffffffff33333333e4
4ebb3bbbbbbffffcccbbbbffff666666666666633e3b66666666666fffbbbbbffffffffffeaeaefbbbffbbbbbbbbbb33e333bcc33ffffffffffff333333333e4
4ebbbbbbbbbffffccccbbbfffaaaff6aaaaaa6ab33baaaaaaa6aaffffbbbbffffffffffff3aea3fbbffffffbbbbbbb3333bbbc3333fffffffffff33333333ee4
4ebb333bbffffffccccbbffffffffa6affffa6a33a6aaafaaa6ffffbbbbbfffffffffffffeaaaeffffffffffffbbbbbbbbbbcc3333ffffffffff333bb333eee4
4eb3333fffffffffccccbfffffffffffffffa63e3a6affffaa6affbbbbbffffffffffffff3e3e3fffffffffffffffbbbbbbbc33333fffffffffb33bb3333eee4
4eb3e333ffffffffcccccffffffffffffffff3333a6afbffaa6affbbbbbfffffffffffffffffffffffffffffffffffbbbbbcc33333ffffffffb333bb333ee3e4
4eb3e333ffffffffbcccccc4ffffffffffffb333fa6afbbbba6afffffffffffffffffffffffffffffffff33333fffff3333c333e3fffffffffb333bb333eeee4
4ef3333fffffff33bbcccccc4ffffffffffb3333fa6afbbbbf6afaaaaaafaaafffffffffffffffffffff33333333333333cc33333ffffffff3333333333eeee4
4eff33ffffffff33bbcccccccffffffffffbb33bfa6afbbbba666666666666afffffffffffffffffff333333333333333cc333e333ffffffb3333333333eeee4
4efffffffffff3333bbccccccccfffffbbbbbbbbff6ffbbbff6aaaaafafafaaffffffffffffffffff333333333333333ccf333333ffffff3333b3333333ee3e4
4efffffffffff33333bbccccccccc44bbbbbbbbbfa6affbffa6ffffffffffffffffffffffffffff333333333ff333334c4ff3333ffffff33333bb33333333ee4
4efffffffff3333333bbbcccccccccccccc4bbbffaaaffbfffffffffffffffffffffffffffffff33333333ffffff444cc4fff33ffff33333333bbb33333e3ee4
4effffffff333e3333fbbbbcccccccccccccccccccccccccccccccfffffffffffffbbbffffbbb333333333fffff4cccc44fffffff3333333333beb3333333ee4
4efffffff333333333fbbbbbcccccccccccccccccccccccccccccccccccccccccccbbbbfffb333333e3333ffff4cccc4ffffffff33333333333bbb3333333ee4
4efffff3333333333ffbbbfbbbfcccccccccccccccccccccccccccccccccccccccccccc333333333333333fffcccc4ffffffff33333333333333b333333333e4
4effff3333333333ffbbbbbbbbffffccccccccccccccccccccccccccccccccccccccccccccc3333333333fcccccfffffffffff333333333333333333333333e4
4efff3333333333ffffbbbbfbbbbfbbbbb4b4444444bbfffffffccccccccccccccccccccccccccc33333ccccccccccccccccccccc333333333333333333333e4
4efff3333e3333fffffbbbbbbbbbffbbbbbbb44444bbbffffffffffffffccccccccccccccccccccccccccccccccccccccccccccccccccccc33333333333333e4
4effff33e3333fffffbbbbbbbbbbbbbbbbbbbbbbbbbbffffffffffffffffffffffffffcccccccccccccccccccccccccfff33333333ccccccccccccccccc333e4
4effff333333fffffbbbbbbbbbbbbbbbfbbbbbbbbbbffffffffffffffffffffffffffffffffffbbffffffffffffffffff3333333333333333333333333cccce4
4efffff3333ffffffbbb3333333bbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffffffbffffffffffffffffff333333333333333333333333333333e4
4e33fffffffffffffbbb333333333bbbbbbbbbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffff33333bb333333e33333333333333333e4
4e33ffffffffffffffbbbb333e333bbbbbbbbbbbfffffffffffffffffffffffffffffffff33333333ffffffffffff333333bbbb33333333333333333333333e4
4e333ffffffffffffffbbbb3333333bbbbbbbbb44ffffffbbfffffffffffffffffffff33333bb333333333fff33333333bbbbbbbb333333333333333333333e4
4e3333fffffffffffffbbbb33333333bbbbbbb44444ffffbbbfffffffffffffffffff33333bbbb333333333333333333bbbbb3333333333333333333333333e4
4e33333fffffffffffffbbb33333333bbbbbbb44444bbbbbfbbffffbbbbbbffffff33333333bbb3333333333333333333bb3333333333333333333333333eee4
4e33e333ffffffffffffbbb33333e333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffff333333e33333333333333333333333333333ee33333333333333333ee33ee4
4e3333333fffffbbfffffbbb333333333bbbbbbbbbbbbbbbbfbbbffbbb3bbbff333333333333333333333e33333333333333e3333e33333333333e3e3333eee4
4e33e333333333bbbfffffbbbbb3333e33bbb3bbbbbbbbbbbbbbbbffbbbbbb33333e3333333333333e33333333333333333eee333eee333333eeee333eeeeee4
4e333333333333333ffffffbbbbb3333333bbbbbbbbbbbbbbb3bbbbbbb3333333333333333333333333333333333333333ee333eeeee33eeeeeeeeeeeeeee3e4
4e3333333ee33e3333ffffffbbbbb333333bbb3bbb3bbbbbbbbbbbbbbb33333333333333333333333333333333333333eeeeeeee33eeeeee33eeeeee3eeeeee4
4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010300060561407611096110961508605046050160100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
0003000603514085110f5111951109515045050150100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
000300062a615136011b6010960108601046050160100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
000300060161405615076040760505604016050160100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100001117505171071710a1710e175122741827111271102711124114231232511d26124271292750000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000517505171071710a1710e175122741827111271102711124114231172511d26118271112750000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

