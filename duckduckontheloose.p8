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
 cells.bounds={128,128}
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
 add_biome(7,{0,0.1},{0.1,0,{}},true,{true,3})
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
 p.p=v_mul({5,5},32)
 p.v={0,0}
 p.speed={0.7,0.7}
 p.max_speed=3
 p.cur_speed=0
 p.damping=0.8
 p.a=0.75
 p.a_o=0
 p.stride_w=4
 p.stride_l=12
 p.stride_alt=false
 p.height=4
 p.quack_timer=0
 p.c={0,0,0}
 p.duck=-1
 p.ducklings={}
 
 ducklings={}
 ducklings.height=3
 ducklings.r=2
 ducklings.found=0
 ducklings.found_timer=0
 
 add(ducklings,{
  p={10,10}
 })
 add(ducklings,{
  p={20,20}
 })
 add(ducklings,{
  p={30,30}
 })
 add(ducklings,{
  p={40,40}
 })
 add(ducklings,{
  p={50,50}
 })
 add(ducklings,{
  p={60,60}
 })
 add(ducklings,{
  p={70,70}
 })
 
 p.r=4 
 p.r2=p.r*p.r
 -- camera
 cam={}
 cam.p=v_sub(p.p,{64,64+128})
 cam.c={0,0}
 cam.p_o=cam.p
 cam.offset={64,64}
 cam.sway={0.25,0.25,8,9}
 
 cells.current={
  flr(cam.p[1]/cells.w),
  flr(cam.p[2]/cells.h)
 }
 
 
 
 
 -- read compressed map
 mapdata={}
 local x=cells.bounds[1]-1
 local y=-1
 for i=0x1000+64*16,0x2fff do
  x+=1
  if x==cells.bounds[1] then
   x=0
   y+=1
   if y==cells.bounds[2] then
    break
   end
   mapdata[y]={}
  end
  
  local h=peek(i)
  local a=band(peek(i),0x0f)
  local b=shr(band(peek(i),0xf0),4)
  printh(h..","..a..","..b)
  mapdata[y][x]=a
  
  x+=1
  if x==cells.bounds[1] then
   x=0
   y+=1
   if y==cells.bounds[2] then
    break
   end
   mapdata[y]={}
  end
  mapdata[y][x]=b
  
 end
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
 	{who="drake",spr=1,
 	mouth=-1,mouth_offset=0,
 	c1=4,c2=3,r=3,height=2,
 	lines="duck duck! we need your help!|we lost our babies!!!!!|we had eight before, but now we only have one!|i don't know what happened to the rest!|i'm staying here to keep track of the last one.|please find the other seven!|we're counting on you\nduck duck!|"},
 	{who="hen",spr=0,
 	mouth=-1,mouth_offset=0,
 	c1=6,c2=4,r=3,height=2,
 	lines="duck duck! you need to find our babies!|we lost them!!!!!|one's still here, but there are seven on the loose!|you've got to find them!|don't let us down duck duck!|"},
 	{who="duckling",spr=2,
 	mouth=-1,mouth_offset=0,
 	c1=9,c2=10,r=2,height=2,
 	lines="hi duck duck!|are you going to find my brothers and sisters?|they're hiding somewhere around here...|i'll let you know if i see them!|good luck duck duck!|"},
 	{who="dumb alien",spr=15,
 	mouth=10,mouth_offset=-4,
 	c1=0,c2=11,r=4,height=4},
 	{who="spooky ghost",spr=14,
 	mouth=7,mouth_offset=0,
 	c1=7,c2=7,r=3,height=4},
 	{who="giddy girl",spr=13,
 	mouth=0,mouth_offset=2,
 	c1=10,c2=8,r=3,height=2},
 	{who="hipster",spr=12,
 	mouth=0,mouth_offset=0,
 	c1=13,c2=15,r=3,height=4},
 	{who="tommy tim-tom",spr=11,
 	mouth=0,mouth_offset=0,
 	c1=1,c2=15,r=4,height=4,
  lines="duck duck, buddy!|how's it going?|on an adventure, i see!|i know how that goes...|but that life's not for ol' tommy!|leave the adventurin' to the birds, i always say!|speaking of birds...|what's up with those ducklings?|i saw one headed out west earlier...|course i didn't follow!|birds know best, as i always say!|or is it \"birds know west\"?|...|well, i'll let you get back to it...|best o' luck duck duck!|"},
 	{who="swimmer",spr=10,
 	mouth=0,mouth_offset=-4,
 	c1=10,c2=13,r=4,height=3,
 	lines="oh! duck duck!|what a great day for a swim.|wouldn't you agree?|i've been doing calisthenics here every day.|i feel so much better for it!|so full of energy!|swimming is such great exercise.|though i'm sure you already knew that! ha ha!|...|my friends think i'm crazy for doing this.|they say it's dangerous to be out here alone.|they keep telling me but i just ignore them.|it's like water off a duck's back!|ha ha!|...|thanks for the visit...|but i should get back to exercising.|see you around duck duck!|"},
 	{who="bouncer",spr=9,
 	mouth=0,mouth_offset=-4,
 	c1=9,c2=15,r=4,height=4},
 	{who="pupper",spr=8,
 	mouth=0,mouth_offset=0,
 	c1=4,c2=4,r=3,height=2},
 	{who="?",spr=7,
 	mouth=0,mouth_offset=0,
 	c1=2,c2=4,r=4,height=4},
 	{who="blondie",spr=6,
 	mouth=2,mouth_offset=0,
 	c1=8,c2=10,r=4,height=3},
 	{who="buddy boy",spr=5,
 	mouth=0,mouth_offset=2,
 	c1=12,c2=15,r=3,height=2},
 	{who="ranger",spr=4,
 	mouth=0,mouth_offset=0,
 	c1=3,c2=15,r=4,height=4},
 	{who="scarves mcgee",spr=3,
 	mouth=0,mouth_offset=0,
 	c1=5,c2=4,r=4,height=4,
  lines="hello duck duck!|how are you today?|i'm taking a personal day...|get me some me time, you know?|oh, speaking of which...|i saw a couple ducklings strolling through town.|looked like they were making a day of it!|anyway, nice catching up with you.|make sure to hit me up next time you're in town!|...|...|...i wonder if i should get a new scarf...|"}
 }
 
 for npc in all(npcs) do
  npc.p={rnd(cells.w),rnd(cells.h)}
  --npc.c1=rnd(16)%8+8
  --npc.c2=rnd(16)%8+8
  --npc.r=rnd(3)+2
  npc.r2=npc.r*npc.r
  --npc.height=6
  npc.cell={flr(rnd(cells.bounds[1])),flr(rnd(cells.bounds[2]))}
  
  npc.cell[1]=flr(rnd(6))
  npc.cell[2]=flr(rnd(6))
  
  npc.sfx=flr(rnd(2))+10
  
  npc.lines=npc.lines or "oh hey duck duck!|this is just some test dialog.|it's the same for every character!|i'm just gonna say this now.|"
  
  -- add breaks into lines
  -- (no word breaks)
  local l=npc.lines
  local lw=0
  local ww=0
  local word=""
  npc.lines=""
  while #l > 0 do
   --get next letter
   local c=sub(l,1,1)
   l=sub(l,2,#l)
   word=word..c
   
   -- word ends
   if c==" " or c=="\n" or c=="|" or #l==0 then
    if #word+lw>16 then
     npc.lines=npc.lines.."\n"
     lw=0
    end
    
    npc.lines=npc.lines..word
    lw+=#word
    word=""
    -- newline characters
    if c=="\n" or c=="|" then
     lw=0
    end
   end
  end
  
  -- save the last line for repeating
  local l=#npc.lines
  repeat
   l-=1
  until sub(npc.lines,l,l) == "|"
  npc.lastline = sub(npc.lines,l,#npc.lines)
 end
 
 talk={}
 talk.npc=nil
 talk.bounce=0
 talk.say=""
 talk.said=""
 talk.offset_target=40
 talk.offset=-talk.offset_target
 
 menu=0
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
 
 if x<0 or x>cells.bounds[1]-1 or y<0 or y>cells.bounds[2]-1 then
  c.c=1
 else
  c.c=mapdata[y][x]
 end
 c.biome=biomes[c.c]
 
 -- get colours for edge transition
 c.edges={}
 for u=-1,1 do
  c.edges[u]={}
 for v=-1,1 do
  if x+u<0 or x+u>cells.bounds[1]-1 or y+v<0 or y+v>cells.bounds[2]-1 then
   c.edges[u][v]=1
  else
   c.edges[u][v]=mapdata[y+v][x+u]
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

function add_blob(p,r)
 local blob={}
 blob.hit = false
 blob.p = p
 blob.r = r
 blob.r2=blob.r*blob.r
 add(blobs,blob)
end

function _update()
 
 local v_dif={0,0}
 
 if menu != nil then
  -- menu transition
  if menu==0 then
   if btnp(4) or btnp(5) then
    menu-=1
    sfx(7,3)
    if btnp(4) then
     p.c={4,10,3}
     p.duck=4
    else
     p.c={6,10,4}
     p.duck=5
    end
   end
  else
   menu+=menu/4
   
   if menu < -128 then
    menu=nil
   end
  end
 else
  
  -- movement
  if btn(0) then v_dif[1] -= p.speed[1] end
  if btn(1) then v_dif[1] += p.speed[1] end
  if btn(2) then v_dif[2] -= p.speed[2] end
  if btn(3) then v_dif[2] += p.speed[2] end
  
  -- footstep sfx
  if
   btn(0) != btn(1) or
   btn(2) != btn(3)
  then
   if p.cell!= nil and stat(16) != p.cell.biome.foot_sfx then
    sfx(p.cell.biome.foot_sfx,0)
   end
  else
   sfx(-1,0)
  end
 
 end
 
 
 
 -- quack
 if btnp(4) then
  sfx(5,2)
  p.quack_timer=10
 elseif btnp(5) then
  sfx(6,2)
  p.quack_timer=10
 end
 
 p.quack_timer=max(0,p.quack_timer-1)
 
 perspective_offset[1]=64+sin(time()/9)*4
 perspective_offset[2]=80+sin(time()/11)*4
 
 
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
 if menu!=nil then
  cam.offset[2]+=128+menu*1.5
 end
 
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
 update_npcs()
 update_ducklings()
 update_collision()
 
 
 local pcell={
 flr(p.p[1]/cells.w),
 flr(p.p[2]/cells.h)
 }
 
 pcell=v_sub(pcell,cell)
 
 p.cell=cells.a[pcell[1]][pcell[2]]

 update_footprints()
 update_dialog()
end

function update_footprints()
 if p.cell then
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
end


function update_collision()
 -- blobs
 for b in all(blobs) do
  local d=v_sub(p.p,b.p)
  local l2=v_len2(d)
  if l2 < b.r2+p.r2 then
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
  
  add_blob(v_add({(cells.current[1]+x)*cells.w,(cells.current[2]+y)*cells.h},t.p), t.girth)
  
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

function update_npcs()
 for npc in all(npcs) do
  --npc.p={64,64}
  --npc.id=5
  --npc.r=4
  --npc.height=6
  --npc.c1=8
  --npc.c2=10
  
  --local p=v_add(npc.cell, cells.current)
  npc.p2={npc.cell[1],npc.cell[2]}
  
  if v_distm(npc.p2,v_add(cells.current,{2,2})) <= 4 then
  npc.active=true
  npc.p2[1]*=cells.w
  npc.p2[2]*=cells.h
  npc.p2=v_add(npc.p, npc.p2)
  
  npc.s=v_sub(npc.p2,v_add(cam.p,perspective_offset))
  npc.s=v_mul(npc.s,npc.height*height_mult)
  npc.s=v_add(npc.p2,npc.s)
  
  add_blob(npc.p2,npc.r)
  else
  npc.active=false
  end
 end
end

function update_ducklings()
 -- pick em up
 for d in all(ducklings) do
  if v_distm(d.p,p.p) < p.r then
   d.target=p.ducklings[#p.ducklings] or p
   add(p.ducklings,d)
   del(ducklings,d)
   ducklings.found+=1
   ducklings.found_timer=80
   
   if ducklings.found==7 then
    npcs[1].lines="duck duck!|you found\nthem all!|ha ha, it looks\nlike they're not\ndone exploring\nthough!|feel free to\nbabysit them\nfor now.|just be sure you\ndon't lose them!|thanks again\nduck duck!|"
    npcs[2].lines="duck duck!|you found\nthem all!|um...|would you mind\nlooking after\nthem for a bit?|it's just...\nthey're having\nso much fun!|you could take\nthem exploring!|you're great with\nkids, duck duck!|thank you\nso much!|"
    npcs[1].lastline="|thanks again\nduck duck!|"
    npcs[2].lastline="|thank you\nso much!|"
    npcs[3].lines="oh, you found\nthem all\nduck duck!|next time we\nplay hide and\nseek i'll try\nharder...|"
    npcs[3].lastline="|next time we\nplay hide and\nseek i'll try\nharder...|"
   elseif ducklings.found==1 then
    npcs[1].lines="you found one!|but where are\nthe others?|you've got to\nfind them\nduck duck!!|please find\nour babies!|"
    npcs[2].lines="you found one!|but where are\nthe others?|you've got to\nfind them\nduck duck!!|please find\nour babies!|"
    npcs[1].lastline="|please find\nour babies!|"
    npcs[2].lastline="|please find\nour babies!|"
   else
    npcs[1].lines="duck duck!|you found "..#p.ducklings.."\nducklings, but\nthere's still "..(7-#p.ducklings).."\nleft out there!|please find them!|"
    npcs[2].lines="duck duck!|you found "..#p.ducklings.."\nducklings, but\nthere's still "..(7-#p.ducklings).."\nleft out there!|please find them!|"
    npcs[1].lastline="|please find them!|"
    npcs[2].lastline="|please find them!|"
   end
   
   sfx(8,3)
  end
 end
 
 ducklings.found_timer=max(0,ducklings.found_timer-1)
 
 
 
 -- follow the leader
 for d in all(p.ducklings) do
  local v=min(1,v_distm(d.p,d.target.p)/(p.r*2))*0.4
  d.p=v_lerp(d.p,d.target.p,v*v)
  d.a=-atan2(d.target.p[2]-d.p[2],d.target.p[1]-d.p[1])-0.25
 end
end

function update_dialog()
 local prev=talk.npc
 talk.r=10000
 for npc in all(npcs) do
  if npc.active then
   local r=v_dist(npc.p2,p.p)
   if r<talk.r and r < (npc.r+p.r)*2.5 then
    talk.npc=npc
    talk.r=r
   end
  end
 end
 
 if prev!=talk.npc then
  if #talk.npc.lines > 0 then
   talk.say="|"..talk.npc.lines
  else
   talk.say="|"..sub(talk.npc.lastline,2,#talk.npc.lastline)
  end
  talk.said=""
  printh(talk.npc.who..": "..talk.say)
 end
 
 -- transition view
 if talk.r==10000 then
  talk.offset=lerp(talk.offset,-talk.offset_target,0.25)
  if abs(talk.offset-(-talk.offset_target)) < 1 then
   talk.offset=-talk.offset_target
   talk.npc=nil
   talk.say=""
   talk.said=""
  end
 else
  talk.offset=lerp(talk.offset,0,0.25) 
 end
 
 
 local s=sub(talk.say,1,1)
 local skip=btnp(4) or btnp(5)
 
 --skip only applied mid-line
 if s=="|" then
  skip = false
 else
 end
 
 -- handle text
 if talk.npc!=nil then
  if #talk.say <= 1 then
   talk.say=talk.npc.lastline
  end
  repeat
   s=sub(talk.say,1,1)
   if s!="|" and s!="" then
    
    if stat(19) != talk.npc.sfx then
     sfx(talk.npc.sfx,3)
     talk.bounce=10
    end
    --sfx(5,2)
    -- add letter
    talk.said=talk.said..s
    talk.say=sub(talk.say,2,#talk.say)
   elseif not skip and (btnp(4) or btnp(5)) then
    -- go to next line
    printh("next!")
    talk.said=""
    
    -- remove npc's old line
    while #talk.npc.lines > 0 and sub(talk.npc.lines,1,1) != "|" do
     talk.npc.lines=sub(talk.npc.lines,2,#talk.npc.lines)
    end
    talk.npc.lines=sub(talk.npc.lines,2,#talk.npc.lines)
    
    talk.say=sub(talk.say,2,#talk.say)
   else
    -- reached end of line
    skip=false
   end
  until not skip
 end
 talk.bounce=max(0,talk.bounce-1)
end

function _draw()
 draw_bg()
 
 camera(cam.p[1],cam.p[2])
 
 draw_footprints()
 
 draw_bushes(true)
 draw_npcs(true)
 draw_ducklings(true)
 draw_player(true)
 draw_trees(true)
 draw_buildings(true)
 draw_clouds(true) 
 
 draw_bushes(false)
 draw_npcs(false)
 draw_ducklings(false)
 draw_player(false)
 draw_trees(false)
 draw_buildings(false)
 draw_clouds(false)
 
 --draw_debug()
 
 if ducklings.found_timer > 0 then
  local c=ducklings.found_timer/160
  c=c*c*2
  c=-(-sin(c))*128+64
  --c=lerp(0,c,0.5)
  camera(0,c)
  for i=0,3 do
   pal(0,(i+time()*16)%8+8)
   sspr(40+i*8,16,8,11, 20+i*16,10+sin(time()+i/3)*1.2, 16,22)
  end
  for i=0,5 do
   pal(0,(i+time()*16)%8+8)
   sspr(80+i*8,112,8,11, 20+i*16,30+sin(time()+i/3)*1.2, 16,22)
  end
  pal(0,0)
 end
 
 if menu!=nil then
  draw_menu()
 elseif talk.offset > -talk.offset_target then
  camera(0,talk.offset)
  draw_duckface()
  draw_npcface()
  draw_dialog()
 end
 
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
  pal(0,c)
  for v=0,cells.h/8 do
   spr(4+flr(rnd(4))*16,x+cells.w-8, y+v*8)
  end
 end
 c=cell.edges[-1][0]
 if c!=cell.c then
  pal(0,c)
  for v=0,cells.h/8 do
   spr(3+flr(rnd(4))*16,x, y+v*8)
  end
 end
 c=cell.edges[0][-1]
 if c!=cell.c then
  pal(0,c)
  for u=0,cells.w/8 do
   spr(2+flr(rnd(4))*16,x+u*8, y)
  end
 end
 c=cell.edges[0][1]
 if c!=cell.c then
  pal(0,c)
  for u=0,cells.w/8 do
   spr(1+flr(rnd(4))*16,x+u*8, y+cells.h-8)
  end
 end
 
 end
 end
 
 pal(0,0)
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

function draw_ducklings(shadow)
 camera(cam.p[1],cam.p[2])
 
 if shadow then
  color(5)
  for d in all(ducklings) do
   circfill(d.p[1]+shadow_offset[1]*ducklings.height,d.p[2]+shadow_offset[1]*ducklings.height,ducklings.r+1)
  end
  for d in all(p.ducklings) do
   circfill(d.p[1]+shadow_offset[1]*ducklings.height,d.p[2]+shadow_offset[1]*ducklings.height,ducklings.r+1)
  end
 else
  for d in all(ducklings) do
   circfill(d.p[1],d.p[2],ducklings.r,9)
   circfill(d.p[1]+1,d.p[2]+1,1,10)
  end
  for d in all(p.ducklings) do
   circfill(d.p[1],d.p[2],ducklings.r,9)
   circfill(d.p[1]+cos(d.a),d.p[2]+sin(d.a),1,10)
  end
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
  
  circfill(p1[1],p1[2],p.r*3/4,p.c[1])
  circfill(p2[1],p2[2],p.r/2,p.c[2])
  p2=v_lerp(p1,p2,0.75)
  circfill(p2[1],p2[2],p.r/2,p.c[3])
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

function draw_npcs(shadows)
 camera(cam.p[1],cam.p[2])
 
 if shadows then
  for npc in all(npcs) do
   if npc.active then
    circfill(
     npc.p2[1]+shadow_offset[1]*npc.height,
     npc.p2[2]+shadow_offset[2]*npc.height,
     npc.r,5)
   end
  end
 else
  for npc in all(npcs) do
   if npc.active then
    local s=v_lerp(npc.s,npc.p2,0.75)
    circfill(s[1],s[2],npc.r,npc.c1)
    circfill(npc.s[1],npc.s[2],npc.r-1,npc.c2)
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
 local c=2
 if menu != 0 then
  c=8
  t2*=16
 end
 for i=0,3 do
  pal(0,(i+t2)%c+c)
  sspr(40+8*i,16,8,11,12+12*i,10+sin(t+i/3)*1.2,16,22)
 end
 for i=0,3 do
  pal(0,(i+t2+4)%c+c)
  sspr(40+8*i,16,8,11,9+12*(i+4)+8,10+sin(t+(i+1)/3)*1.2,16,22)
 end
 local s=" on the"
 for i=1,#s do
  pal(0,(i+t2)%c+c)
  print_ol(sub(s,i,i),64+(i-1)*4-#s*2+2,35+sin(t/2+i/#s)+2,5,5)
  print_ol(sub(s,i,i),64+(i-1)*4-#s*2,35+sin(t/2+i/#s),7,0)
 end
 
 for i=0,4 do
  pal(0,(i+t2)%c+c)
  sspr(72+8*i,16,8,11,9+12*(i+2),44+sin(t+(i+2)/3)*1.2,16,22)
 end
 pal(0,0)
end

function draw_menu()
 camera(0,menu)
 draw_title()
 
 local a=-abs(sin(time()/2))*3
 a=flr(a)
 
 -- drake
 sx=64
 if p.duck==4 then
  sx+=16
 end
 sspr(sx,0,16,16,0,128-32-a,32,32+a)
 sx=96
 
 -- hen
 if p.duck==5 then
  sx+=16
 end
 sspr(sx,0,16,16,128-32,128-32-a,32,32+a,true)

 -- quack text
 if p.duck==4 then
  print_ol("Ž",33,127-16,7,0)
 else
  print_ol("Ž",33,127-16,0,7)
 end
 if p.duck==5 then
  print_ol("—",97-8,127-16,7,0)
 else
  print_ol("—",97-8,127-16,0,7)
 end
 print_ol("• quack •",43,127-16,0,7)
end

function draw_duckface()
 local t=p.quack_timer
 local a=abs(sin(t/40))*5-abs(sin(time()/2))*3
 a=flr(a)
 sx=64
 if p.duck==5 then
  sx+=32
 end
 if t > 0 then
  sx+=16
 end
 sspr(sx,0,16,16,0,128-32-a,32,32+a)
end

function draw_npcface()
 local a=abs(sin(talk.bounce/40))*5-abs(sin(time()/2))*3
 a=flr(a)sx=0
 sy=32
 local npc=talk.npc
 sx+=npc.spr*16
 while(sx >= 128) do
  sx-=128
  sy+=16
 end
 
 sspr(sx,sy,16,16,128-32,128-32-a,32,32+a)
 
 -- npc mouth
 if npc.mouth >= 0 then
  local c=sub(talk.say,1,1)
  if c!="|" and c!="" and time()%0.2 > 0.1 then
   pal(0,npc.mouth)
   sspr(56,0,8,16,128-20,128-32-a+npc.mouth_offset,16,32+a)
   pal(0,0)
  end
 end
end

function draw_dialog()
 local a=abs(sin(talk.bounce/40))*5-abs(sin(time()/2))*3
 a=flr(a)
 print_ol(talk.npc.who,127-#talk.npc.who*4-2,127-39-a,0,7)
 print_ol(talk.said,32,127-24,0,7)
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
eeeeeeeeeeeeeeee00e000ee0e0eeeeeeee0eee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777eeeeeeeeee777777eeeeeeeeee777777eeeeeeeeee777777eeee
eeeeeeeeee0eee0eeeeeeeee0e0e0eeee0eee0e0eeeeeeeeeeeeeeeeeeeeeeeeeeeee77333377eeeeeeee77333377eeeeeeee77444477eeeeeeee77444477eee
ee7ee7eeeeeeeeeee00e0e000eeeee0eeee0e0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee73333337eeeeeeee73333337eeeeeeee74444447eeeeeeee74444447eee
eee77eeee0e0e0e0eeeeeeee0e0e0eeeeeeeeee0eeeeee999999eeeeeeeeeeeeeeeee73333337eeeeeeee73333337eeeeeeee74444447eeeeeeee74444447eee
eee77eeeeeeeeeee0e0e0e0e0eeeeeeeeee0e0e0eeeee99888899eeeeeeeeeeeeeeee73303307eeeeeeee73303307eeeeeeee74404407eeeeeeee74404407eee
ee7ee7ee00e0e00eeeeeeeeeee0e0eeee0eeeee0eeeee98080889eeeeeeeeeeeeeeee73303307eeeeeeee73303307eeeeeeee74404407eeeeeeee74404407eee
eeeeeeeeeeeeeeeee0eee0eeee0eee0eeee0e0e0eeeee88080888eeeeeeeeeeeeeeee73303307eeeeeeee7330330777eeeeee74404407eeeeeeee7440440777e
eeeeeeee00000e00eeeeeeee0eee0eeeeeeee0e0eeeee88080888eeeeeeeeeeeeeeee73333aa777eeeeee73333aaaa7eeeeee74444aa777eeeeee74444aaaa7e
eeeeeeeeeeeeeeee00e000000eeeeeeeeeeeeee0eeeee888888888eeeeeeeeeeeeeee7333aaaaa7eeeeee7333aaa777eeeeee7444aaaaa7eeeeee7444aaa777e
eeeeeeeeeee0eeeeeeeeeeee0eee0eeeeeeee0e0eeeee888888888eee000eeeeeeeee7333333777eeeeee73330037eeeeeeee7444444777eeeeee74440047eee
eeeeeeeeeeeeeeeee0eee0ee0e0eeeeeeee0eeeeeeeee88000888eeee000eeee7777773333337eee777777333aa377ee7777774444447eee777777444aa477ee
eeeeeeeee0eee0eeeeeeeeee0eeeee0eeeeeeee0eeeee88888888eeeeeeeeeee7444773333337eee7444773333aaa7ee7666774444447eee7666774444aaa7ee
eeeeeeeeeeeeeeeeee0eee0e0eeeeeeee0eeeee0eeeeeee8888eeeeeeeeeeeee4444443333337eee44444433333377ee6666664444447eee66666644444477ee
eeeeeeeeee0eee0eeeeeeeeeeeee0eeeeeeee0e0eeeeeeaa88aaeeeeeeeeeeee44444443333477ee44444443333477ee66666664444677ee66666664444677ee
eeeeeeeeeeeeeeeeeeee0eee0e0eeeeeeee0eee0eeeeeeaaaaaaeeeeeeeeeeee44444444444447ee44444444444447ee66666666666667ee66666666666667ee
eeeeeeee00000e00eeeeeeee0eeeeeeeeeeeeee0eeeeeeaaaaaaeeeeeeeeeeee444444444444447e444444444444447e666666666666667e666666666666667e
77777eeeeeeeeeee0ee0ee000eeeeeeeeeeee0e0777777ee7777777e7777777e7777777e7777eeeee77777eee77777eee777777e7777777e7777777e777777ee
700075eeeeeeee0eeeeeeeeeee0eee0eeee0eee07000077e70077075770000757007707570075eee7700077e7700077e7700007570000075700770757000077e
700075eeeeeeeeeee0ee0ee0eeeeeeeeeeeeeeee7007707570077075700777757007707570075eee700770757007707570077775700777757007707570077075
700075eee0e0eeeeeeeeeeee0eeeeeeeeee0e0ee7007707570077075700755557007077570075eee700770757007707570075555700755557000707570077075
770775eeeeeeeeeeeeee0e0eee0e0eeeeeeeeee0700770757007707570075eee7000775570075eee7007707570077075700777ee700777ee7000707570077075
777775ee0ee0ee0eeeeeeeeeeeeeeeeeeeeeeeee700770757007707570075eee7007077e70075eee70077075700770757700077e7000075e7000007570077075
700075eeeeeeeeeee0eeeeee0eee0eeee0eee0ee700770757007707570075eee7007707570075eee7007707570077075e77700757007775e7007007570077075
700075ee00ee0ee0eeeeeeee0e0eeeeeeeeeeee070077075700770757007777e700770757007777e7007707570077075777700757007777e7007707570077075
700075eeeeeeeeeeee00e00eeeeeee0eeee0eeee7000077577000775770000757007707570000075770007757700077570000775700000757007707570000775
777775eeeeeeeee0eeeeeeeeeeeeeeeeeeeee0e077777755e7777755e77777757777777577777775e7777755e777775577777755777777757777777577777755
e55555eeeeeeeeeeeeeeee0e0eeeeeeeeeeeeee0e555555eee55555eee555555e5555555e5555555ee55555eee55555ee555555ee5555555e5555555e555555e
eeeeeeee0eee0eeeeeeeeeee0eee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeee0eee0eeeeeeeeeee0eee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee0eeeeeeeeeeeeee0eeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee0eeeeeee0e0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee00e00eeeeeeeeeeeeee0eeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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
eee7444444776667eee7333333774447eeeeee7799999779eeeee744444477eeeeeee77ffff77eeeeeee7ff000fff77eeeee7ffffffffaa7eeee74444444407e
eee7444444666666eee7333333444444eeeeee7999999999eeeee77666677eeeeeee7739553377eeeeee77ffffff77eeeeee7aaffffaaaa7eeee77044440077e
ee77644446666666ee77433334444444eeeee77996699999eeeee75665557eeeeeee73339aa337eeeeee7777ff7777eeeeee7788ff88aa77eeeee766446677ee
ee76666666666666ee74444444444444eeeee79966669999eeeee75655557eeeeeee7f335933f7eeeeeee7ccffcc7eeeeee77f888888fa7eeeeee76666667eee
ee76666666666666ee74444444444444eeeee79666666999eeeee75555557eeeeeee7f335593f7eeeeeee7cccccc7eeeeee7ff888888ff7eeeeee72222227eee
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
eeeee77777777eeeeeee7777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeee711111877eeeeee7000000007eeeeeeeeeeeeeeeeeeeeeee77777777eeeeeeeeeeeeeeeeeeeeeeee77979777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee771c1c18877eeeee7000000007eeeeeeee777eee777eeeee77f0ffff77eeeeeee77777777eeeeeee77a9a9a977eeeeeee77777777eeeee777777777777ee
eeee71818181887eee77788888888777eeeeee797777797eeeee7fff0ffff7eeeeee7744444477eeeeee79a444a9a7eeeeee7755555577eee77444444444477e
eeee78888888187eee700ffffffff007eeeeee799777997eeeee7ffff000f7eeeeee7444444447eeeeee7444444447eeeeee7aaaaaaaa7eee74444444444447e
eeee7ff0f0ff817eee777ff0f0fff777eeeeee7999999a7eeeee7ff0f000f77eeeee7400400447eeeeee7440404447eeeeee7accccc6a7eee74000040040047e
eeee7ff0f0fff87eeeee7ff0f0fff7eeeeeeee7999999a7eeeee7ffff000ff7eeeee7400400447eeeeee7440404447eeeeee7ac7c7c6a7eee74444444444447e
ee777ff0f0ffff7eeeee7ff0f0fff77eeeeeee790909997eeeee7fffffff0f7eeeee74404044477eeeee74404044477eeeee7ac7c7c6a7eee74000004000047e
ee717ffffffff17eeeee7fffffffff7eeeeee7790909997eeeee7ff000fff77eeeee74444444447eeeee74444444447eeeee7accccc6a7eee74444444444447e
ee717fffff0ff17ee7777fffff0fff7eeeeee7009999997eeeee7fffff0ff7eeeeee74444444447eeeee74444404447eeeee7a66666aa7eee74004000400047e
ee717ff000fff17ee7ff7ff000fff77eeeeee7999999997eeeee77ffffff77eeeeee74400044477eeeee74400044477eeeee7a65656aa7eee74444444444447e
ee7174ffffff417ee7ff7ffffffff7eeeeeee79900099977eeeee777ff777eeeeeee7444444447eeeeee7444444447eeeeee7766666a777ee77777744777777e
e77174444444717ee700777ffff777eeee77777999999997eeeee78888887eeeeeee7774444777eeeeee7774444777eeeeeee7755556667eeeeeee7447eeeeee
e788774444478877e7000000ff007eeeee79977799999999eeee7766666677eeeeeee79944997eeeeeee778f44f877eeeeee776aaa6a667eeeeeee7447eeeeee
e788771441178817e700000088007eeeee7799799aaaa999eeee7ff8888ff7eeeeeee79999997eeeeeee748ffff847eeeeee7a6aaa6aa67eeeeeee7447eeeeee
e771111111177117e777770066007eeeeee77979aaaaaa99eeee7fff66fff7eeeeeee79999997eeeeeee748f88f847eeeeee7a6aaa6aa67eeeeeee7447eeeeee
81111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111cccccccccccccccccc1111111111cccccccccccccccccccccccccccccccccccccc11111cccccccccccccccccccccccccccccccccc11
11111111111cccc111ccccccccccccccccccccccccccccccccccccccccccccccccc44ccccccccccccccccccccccccccccccffffffffbbbbccccbbb3333ccccc1
111111111ccccccccccccc11cc1111cccccffccccccccccccccccc444433cccc33444cccce33e333333444ccccccccccbbbfffaaafffbbfbbcbbb33bb333ccc1
11111111ccccccccccc11111cc11111ccc4ffffffffffffffffff44444433333334444333333333e3344444fffffbbbbbbfaaaaaaaaafbbbbc3333bbbb333cc1
1111111ccccccccc111111111cc1111cc4fffffffffffffffffffff44444333333344444333e3333444444fffffbbbbbbfaaaaa6aaaaafbbcc3333bbbb3333c1
111111ccccccccc11111111111ccc1cccfffffffffffffffffffffff444444333344444443333334444433333ffbbbbbffaa6666666aaaaaaaaa3333333333c1
11111ccccccccc111111111111ccccccfffffffffffffffffffffffff44444444444444444444ccccccc344433bbbbbbffaa6aa6aaaaaaaaaaaaa3e3333333c1
1111cccccccc11111111111cccc1ccccccccccccccffffffffffffffff444444444444444444ccccccccccc443bbbbbfffaa666666666666666aaa33333333c1
1111cccccc1111111ccccccccccccccccccccccccccccccccccccccfffff44444444444444cccccccccccccc43bbbbbfffaaaa6aaa6aaaaaaaaaa333e33333c1
111ccccc11111111ccccccccccccccccccccccccccccccccccccccccccccff44444444ccccccccccc44ccccc43bbbbbfffaa6666666aaaaaaaaa3333333333c1
111ccc11111111cccccccccccfbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccc44bbcccc33bbbbbbffaaaaaaaaaaafc334333333333333c1
11ccc11111111ccccccccccfbbbfffffffffaaaffff4f4444cccccccccccccccccccccc4ffccccc33ebbbcccc3bbbbbbb33aaaaaaaaabcc33333333333333cc1
11cc11111111ccccccccbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffbfffffffff44ffffcccc43bbbbcccccffbbbbb3f33fffffffffc33333333333e33fcc1
11cc1111111cccccbbbbbbbbaaaaaaaaaaaaa6aaaaaaaaaaaaaaaaaaabbfffffffffffffffccc4433bbcccccffffbbbbbb33fbfffffffc33333333333333fcc1
1ccc111111ccccffbbbbbbbbaa66666666666666666666666666666aab333fffffffffffffcccc433cccccccbffffbbbb3bb3ffffffffc333343333e3333fcc1
1ccc111111ccccfffbfbbbbbaa6aaaaaaaaaa6aaaa6aaaaa6aaaaaaaa33333fffffff333334cccc3ccccccccbb3333bbbbfbbfffffffccf333333333333ffcc1
1cccc111111cccfffbbbbbbbaa6aaaaaaaaaa6aaaa6aaaaa6aaaaaaa3333333fffff33333344cccccccccccb333b33bbbbbbbfbfffffcffbb33333333bbfccc1
1ccccccc111ccccfffbbbbbaaa6aaaaebaaaa6aaaa6aafaa6aaffbbb3333e33333ff333e33344ccccccccbb33bbb33bbbbbbbfbfffffcfffb3333333bbbfccc1
11ccccccc11ccccffffbbbbaa6666aabcaa666aaaa6aafaa6aaffbb3333b333333334433333344443ffffb33bbbb333bbbbbbffffffccfffbb33333bbbbfcc11
11cccccccc11cccffffffffaaa6aaaaebaaaa6aaaa6aafaaaaafbb3333bb33333334444b333333333ffff33bbbbb333bbbbfbffffffcfffffbbb33bbbfffcc11
11ccccccccccccccffffbfffaa6aaaaaaaaaaaaaaa6aaffaaafbb333bbbb333334444bbbbbbbfffffffff3bbbbbe333bbbbbbffffffcffffffbbbbbbbbffcc11
11cccccbccc1ccccbbffffffaa6aaaaaaaaaaaaaaa6aafffffbbbbbbbbb333333344bbbbbbbfffffffffb33bbbe3333bbbbbbfbfffccffffffbbbbbbffffcc11
1cccccbbbcccccccbbbbffffaa6aaaaaa66666aaaa6aafffbbbbbbbbbb3333e33333bbfbbbffffffffbbbb33333333bbbbbbbfffffcfffffff3bbfffffffccc1
1ccbbb33bbccc1ccbbbbbaaaaa6aaa6aa6aaa6aaaa6aaffbbb3333bbbb3333333333bbffbfffffffffbbbbb3333333bbbbbbbbfffccfffffffbffffffffffcc1
1cbbb3333bccccccbbb4aaaaaa6aaa6aa6aaa6aaaa6aafbbbbb333bbbb333333333bbbfbffffffffffffbbfbbbbbbbbbbbbbbbfffcfffffffffffffffffffcc1
1cb333333bbcccccbbbbaa666666666aa6aaa6aaaa6aabbbbbbbb33bbbbb333333bbbbbffffffffffffbbbbbbbbbbbbbb333bbffccfffffffffbfffbbfff3cc1
1cb33e333bbcccccbbbbaaaaaa6aaa6aa6666666666aabbbbbbbb33ebbbbbb3bbbbbbbbff3e3e3ffbffbfbbbbbbbbbbb3333bbffcfffffffffffffbbbb333cc1
1cb333333bbfcccccbbbbaaaaa6aaa6aaaaaaaaaaa6aa3bbbbbbbbbbbbbbbbbbbbbbfffffeaaaeffffbbbbbfbbbbbbb33333bbfccfffffffffffffbbb33333c1
1cbb3333bbffcccccbbbbbbfaa6aaa6aaaaaaaaaaa6aa333bbbbbbbbbbbbbbbbbbbbbffff3aea3fbffbbbffffbbbbb333333bbfcffffffffffffb3bb333333c1
1c3bbbbbbbfffccccbbbfbbfaa6aaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbffbffffffeaeaefffffffffffbbbb3333333bbccfffffffffffffff3333333c1
1cbbbbbebbbfffcccbbbfbbfaa6aaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbfffbffff3aea3fbbbfffbbfbbbbb3333333bbcfffffffffffb3ff33333333c1
1cbb3bbbbbbffffcccbbbbffaa6666666666666aaaaa66666666666aafbbbbbffffffffffeaeaefbbbffbbbbbbbbbb33e333bcc33ffffffffffff333333333c1
1cbbbbbbbbbfbffccccbbbffaaaaaa6aaaaaa6aaaaaaaaaaaa6aaaaaabbbbffffbfffffff3aea3fbbffffffbbbbbbb3333bbbc3333fffffffffff33333333ec1
1cbb333bbfffbffccccbbffffaaaaa6aaaaaa6aaaa6aaaaaaa6aaaaabbbbffffffbffffffeaaaeffffffffffffbbbbbbbbbbcc3333ffffffffff333bb333eec1
1cb3333fffbfffffccccbfbfffffaaaaaffaa6aaaa6aafffaa6aafbbbbbfffbbfffffffff3e3e3fbfffffffffffffbbbbbbbc33333fffffffffb33bb3333eec1
1cb3e333ffffffffcccccffffffffaaafffaaaaaaa6aabffaa6aafbbbbbfffffffffffffffffffffffffffffffffffbbbbbcc33333ffffffffb333bb333ee3c1
1cb3e333ffffffffbcccccc4ffffffffffffaaa3aa6aabbbaa6aaaaaaaaaaaafffffffffffffffffbffff33333fffff3333c333e3fffffffffb333bb333eeec1
1cf3333fffffff33bbcccccc4ffffffffffb3333aa6aabbbaa6aaaaaaaaaaaaaffffffffffffffffffff33333333333333cc33333ffffffff3333333333eeec1
1cff33ffffffff33bbcccccccffffffffffbb33baa6aabbbaa666666666666aaffffffffffffffffff333333333333333cc333e333ffffffb3333333333eeec1
1ccfffffff3ff3333bbccccccccfffffbbbbbbbbaa6aabbbaa6aaaaaaaaaaaaafffffffffffffffff333333333333333ccf333333ffffff3333b3333333ee3c1
1ccffffffffff33333bbccccccccc44bbbbbbbbbaa6aafbfaa6aaaaaaaaaaaaffffffffffffffff333333333ff333334c4ff3333ffffff33333bb33333333ec1
1cccfffffff3333333bbbcccccccccccccc4bbbfaaaaafbfaaaaafffffffffffffffffffffffff33333333ffffff444cc4fff33ffff33333333bbb33333e3ec1
11ccfff3ff333e3333fbbbbccccccccccccccccccaaacccccaaaccfffffffffffffbbbffffbbb333333333fffff4cccc44fffffff3333333333beb3333333ec1
11ccfffff333333333fbbbbbcccccccccccccccccccccccccccccccccccccccccccbbbbfffb333333e3333ffff4cccc4ffffffff33333333333bbb3333333ec1
11ccfff3333333333ffbbbfbbbfcccccccccccccccccccccccccccccccccccccccccccc333333333333333fffcccc4ffffffff33333333333333b333333333c1
1cccff3333333333ffbbbbbbbbffffccccccccccccccccccccccccccccccccccccccccccccc3333333333fcccccfffffffffff33333333333333333333333cc1
1ccff3333333333ffffbbbbfbbbbfbbbbb4b4444444bbfffffffccccccccccccccccccccccccccc33333ccccccccccccccccccccc33333333333333333333cc1
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
c1fc3f33e33333ffffbfbbbbbbbbffbbbbbb4b4444bbfbffffffffffffcfcccccccccccccccccccccccccccccccccccccccccccccccccccc333333333333cc1cc1fcff333e33f3ffffbbbbbbbbbbbbbbbbbbbbbbbbbbfffbffffffffffffffffffffffccccccccccccccccccccccccfcff33333333cccccccccccccccc3ccc11
c1ffff333333ffffbfbbbbbbbbbbbbbbbfbbbbbbbbfbffffffffffffffffffffffffffffffffbffbffffffffffffffff3f333333333333333333333333cccc11c1ffff3f33f3ffbfbfbb333333b3bbbbbbbbbbbbbbffffffffffffffffffffffffffffffffffbfffffffffffffffffff3333333333333333333333333333cc11
c133ffffffffffffbfffff3f3333b3bbbbfbbffbfbfffbffbfffffffffffffffffffffffffffffffffffffffffffff3f3333bb3333333e33333333333333c311c133ffffffffbfffaaffaaffe333b3bbbbffbbffffffffffffffffffffffffffffffffff3f333333f3ffffffffff3f3333b3bb3b33333333333333333333c31c
c133f3ffffffffafaaaaaaff3f3333ffffbfbbfbaafaffbffbffffffffffffffffffff3333b33b33333333ff3f333333b3bbbbbb3b333333333333333333c31cc13333ffffffffaa6a66aaffffffffaf6666666666faffbfbbffffffffffffffffff3f3333bbbb333333333333333333bbbb3b3333333333333333333333331c
c13333f3ffffffaa666aaaaaafffffaaa6aaaaaa6afabfbbbffbffbfbbbbfbffff3f333333b3bb333333333333333333b33b33bbbbbbbbbbbb3b33333333e31cc1333e33ffffffaa6666666666666666a66666666affffbbbbbbbbbbbbbbbbffff3333333e33333333333333333333333333bbbb33333333b4bb3333e33ee31c
c1333333f3ffffaaa66aaaaaff33baaba6b6bb6b6affffbbfbbbfbbfbbb3bbff33333333333333333333e3333333333333b3bb3be343444444b4ebe33333e31cc1333e333333f3aa6666aaffff33b3bba6b6ee6b6afbffbbbbbbbbffbbbbbb3333e3333333333333e33333333333333333b3bb333333334344b43b3333e3e31c
c13c333333f34f44644644ff3f33b3bba6b6ee6b6afbffbbbbb3bbbbbb33333333333333333333333333333333e3333333bb3b33334444444444bb3eee33331cc1ccfc33f3ff44c46cc644f43333b3b3a6b6bb6b6abbffbfbbbbbbbb3b33333333333333333333333333333333333333bebb3be3434333444444bb3ee33ee31c
11ccccfccfcccccc6cc6ccfc3333b3bb6666666666bbf3bfbbbbbbbb3b33333333333333333333333333333333333333b3bb3b33333343444444b43b3333331c11c1cccccccccccc6cc6cccc3c3333bbbb4b66b4bbbb33bfbbbbbbbb3f3333333333333333333333333333333333333eb3bb3b3e434344473443443b3333331c
11c1cccccccccccc6cc6cccccccc333bb3446644cccc33bfffbbfbff3f33333333333333333333333333333333333333b3bb3b3344447477444344bb3ee33e1c11c1cccccccccccc6cc6cccccccccccccccc66cccccc3cbfbbfbffffff333333333e33333333333e3333333333333333b3bb3b4344447777474344bb3e33331c
1111cccccccccccc6cc6ccccccccccccccccc6ccccccccffffffffffff3f333333333333e33333333333333333333333f3bb3b43344474774443b4bb3b3e331c1111cccccccccccc6cc6cccccc1c1111c1cc1cc1ccccccfffffbffb4ffffff3333333333333333333333333333333333f3bbbb43344444473444b4bb3b33c31c
1111cccccccccccc6cc6cccccc11111111111111ccccccfffff3ff3ffbffffff333333333333bb3b33333e333333f3ffffbfbb43444344444444b4bb3be3c31c1111cccccccccccc6cc6cccccccc1c1111111111ccccfcfffbffffffffffffffbbbbbbbb3333bbbb3b3333333333ffffffffbb4b443333444444bbbb3b33c31c
1111cccccccccccc6cc6cccccccccccc1c11c1ccccccffff44ffffffffffffffbb3bbbbbbb3333333333333333ffffffffffbbbb44444444b4bbbbbb3b33c31c1111cccccccccc44644644f4ffccccccccccccccccfcffffffbff3ffffb4fbbfbb33bbbbbb3b3333333333ffffffffffffffbbbb4b4444bbbbbbbbbb3b33c31c
11c1ccccccff444466664affffffcfccccccccccccffffffffffffffffbbffbbbbbbbbbb3bfbffffffffffffffffffffffffbfbbbbbbbbbbbbbbbbbb3333c31c11c1ccccfcff4f444664aaffffffffcfccccc6fcffffffffffffffff3ffbbfbbbbbbbbb3bbbbffffffffffffffffffffffffffbfbbbbbbbbbbbbbbbb3bbbc31c
11c1ccccffffffa46666aafffffaffffff4f66ffffffffffff43fffbffffbbbbb3bbbbbbb3bbbbfbfffffffff3ffffffffffffffbfbbbbbbffffbbbb3bb3c31c11c1ccffffffffaa466afaffffffffffff4f64f4ffffffffffffffffffbfbbbbbbbbbbbbbb3bbbbbffff4fffbfffffffffffffffffffffffffffbfbbbbb3331c
11ccfcffffffffaa6666affffffffffff44f44f4ffffffffffffffffffbffbbbbbbbbbbbbbbbbbbbbfffffbfffffffffffffffffffffffffffffffbbbbbb331c11ccfcffffffffff66ffffff4fffffff4f4f44f4f4fffffffffff4ffffbbbbebeeeeeeeeeebebbbbbffffff4ffffffffffffffffffffffffffffffbbbbbb331c
11ccfffffffffff4ffafffffffffffff4f4f46fff4f4ffffffff3bfff4bbfbebbbbbbbbbbbbebbbbbffbffffffffffffffffffffffffffffffffffbfbbb3331c11ccffffffffffffffff4f4444ff4fffffff44f4f4ffffffffffffffffbbbbebebeeeeeebebebbbbbffbffffffffffffffffffff3333333333ffffffbbb33b1c
11fcffffffffafffffffff44444444f44f4f64ff44fffffffffffffbffbbbbebebbbbbbbbebebbbbfffbfff3f3ffffffffff3f33333333333333ffffffb33b1c11fcffffffffffffffffffff444444ff4ff444ffffffffffffffffffffbbbbebebebeebebebebbb3fbff4bffffffffff3f333333333e33333333f3ffff333b1c
11fcfffffffffffaf4fff4ffffffffffff4444fff4f4ffffffffffffffbbbbebebebbbbebebebbbbbbffffffffffff3333333333333333aaaaaaaaffff333b1c11fcfffffffffffa4fff4f4444444444ffff44ffffffffffffffffffbfbbbbebebebebbebebebb3bbbfbffffffff3333333333333333aaaa6666aaffff333b1c
11fcffffffffffff44ff444fcc4cf4ff44ff4fff4fffffffffffffffbfbfbbebebebbbbbbebebfbbfbffffffff3f333333aaaaaaaaa3aaaaa66aaaaafa33331c11ccffffffffff4ff4fff4441ccc4cf44fff4ff4ffffffffffffffffbbbbbbebebebeeeebebebbbb3f3333333333aaaaaa6a6666aaaa6a66a66aaaaaaa33331c
11ccffffffffff4ff44f4fc4cccccc4444f4fff4ffffffffffffffffbbbbbbebebbbbbbbbbbebbff3fa3aaaaaa3aaa66666a6a6baaaa6aaaa66a6666a63fc31c11ccfcffffffff4fff4f4fccccc1c144f4f4f4f4ffffffffffffffffbbbbbbebebeeeeeeeebefbff33aa6a66a6aaaaa66a6a6a6b6a6666aaa66acccca6cacc1c
11ccfcffffffff4ff44f441c1cc1cc4c44f4f4f4ffffffffffffffffbb3bbbbbbbbbbbbbbbbbff3fb36a66aaa6aaaaa66a666a6b6a3363aa6666bccba6cacc1c11ccccffffff4f4ff4ff44cc1c111ccc4ff4f4f4ffffffffffffffffbbbbbbbbbbbbbbbbbfff3f33bb6a6aaa66a666a66a6a6a666ae363aaa66acccca6cacc1c
11ccccfffffffffff4ff4fc41ccccccc44f4f4f4fffff4ffffffbfbfbbbbbbbbbbbbbbffffff33bbbb6a6a66a666a6a66a6aaa6a6a336366a66a6666a6cacc1cc1ccccfcffffffffffff4f44cccccc44f4f4f4ffffffffffffffbfbfbbbbbbbbbfbbbb3f3e3ebeabaa6aaaaa66a6a666666a6a66666666aaaaaaaaa6aacacc1c
c1ccccccfffffffffff4ff4444c444444f44f4ffffffffffffffbbbfbbbbbbbbbbfbbb6bbbbbbbaaaa6a3aa3aaaaa6aaaa6a6aaaaaaaaaaa3333a3a67ac7cc1cc1ccccccfcffffffffffff4f44444444f44fffffffffffffffffbbbfbbbb33bbbbfbbb6b6666666666666666666666666666666666666666666666a67777cc1c
c1ccccccccfffffffff4fff4ff44fff4ff44ffff4fffffffffffbbbbbb3333bbfbbfbb6b6666666666666666666666666666666666666666666666a67777cc1cc1ccffcfccfcffffffffffffff4f4444ffff44ffffffffffffffbbbbb333b3bbffbbfb6bbbbbbbaaaa6aaaaa3aa3a6aaaa6a3a3e3e6aaaa6e3e3a3a67777cc1c
c1ccffffccccffffffffffffffffffffff44f4ffffffffffffffbfbbbbbbbbbbbbbfbb3f3e3ebeabaa6a6a66aaaaa66a666a3a33336aaaa63333a3a67a77cc1cc1ccffffcfccfcffffffffffff4f44444444ffffffffffffffffbfbbbf3bfbbbfbbbfbffffff33bbbb6a666a66a6a66a636aaaaaaa6aaaa6aaaaaaa6aa77cc1c
c1ccfcffffccccfffffffffff4ffff44f4ffffffffffffffffffffbbbbbbbbbbbbbbffffffff3f33bbaa6a66aa66a66a6e66a6aa6a66a66666666a66aa77cc1cc1ccccffffcfccfcfffffffffffffffffffffff4fffff4ffffffffbbbbffbbbbbbffffffffffff3fb3aaaaa6aaa6666663aa666666aaa6a6b66b6a6aaa77cc1c
c17cccfcffffccccffffffffffffffffffffffffffffffffffffffbffbbfbbbfffffff7777ffffff33aaaa6666a6aa6a66aaa6a66aaaa6a6b66b6666aac7cc1cc1ccc7ccfcffcfccccffffffffffffffffffffffffff7f7777ffffffffffffffffff7f777777f7ff3f33aaaaaaaaaaaaaaaa66a66a6666a66666aaaa7ac7cc1c
c1cc77c7cc77ffccccccccccccccccffffffffffff77777777c7fcffcfcccccccccccccc777777f7ff3fa3aaaa3a33a3aaa3aaaaaaaaaaaaaaaaaaaa77cccc1cc1cc7c77c77c77ffccccccccccccccccffffff77777777cccccc7777ccffffffffff77c7cccccc77773f333333333333333333333333333333333377c7cccc1c
c1cccc7777cc7777ffcfcccccccccccccc7c777777cccc7c777777777777ccfc7f77c7cc7c77c7cc77777737333333333333333333333333737777c7ccccc71cc1cccc7c77c77777ffffffff7777cccccccccccccc7c777777777777777777c7cccccc77777777c7cccccc77773333333333e333333333777777cccc77c7cc1c
11cccccc77777777f7ff7f7777777777c7cccc7c77777777777777777777777777cc7c77777777777777c7cc77777777773733333373777777c7cccccccccc1111cccccc7c77777777ffcccc7777777777cccccccccccc7777777777777777777777cc7c77777777777777c7cccc7c7777777733337777cccccc777777c7cc11
11c1cccccc7c7777777777cccc7c77c7cccc7ccccc77c7cc7c7777cc7777cccccc7cc7ccccc7cccccccc7c777777ccccc777777777c7cccc7c777777c7cc1c111111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc7cccc77c7cc7777c7cccccccccccccc77777777cccc1c1111
111111c1cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
__sfx__
010300060561407611096110961508605046050160100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
0003000603514085110f5111951109515045050150100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
000300062a615136011b6010960108601046050160100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
00030006016140561507604076050560401605016010060100601006010060100601006010060100601006010d001006010060100601006010060100601006010060100601006010060100601006010060100601
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001117505171071710a1710e175122741827111271102711124114231232511d26124271292750000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000517505171071710a1710e175122741827111271102711124114231172511d26118271112750000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002b000360003b00036000120000d000090000700006010040100501007010090200b0300e03011030150401d050210502805030060370603d060000000000000000000000000000000000000000000000
000900001b5151d5251b5251f0251b535220351b5352b04533550330613356133061335613355133551335413354133531335313352133521335113351533505335052650528505265052a505315053550537505
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000000000000000d0500a05009050080500000000000000000d0500d0500c0500905010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000000000000005050060500b050110500000000000000000405005050070501005010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

