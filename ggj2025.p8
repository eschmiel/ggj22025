pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	state = mk_title_st()
end

function _update()
	state:update()
end

function _draw()
	cls()
	state:draw()
end
-->8
function mk_title_st()
	return {
		b_mgr=mk_bub_mgr(),
		a=0,
		update=function(self)
			self.b_mgr:update()
			if(btnp(❎))self.b_mgr.b_max+=1
		end,
		draw=function(self)
			rect(0,0,127,127,0)
			dr_play_area()
			self.b_mgr:draw()
			if(#self.b_mgr.list>0)then
				pr_f_list(self.b_mgr.list[1].f_mgr.list)
				print(self.b_mgr.list[1].a)
			end
		end
	}
end

function dr_play_area()
	rect(
				p_l_wall,
				p_ceil,
				p_r_wall,
				p_flr,
				3
			)
end


-->8
--test

function ang_cont(self)
--	if(btn(⬆️) or btn(➡️))then

	if(btn(⬅️))then
		self.a+=.02
	end
--	if(btn(⬇️) or btn(⬅️))then 
	if(btn(➡️))then
		self.a-=.02
	end	
	if(self.a>1)self.a=0
	if(self.a<0)self.a=1
	
	if(btnp(❎)) self.f_mgr:add_f(self.a,1)
end

function pr_ang_vec(self,x,y)
 local v = mk_vec(self.a)
	print(self.a,x,y,7)
	print(v[1]..","..v[2],x,y+10)
end

function dr_t_circ(x,y,a)
	local r=7
	circ(x+r,y+r,r,10)
	local v = mk_vec(a)
	local mv={v[1]*r,v[2]*r}
	pset(x+r+mv[1],y+r+mv[2],8)
end

function demo_bub()
			circ(20,20,1,7)
			circ(20,30,2)
			circ(20,40,3)--small
			circ(20,60,4)
			circ(20,80,5)--med
			circ(20,100,6)
			circ(20,120,7)--large
end

function dr_dir_arr(bub)
	local uv=mk_vec(bub.a)
	local x=bub.x
	local y=bub.y
	line(x,y,uv[1]*3+x,uv[2]*3+y)
	pset(uv[1]*3+x,uv[2]*3+y,9)
end

--[[
function float(bub)
--	bub.y-=1
	local uv=mk_vec(bub.a)
	bub.x+=uv[1]
	bub.y+=uv[2]
end
]]

function pr_f_list(f_list)
	local x=0
	local y=10
	for f in all(f_list)do
		for v in all(f) do
			print(v,x,y)
			y+=10
		end
	end
end

function log(...)
	local vals={...}
	printh('','ggj',true)
		
	for v in all(vals) do
		printh(v,'ggj')
	end
end
-->8
--physics


function apply_forces(ent)
	for f in all(ent.f_mgr.list) do
		ent.x+=f[1]*f[3]
		ent.y+=f[2]*f[3]
	end
end


function mk_vec(r,f)
	return {cos(r),sin(r),f}
end

function mk_force_mgr()
	return{
		list={},
		update=function(self)
			for l in all(self.list) do
				l[3]-=frict
				if(l[3]<=0)then
					del(self.list,l)
				end
			end
		end,
		add_f=function(self,a,m)
			add(self.list,mk_vec(a,m))
		end
	}
end

function circ_col(bub1,bub2)
	local x_diff=bub1.x-bub2.x
	local y_diff=bub1.y-bub2.y
	local diff=sqrt(
		x_diff*x_diff+y_diff*y_diff
	)
	
	return diff<bub1.r+bub2.r
end

function rev_vec_x(x,y)
	local a = atan2(x,y)
	local rev_a=abs(.5-a)
	return cos(rev_a)
end

function rev_vec_y(x,y)
	local a = atan2(x,y)
	local rev_a=abs(.75-a+.25)
	return sin(rev_a)
end
-->8
--bubble

function mk_bub_mgr()
	return{
		list={},
		b_max=1,
		b_timer=20,
		t=0,
		update=function(self)
			run_bub_spawn(self)
			for b in all (self.list) do
				b:update()
			end
			run_bub_cols(self.list)
		end,
		draw=function(self)
			for b in all (self.list) do
				local c=1
				if(b.hit) c=8
				b:draw(c)
			end
		end
	}
end

function run_bub_spawn(mgr)
	if(#mgr.list<mgr.b_max)then
		if(mgr.t>=mgr.b_timer)then
			local d = rnd(.3)+.1
			add(mgr.list,mk_bub(65,110,7))
			mgr.list[#mgr.list].f_mgr:add_f(d,4)
			mgr.t=0
		end
		mgr.t+=1
	end
end

function mk_bub(x,y,r)
	return {
		x=x,
		y=y,
		r=r,
		a=0,
		f_mgr=mk_force_mgr(),
		update=function(self)
			apply_forces(self)
			self.f_mgr:update()
			wall_col(self)
--			float(self)
		end,
		draw=function(self,c)
			circ(self.x,self.y,self.r,c)
			dr_dir_arr(self)
		end
	}
end

function bub_col(
	col_list,
	b_tbl,
	b
)
	for b2 in all (b_tbl) do
		local collided=(
			col_list[b][b2]
			or (
				col_list[b2]
				and col_list[b2][b]
			)
		)
		if(
			not collided
			and circ_col(b,b2)
			and b!=b2
		)
		then 
			b.hit=true
			add(col_list[b],b2)
			local new_f_tbl={}
			for f in all(b.f_mgr.list)do
				b.x-=f[1]*f[3]
				b.y-=f[2]*f[3]
				add(
					new_f_tbl,
					{-f[1],-f[2],f[3]/2}
				)
				add(
					b2.f_mgr.list,
					{f[1],f[2],f[3]/2}
				)
				del(b.f_mgr.list,f)
			end
			for f in all(new_f_tbl)do
				add(
					b.f_mgr.list,
					{f[1],f[2],f[3]}
				)
			end
		end
	end
end

function transfer_forces(b,b2)
	
	
	local new_f_tbl={}
	
	for f in all(b.f_mgr.list)do
		b.x-=f[1]*f[3]
		b.y-=f[2]*f[3]
		add(
			new_f_tbl,
			{-f[1],-f[2],f[3]/2}
		)
		add(
			b2.f_mgr.list,
			{f[1],f[2],f[3]/2}
		)
		del(b.f_mgr.list,f)
	end
	for f in all(new_f_tbl)do
		add(
			b.f_mgr.list,
			{f[1],f[2],f[3]}
		)
	end
end
function run_bub_cols(b_tbl)
	local col_list={}
	for b in all (b_tbl) do
		col_list[b]={}
		b.hit=false
		for b2 in all (b_tbl) do
			if(
				not (
					col_list[b][b2]
					or (
						col_list[b2]
						and col_list[b2][b]
					)
				)
				and circ_col(b,b2)
				and b!=b2
			)
			then 
				b.hit=true
				add(col_list[b],b2)
				local new_f_tbl={}
				for f in all(b.f_mgr.list)do
					b.x-=f[1]*f[3]
					b.y-=f[2]*f[3]
					add(
						new_f_tbl,
						{-f[1],-f[2],f[3]/2}
					)
					add(
						b2.f_mgr.list,
						{f[1],f[2],f[3]/2}
					)
					del(b.f_mgr.list,f)
				end
				for f in all(new_f_tbl)do
					add(
						b.f_mgr.list,
						{f[1],f[2],f[3]}
					)
				end
			end
		end
	end
end
		
function wall_col(ent)
	ceil_col(ent)
	flr_col(ent)
	l_wall_col(ent)
	r_wall_col(ent)
end

function ceil_col(ent)
--	if(ent.y-ent.r<p_ceil+1)then
--		ent.y=p_ceil+ent.r+1
--	end

	local col=ent.y-ent.r<p_ceil+1
	if(not col)return
	
	ent.y=p_ceil+ent.r+1
	for f in all(ent.f_mgr.list)do
		f[2]=rev_vec_y(f[1],f[2])
	end
end

function flr_col(ent)
--	if(ent.y+ent.r>p_flr-1)then
--		ent.y=p_flr-ent.r-1
--	end
	
	local col=ent.y+ent.r>p_flr-1
	if(not col)return
	
	ent.y=p_flr-ent.r-1
	for f in all(ent.f_mgr.list)do
		f[2]=rev_vec_y(f[1],f[2])
	end
end

function l_wall_col(ent)
 local col=ent.x-ent.r<p_l_wall
	if(not col)return
	
	ent.x=p_l_wall+ent.r
	for f in all(ent.f_mgr.list)do
		f[1]=rev_vec_x(f[1],f[2])
	end
end

function r_wall_col(ent)
	local col=ent.x+ent.r>p_r_wall
	if(not col)return
	
	ent.x=p_r_wall-ent.r-1
	for f in all(ent.f_mgr.list)do
		f[1]=rev_vec_x(f[1],f[2])
	end
	
--	if(ent.x+ent.r>p_r_wall)then
--		ent.x=p_r_wall-ent.r
--	end
end
-->8
--constants

frict=.02

p_ceil=8
p_l_wall=32
p_r_wall=96
p_flr=120

s_bub_r=3
m_bub_r=5
l_bub_r=7
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
