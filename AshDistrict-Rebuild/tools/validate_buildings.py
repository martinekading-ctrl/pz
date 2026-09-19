"""Validate and render the same metre-based furniture data used by Godot."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/"data/building_layouts.json").read_text(encoding="utf-8"))
def intersects(a,b):
    return all((a[0]<b[0]+b[2]-1e-6,a[0]+a[2]>b[0]+1e-6,a[1]<b[1]+b[3]-1e-6,a[1]+a[3]>b[1]+1e-6))
def zone(e):
    x,y=e["position_m"];w,h=e["size_m"];c=e["clearance_m"]
    return {"south":[x,y+h,w,c],"north":[x,y-c,w,c],"east":[x+w,y,c,h],"west":[x-c,y,c,h]}[e["front"]]
out=['<!doctype html><meta charset="utf-8"><title>建筑规范平面图</title><style>body{background:#19282a;color:#eee;font:16px sans-serif;padding:30px}svg{background:#f6f1e4}p{line-height:1.7}</style><h1>建筑布局规范 · 0.7</h1><p>尺寸为米。棕色：家具占地；绿色虚线：正面使用区；红点：入口。与游戏共用布局数据。</p>']
for key,b in data["buildings"].items():
    w,h=b["size_m"]
    out.append(f'<h2>{key} · {w} × {h} m</h2><svg width="{w*90+80}" height="{h*90+80}"><rect x="40" y="40" width="{w*90}" height="{h*90}" fill="#eee4cf" stroke="#324d50" stroke-width="5"/>')
    for e in b["items"]:
        x,y=e["position_m"];fw,fh=e["size_m"];box=[x,y,fw,fh];z=zone(e)
        assert x>=.1 and y>=.1 and x+fw<=w-.1 and y+fh<=h-.1,e["name"]
        gaps={"north":y,"south":h-y-fh,"west":x,"east":w-x-fw}
        if e["wall"]:assert .099<=gaps[e["wall"]]<=.201,e["name"]
        for other in b["items"]:
            if other is e:continue
            ob=other["position_m"]+other["size_m"]
            assert not intersects(box,ob),e["name"]+" overlap"
            assert not intersects(z,ob),e["name"]+" blocked operation"
        for r,fill,stroke in [(z,"#b4d6bb",'stroke="#318558" stroke-dasharray="5 4"'),(box,"#c5ac83",'stroke="#65553a"')]:
            out.append(f'<rect x="{40+r[0]*90}" y="{40+r[1]*90}" width="{r[2]*90}" height="{r[3]*90}" fill="{fill}" {stroke}/>')
        out.append(f'<text x="{40+(x+fw/2)*90}" y="{40+(y+fh/2)*90}" text-anchor="middle" font-size="12">{e["name"]}<tspan x="{40+(x+fw/2)*90}" dy="16">{fw} × {fh}</tspan></text>')
    ex,ey=b["entry_m"];out.append(f'<circle cx="{40+ex*90}" cy="{40+ey*90}" r="8" fill="#c34532"/></svg>')
out.append("<p>检查通过：占地边界、家具重叠、靠墙间距、使用区净空。门窗、贴图朝向与画面遮挡另做实机验收。</p>")
(ROOT/"docs/layout-plans.html").write_text("\n".join(out),encoding="utf-8")
print("GEOMETRY PASS: bounds, overlap, wall attachment, operation clearance")
