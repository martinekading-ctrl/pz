"""Build deterministic residential placements from the approved six-plan catalog."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
catalog=json.loads((ROOT/'data/house-catalog-v1.json').read_text(encoding='utf-8'))['designs']
world=json.loads((ROOT/'data/expansion-runtime-01.json').read_text(encoding='utf-8'))
choices=[0,1,4,2,5,3,1,0]
out=[]
for index,(raw,choice) in enumerate(zip(world['plots'][1:],choices)):
 d=catalog[choice]; w,h=d['w'],d['h']
 origin=[raw[0],raw[1]]
 outline=[[0,0],[w,0],[w,h],[0,h]]
 if d.get('lshape'): outline=[[0,0],[10,0],[10,4.6],[6,4.6],[6,8],[0,8]]
 doors=[]; segments=set(); items=[]
 def seg(a,b):
  a=tuple(round(v,3) for v in a);b=tuple(round(v,3) for v in b)
  segments.add(tuple(sorted([a,b])))
 def item(name,asset,x,y,sx,sy,front='south',height=.8):
  items.append(dict(name=name,cell=0,asset=asset,position_m=[round(x,3),round(y,3)],size_m=[sx,sy],height_m=height,front=front,wall='',clearance_m=.85,asset_scale=.82,desaturate=0,tint='ffffff',loot={'bandage':1} if '卧' in name or '浴' in name else {'food':2,'parts':1}))
 art='res://art/house_blue/prop-v08-'
 for name,x,y,rw,rh in d['rooms']:
  for a,b in [([x,y],[x+rw,y]),([x+rw,y],[x+rw,y+rh]),([x+rw,y+rh],[x,y+rh]),([x,y+rh],[x,y])]:seg(a,b)
  if d.get('side'): doors.append([[x+rw,y+rh*.65],[x+rw,y+rh*.65+1]])
  elif name=='车库': doors.append([[x,5.4],[x,6.4]])
  elif y==0:doors.append([[x+rw*.72-.5,y+rh],[x+rw*.72+.5,y+rh]])
  else:doors.append([[x+rw*.72-.5,y],[x+rw*.72+.5,y]])
  if '卧' in name: item(name+'床',art+'0.png',x+.3,y+.3,1.5,2,'east',.65)
  elif '卫' in name:item('浴室柜','res://art/residential_b01/bathroom-sink-v011.png',x+.3,y+.3,.6,.55,'south',.85)
  elif '藏' in name:item(name+'柜',art+'5.png',x+.25,y+.3,.6,1.0,'east',1.2)
  elif name=='车库':item('车库工具柜',art+'5.png',x+.3,y+.3,1.2,.6,'south',1.2)
  else:
   item(name+'沙发','res://art/residential_b01/sofa-v011.png',x+.25,y+.4,.8,1.6,'east',.8)
   if '厨' in name:
    item('厨房橱柜',art+'2.png',x+1.4 if d['id']=='H01' else x+rw-1.8,y+.2 if d['id']=='H03' or y==0 else y+rh-.8,1.5,.6,'south' if d['id']=='H03' or y==0 else 'north',.9)
    # Keep frontal access separate from the couch and room doorway.
 doors.append([[d['entry']-.5,h],[d['entry']+.5,h]])
 for i,a in enumerate(outline):seg(a,outline[(i+1)%len(outline)])
 def covers(a,b,p):
  return abs((b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]))<1e-5 and min(a[0],b[0])-1e-5<=p[0]<=max(a[0],b[0])+1e-5 and min(a[1],b[1])-1e-5<=p[1]<=max(a[1],b[1])+1e-5
 # Split collinear room edges on 0.1m intervals, merge afterwards to avoid double walls.
 ticks={}
 for a,b in segments:
  axis=0 if a[1]==b[1] else 1
  fixed=a[1-axis];lo=a[axis];hi=b[axis]
  for n in range(round(lo*100),round(hi*100),10):
   p=[0,0];p[axis]=(n+5)/100;p[1-axis]=fixed
   if any(covers(da,db,p) for da,db in doors):continue
   exterior=any(covers(oa,outline[(j+1)%len(outline)],p) for j,oa in enumerate(outline))
   ticks[(axis,fixed,n)]=exterior
 walls=[]
 for axis,fixed in sorted(set((a,f) for a,f,n in ticks)):
  nums=sorted(n for a,f,n in ticks if a==axis and f==fixed)
  groups=[]
  for n in nums:
   ext=ticks[(axis,fixed,n)]
   if groups and groups[-1][1]==n and groups[-1][2]==ext:groups[-1][1]=n+10
   else:groups.append([n,n+10,ext])
  for lo,hi,ext in groups:
   a=[0,0];b=[0,0];a[axis]=lo/100;b[axis]=hi/100;a[1-axis]=b[1-axis]=fixed
   walls.append({'a':a,'b':b,'exterior':ext})
 world['plots'][index+1]=origin+[int(w*2),int(h*2)]
 out.append(dict(id='R%02d'%(index+2),template=d['id'],title=d['name'],origin=origin,size_m=[w,h],entry=d['entry'],outline=outline,rooms=d['rooms'],walls=walls,doorways=doors[:-1],items=items,palette=['a6b4a0','d4c7ab','a68574','b3b9bc','d7cfb7','a5afa0'][choice],roof_style=d['roof'],roofs=[[0,0,w,h]] if not d.get('lshape') else [[0,0,10,4.6],[0,4.6,6,3.4]]))
# Connect actual entrances to the nearest street without crossing house footprints.
import math
world['routes']=[r for r in world['routes'] if not r.get('id','').startswith('house-access-')]
roads=[r for r in world['routes'] if r['kind'] in ('road','street')]
def length(a,b):return math.dist(a,b)
def clear(a,b):
 for n in range(1,max(2,int(length(a,b)*4))):
  t=n/max(2,int(length(a,b)*4));p=[a[i]+(b[i]-a[i])*t for i in (0,1)]
  for x,y,w,h in world['plots']:
   if x-1<p[0]<x+w+1 and y-1<p[1]<y+h+1:return False
 return True
for house in out:
 x,y=house['origin'];w,h=[v*2 for v in house['size_m']]
 door=[x+house['entry']*2,y+h];start=[door[0],door[1]+3]
 candidates=[]
 for route in roads:
  for a,b in zip(route['points'],route['points'][1:]):
   dx,dy=b[0]-a[0],b[1]-a[1]
   t=max(0,min(1,((start[0]-a[0])*dx+(start[1]-a[1])*dy)/(dx*dx+dy*dy)))
   end=[a[0]+t*dx,a[1]+t*dy]
   for mid in [[],[[x-3,start[1]],[x-3,end[1]]],[[x+w+3,start[1]],[x+w+3,end[1]]]]:
    path=[start]+mid+[end]
    if all(clear(a,b) for a,b in zip(path,path[1:])):candidates.append((sum(length(a,b) for a,b in zip(path,path[1:])),path))
 assert candidates,house['id']+' has no street access'
 path=min(candidates,key=lambda p:p[0])[1]
 world['routes'].append(dict(id='house-access-'+house['id'],kind='path',width=2.4,points=[door]+path))
(ROOT/'data/residential-placements.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'data/expansion-runtime-01.json').write_text(json.dumps(world,ensure_ascii=False,indent=2),encoding='utf-8')
print('Residential placements:',len(out), 'templates:',sorted(set(x['template'] for x in out)))
