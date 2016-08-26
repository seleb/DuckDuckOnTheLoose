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
function v_len(v)
 return sqrt(v[1]*v[1]+v[2]*v[2])
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
 --srand(10) --for testing
 seed=rnd()
 palt(0,0)
 palt(14,1)
 
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
 trees.girth_range={6,12}
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
  t.girth=min(cells.w,cells.h)/2
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
  local l=v_len(d)
  if l < b.r then
   b.hit=true
   p.v=v_add(p.v,v_div(d,l))
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
 color(3)
 for t in all(trees) do
  circfill(t.leaves[1][1],t.leaves[1][2],t.girth)
 end
 color(11)
 for t in all(trees) do
  circfill(t.leaves[2][1],t.leaves[2][2],t.girth*0.75)
 end
 color(7)
 for t in all(trees) do
  circfill(t.leaves[3][1],t.leaves[3][2],t.girth*0.5)  
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
eeeeeeeeeeeeeeee77e777ee7e7eeeeeeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeee7eee7eeeeeeeee7e7e7eeee7eee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee7ee7eeeeeeeeeee77e7e777eeeee7eeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee77eeee7e7e7e7eeeeeeee7e7e7eeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee77eeeeeeeeeee7e7e7e7e7eeeeeeeeee7e7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee330330eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee7ee7ee77e7e77eeeeeeeeeee7e7eeee7eeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee330330eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee7eee7eeee7eee7eeee7e7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee330330eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee77777e77eeeeeeee7eee7eeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3333aaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee77e777777eeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333aaaaaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee7eeeeeeeeeeee7eee7eeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee7eee7ee7e7eeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee7eee7eeeeeeeeee7eeeee7eeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444ee333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee7eee7e7eeeeeeee7eeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeee7eee7eeeeeeeeeeeee7eeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444433334eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeee7eee7e7eeeeeeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee77777e77eeeeeeee7eeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee7ee7ee777eeeeeeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeee7eeeeeeeeeee7eee7eeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee7ee7ee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee7e7eeeeeeeeeeee7eeeeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeee7e7eee7e7eeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee7ee7ee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee7eeeeee7eee7eeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee77ee7ee7eeeeeeee7e7eeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee77e77eeeeeee7eeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeee7e7eeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee7eee7eeeeeeeeeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeee7eee7eeeeeeeeeee7eee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee7eeeeeeeeeeeeee7eeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee7eeeeeee7e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee77e77eeeeeeeeeeeeee7eeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
333bbb44411184444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
333bbb4441118eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4
333bbb444111811111111111cccccccccccffffffffffffffffffffffffffffffffff33333333333333ffffffffffffffffffffffffffffffcffffffffffffe4
eeeaa6ffffff811111111111cc1111cccccfffffffffffffffffffffffffffffffffff333333333333fffffffffffffffffffffffffffffffcffffffffffffe4
eeeaa6ffffff811111111111cc11111cccffffffffffffffffffffffffffffffffffffff33333333fffffffffffffffffffffffffffffffffcffffffffffffe4
eee666ffaaaf8111111111111cc1111ccffffffffffffffffffffffffffffffffffffffff333333fffffffffffffffffffffffffffffffffccffffffffffffe4
fffcccffafff81111111111111ccc1cccfffffffffffffffffffffffffffffffffffffffffffffffffff33333fffffffffffffffffffffffcfffffffffffffe4
fffcccfaafff81111111111111ccccccfffffffffffffffffffffffffffffffffffffffffffffccccccc344433fffffffffffffffffffffccfffffffffffffe4
fffcccffffff81111111111cccc1ccccccccccccccffffffffffffffffffffffffffffffffffccccccccccc443fffffffffffffffffffffcffffffffffffffe4
88888888888881111ccccccccccccccccccccccccccccccccccccccfffffffffffffffffffcccccccccccccc43ffffffffffffffffffffccffffffffffffffe4
4e11111111111111ccccccccccccccccccccccccccccccccccccccccccccffffffffffccccccccccc44ccccc43ffffffffffffffffffffcfffffffffffffffe4
4e111111111111cccccccccccffffffffccccccccccccccccccccccccccccccccccccccccccccccc44bbcccc33ffffffffffffffffffffcfffffffffffffffe4
4e1111111111cccccccccccffffffffffffffffffffffffffccccccccccccccccccccccfffccccc33ebbbcccc3fffffffffffffffffffccfffffffffffffffe4
4e111111111cccccccccfffffffffffffffffaffffffffffffffffffffffffffffffffffffcccc43bbbbcccccffffffffffffffffffffcffffffffffffffffe4
4e111111111cccccfffffffffaafafaaaaaaf6ffaaaaaaaafafffaffffffffffffffffffffccc4433bbcccccfffffffffffffffffffffcffffffffffffffffe4
4e111111111cccfffffffffffa66666666666666666666666666666fffffffffffffffffffcccc433cccccccfffffffffffffffffffffcffffffffffffffffe4
4e111111111cccfffffffffffa6aaaaaaaaaa6aaaa6aafaa6fffafffffffffffffff3333334cccc3ccccccccff3333ffffffffffffffccffffffffffffffffe4
4ecc1111111cccfffffffffffa6aaaaaaaaaa6aaaa6aaffa6affffffffffffffffff33333344cccccccccccf333b33ffffffffffffffcfffffffffffffffffe4
4ecccccc111ccccfffffffffaa6aaaaebbeaa6aaaa6aaffa6affffffffffffffffff333333344ccccccccff33bbb33ffffffffffffffcfffffffffffffffffe4
4eccccccc11ccccfffffffffa6666aabccb666afaa6aaffa6fffffffffffffffffffff33333344443fffff33bbbb333ffffffffffffccfffffffffffffffffe4
4ecccccccc11cccfffffffffaa6aaaaebbeaa6afaa6aaffaafffffffffffffffffffffff333333333ffff33bbbbb333ffffffffffffcffffffffffffffffffe4
4eccccccccccccccfffffffffa6aaaaaaaaaaaafaa6aaffffffffffffffffffffffffffffffffffffffff3bbbbbb333ffffffffffffcffffffffffffffffffe4
4ecccccfccc1ccccfffffffffa6affffaaaaaaafaa6aaffffffffffffffffffffffffffffffffffffffff33bbbb3333fffffffffffccffffffffffffffffffe4
4eccccfffcccccccfffffffffa6afaaaa66666afaa6aafffffffffffffffffffffffffffffffffffffffff33333333ffffffffffffcfffffffffffffffffffe4
4ecfffffffccc1ccfffffffffa6afa6aa6bbb6afaa6aaffffffffffffffffffffffffffffffffffffffffff3333333fffffffffffccfffffffffffffffffffe4
4effffffffccccccfffffffafa6aaa6aa6beb6afaa6aaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcfffffffffffffffffff3e4
4efffffffffcccccffffff666666666aa6bbb6aaaa6aafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffccffffffffffffffffff33e4
4efffffffffcccccffffffffaa6aaa6aa6666666666aafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcfffffffffffffffff3333e4
4effffffffffcccccffffffffa6aaa6aaaaaaaaaaa6aaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffccffffffffffffffff33333e4
4effffffffffcccccffffffffa6aaa6affffffffaa6aaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcffffffffffffffff333333e4
4efffffffffffccccffffffffa6aaaaaaaaaaaaaaa6aaaaaafffffffffffffffffffffffffffffffffffffffffffffffffffffccfffffffffffffff3333333e4
4effffffffffffcccffffffffa6aaaaaaaaaaaaaaa6aaaaaaaaaaaffffffffffffffffffffffffffffffffffffffffffffffffcfffffffffffffff33333333e4
4efffffffffffffcccffffffff66666666666666666666666666666ffffffffffffffffffffffffffffffffffffffffffffffccffffffffffffff333333333e4
4efffffffffffffccccffffffaaaff6aaaaaa6aaaa6aaaaaaa6aaffffffffffffffffffffffffffffffffffffffffffffffffcfffffffffffffff33333333ee4
4efffffffffffffccccffffffffffa6affffa6affa6aaafaaa6fffffffffffffffffffffffffffffffffffffffffffffffffccffffffffffffff333bb333eee4
4effffffffffffffccccffffffffffffffffa6fffa6affffaa6affffffffffffffffffffffffffffffffffffffffffffffffcfffffffffffffff33bb3333eee4
4effffffffffffffcccccffffffffffffffffffffa6affffaa6afffffffffffffffffffffffffffffffffffffffffffffffccffffffffffffff333bb333eeee4
4efffffffffffffffccccccffffffffffffffffffa6afffffa6afffffffffffffffffffffffffffffffffffffffffffffffcfffffffffffffff333bb333eeee4
4effffffffffffffffccccccfffffffffffffffffa6affffff6afaaaaaafaaafffffffffffffffffffffffffffffffffffccfffffffffffff3333333333eeee4
4effffffffffffffffcccccccffffffffffffffffa6afffffa666666666666affffffffffffffffffffffffffffffffffccffffffffffffff3333333333eeee4
4efffffffffffffffffccccccccfffffffffffffff6fffffff6aaaaafafafaafffffffffffffffffffffffffffffffffccfffffffffffff3333b3333333eeee4
4effffffffffffffffffcccccccccffffffffffffa6afffffa6fffffffffffffffffffffffffffffffffffffffffffffcfffffffffffff33333bb333333eeee4
4efffffffffffffffffffccccccccccccccffffffaaafffffffffffffffffffffffffffffffffffffffffffffffffffccffffffffff33333333bbb33333eeee4
4efffffffffffffffffffffcccccccccccccccccccccccccccccccffffffffffffffffffffffffffffffffffffffccccfffffffff3333333333beb3333333ee4
4effffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccffffffffffffffffffffffffccccfffffffff33333333333bbb3333333ee4
4efffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccccccffffffffffffffffffccccfffffffff33333333333333b333333333e4
4effffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccfffffffffffcccccfffffffffff333333333333333333333333e4
4effffffffffffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccfffffccccccccccccccccccccc333333333333333333333e4
4efffffffffffffffffffffffffffffffffffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccccccccccccccc33333333333333e4
4effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccfff33333333ccccccccccccccccc333e4
4efffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3333333333333333333333333cccce4
4effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff333333333333333333333333333333e4
4e33fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333bb333333e33333333333333333e4
4e33fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333ffffffffffff333333bbbb33333333333333333333333e4
4e333fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333bb333333333fff33333333bbbbbbbb333333333333333333333e4
4e3333fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333bbbb333333333333333333bbbbb3333333333333333333333333e4
4e33333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333bbb3333333333333333333bb3333333333333333333333333eee4
4e333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff333333e33333333333333333333333333333ee33333333333333333eeeeee4
4e3333333fffffffffffffffffffffffffffffffffffffffffffffffffffffff333333333333333333333e33333333333333eeeeee33333333333eeeeeeeeee4
4e333333333333ffffffffffffffffffffffffffffffffffffffffffffffff3333333333333333333e33333333333333333eeeeeeeee333333eeeeeeeeeeeee4
4e333333333333333fffffffffffffffffffffffffffffffffffffffff3333333333333333333333333333333333333333eeeeeeeeeeeeeeeeeeeeeeeeeeeee4
4e3333333333333333ffffffffffffffffffffffffffffffffffffffff33333333333333333333333333333333333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4
4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0d0d0d0d0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0d0d0e0c0c0c0c0c0c0c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0d0d0d0d0f0c0e0e0e0e0e0c0c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0d0d0d0d0f0c0e0c0c0c0e0e0e0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0c0c0c000c0c0c0c0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

