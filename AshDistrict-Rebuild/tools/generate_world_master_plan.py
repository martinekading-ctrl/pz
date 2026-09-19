from __future__ import annotations

import csv
import json
import math
import random
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
DATA = ROOT / "data"
WORLD_M = 1024
SEED = 140216
PLAN_VERSION = 4

FONT_PATH = r"C:\Windows\Fonts\msyh.ttc"


def font(size: int, bold: bool = False):
    path = r"C:\Windows\Fonts\msyhbd.ttc" if bold else FONT_PATH
    return ImageFont.truetype(path, size)


ZONES = [
    {"id": "Z01", "name": "西北森林与湖泊", "bounds": [0, 0, 340, 320], "count": 12, "color": "#476d46", "pace": "低压探索"},
    {"id": "Z02", "name": "北部农场带", "bounds": [340, 0, 700, 330], "count": 22, "color": "#78914d", "pace": "补给与远景"},
    {"id": "Z03", "name": "东北公路服务区", "bounds": [700, 0, 1024, 330], "count": 17, "color": "#837b64", "pace": "中压交通节点"},
    {"id": "Z04", "name": "西部老旧住宅区", "bounds": [0, 320, 340, 650], "count": 28, "color": "#879858", "pace": "住宅搜刮"},
    {"id": "Z05", "name": "中央商业中心", "bounds": [340, 330, 700, 660], "count": 30, "color": "#9e795d", "pace": "高密度高风险"},
    {"id": "Z06", "name": "东部学校与市政区", "bounds": [700, 330, 1024, 660], "count": 16, "color": "#75939e", "pace": "地标与任务"},
    {"id": "Z07", "name": "西南工业与铁路区", "bounds": [0, 650, 330, 1024], "count": 18, "color": "#6d6b65", "pace": "高价值高威胁"},
    {"id": "Z08", "name": "南部老城区", "bounds": [330, 660, 680, 1024], "count": 25, "color": "#917c66", "pace": "巷道与密集住宅"},
    {"id": "Z09", "name": "东南郊区与拖车营地", "bounds": [680, 660, 1024, 1024], "count": 12, "color": "#799563", "pace": "低密度撤离路线"},
]

ROADS = [
    {"id": "R01", "name": "东北州际公路", "class": "highway", "width": 18, "points": [[680, -20], [755, 70], [840, 145], [930, 190], [1045, 220]]},
    {"id": "R02", "name": "余烬大道", "class": "arterial", "width": 14, "points": [[-20, 500], [1045, 500]]},
    {"id": "R03", "name": "中央大道", "class": "arterial", "width": 14, "points": [[520, -20], [520, 1045]]},
    {"id": "R04", "name": "湖畔乡道", "class": "rural", "width": 8, "points": [[-20, 305], [85, 270], [200, 245], [340, 235], [520, 235]]},
    {"id": "R05", "name": "农庄北路", "class": "rural", "width": 8, "points": [[340, 95], [520, 95], [700, 120]]},
    {"id": "R06", "name": "农庄南路", "class": "rural", "width": 8, "points": [[340, 275], [520, 275], [700, 280]]},
    {"id": "R07", "name": "服务区前路", "class": "collector", "width": 10, "points": [[700, 275], [825, 275], [950, 275], [1025, 300]]},
    {"id": "R08", "name": "高速出口路", "class": "collector", "width": 10, "points": [[825, 275], [825, 205], [855, 155]]},
    {"id": "R09", "name": "西区北街", "class": "collector", "width": 10, "points": [[20, 365], [340, 365]]},
    {"id": "R10", "name": "西区南街", "class": "collector", "width": 10, "points": [[20, 620], [340, 620]]},
    {"id": "R11", "name": "白桦街", "class": "local", "width": 7, "points": [[95, 365], [95, 620]]},
    {"id": "R12", "name": "教堂街", "class": "local", "width": 7, "points": [[245, 365], [245, 620]]},
    {"id": "R13", "name": "市场街", "class": "collector", "width": 10, "points": [[340, 375], [700, 375]]},
    {"id": "R14", "name": "车站街", "class": "collector", "width": 10, "points": [[340, 625], [700, 625]]},
    {"id": "R15", "name": "商业西街", "class": "local", "width": 8, "points": [[390, 330], [390, 660]]},
    {"id": "R16", "name": "商业东街", "class": "local", "width": 8, "points": [[645, 330], [645, 660]]},
    {"id": "R17", "name": "校园北路", "class": "collector", "width": 10, "points": [[700, 375], [1025, 375]]},
    {"id": "R18", "name": "校园南路", "class": "collector", "width": 10, "points": [[700, 625], [1025, 625]]},
    {"id": "R19", "name": "医院路", "class": "local", "width": 8, "points": [[770, 375], [770, 625]]},
    {"id": "R20", "name": "市政路", "class": "local", "width": 8, "points": [[950, 375], [950, 625]]},
    {"id": "R21", "name": "工业北路", "class": "collector", "width": 11, "points": [[-20, 705], [330, 705]]},
    {"id": "R22", "name": "工业南路", "class": "collector", "width": 11, "points": [[-20, 900], [330, 900]]},
    {"id": "R23", "name": "物流大道", "class": "local", "width": 9, "points": [[285, 650], [285, 1045]]},
    {"id": "R24", "name": "旧城北街", "class": "collector", "width": 10, "points": [[330, 705], [680, 705]]},
    {"id": "R25", "name": "旧城中街", "class": "collector", "width": 10, "points": [[330, 835], [680, 835]]},
    {"id": "R26", "name": "旧城南街", "class": "collector", "width": 10, "points": [[330, 980], [680, 980]]},
    {"id": "R27", "name": "砖厂巷", "class": "local", "width": 7, "points": [[385, 850], [385, 1025]]},
    {"id": "R28", "name": "钟楼街", "class": "local", "width": 7, "points": [[630, 660], [630, 1025]]},
    {"id": "R29", "name": "南郊连接路", "class": "collector", "width": 10, "points": [[720, 650], [720, 1045]]},
    {"id": "R30", "name": "东南郊环路", "class": "collector", "width": 10, "points": [[720, 710], [920, 710], [990, 780], [990, 930], [925, 995], [720, 995]]},
    {"id": "R31", "name": "拖车营地路", "class": "local", "width": 7, "points": [[720, 850], [990, 850]]},
]

RAIL_POINTS = [[-20, 920], [190, 875], [360, 835], [530, 800]]

ROAD_FEATURES = [
    {"id": "B01", "type": "stream_bridge", "road": "R09", "center_m": [86, 365]},
    {"id": "B02", "type": "stream_bridge", "road": "R02", "center_m": [72, 500]},
    {"id": "B03", "type": "stream_bridge", "road": "R10", "center_m": [84, 620]},
    {"id": "X01", "type": "rail_crossing", "road": "R22", "center_m": [73, 900]},
    {"id": "X02", "type": "rail_crossing", "road": "R23", "center_m": [285, 853]},
    {"id": "X03", "type": "rail_crossing", "road": "R25", "center_m": [360, 835]},
    {"id": "X04", "type": "rail_crossing", "road": "R03", "center_m": [520, 802]},
    {"id": "J01", "type": "signalized_intersection", "roads": ["R02", "R03"], "center_m": [520, 500]},
    {"id": "J02", "type": "highway_exit", "roads": ["R01", "R08"], "center_m": [855, 155]},
]

RESERVED_AREAS = [
    {"id": "A01", "name": "湖泊与湿地", "type": "water", "district": "Z01", "bounds": [25, 15, 215, 190], "blocks_buildings": True},
    {"id": "A02", "name": "社区公园与儿童游乐场", "type": "park", "district": "Z04", "bounds": [110, 515, 225, 600], "blocks_buildings": True},
    {"id": "A03", "name": "校园运动场", "type": "sports_field", "district": "Z06", "bounds": [800, 520, 930, 610], "blocks_buildings": True},
    {"id": "A04", "name": "市立墓园", "type": "cemetery", "district": "Z06", "bounds": [960, 520, 1010, 610], "blocks_buildings": True},
    {"id": "A05", "name": "临时撤离营地", "type": "evacuation_camp", "district": "Z09", "bounds": [760, 865, 900, 965], "blocks_buildings": True},
    {"id": "A06", "name": "林业采伐场", "type": "logging_site", "district": "Z01", "bounds": [220, 25, 320, 95], "blocks_buildings": True},
    {"id": "A07", "name": "高速检查站", "type": "military_checkpoint", "district": "Z03", "bounds": [875, 205, 935, 250], "blocks_buildings": True},
    {"id": "A08", "name": "垃圾填埋场", "type": "landfill", "district": "Z07", "bounds": [25, 735, 130, 840], "blocks_buildings": True},
]

MAP_DATA_LAYERS = [
    "room_definitions", "loot_distributions", "zombie_heatmap", "vehicle_spawn_zones", "parking_stalls",
    "foraging_zones", "animal_zones", "story_zones", "utility_grid", "pedestrian_network",
    "business_signage", "map_reveal_items", "basement_candidates", "interior_state_seed", "seasonal_overlays",
]

EXPANSION_GATES = [
    {"id": "G01", "edge": "north", "road": "R03", "center_m": [520, 0], "future_region": "北部农林扩展"},
    {"id": "G02", "edge": "north", "road": "R01", "center_m": [697, 0], "future_region": "州际公路北段"},
    {"id": "G03", "edge": "east", "road": "R01", "center_m": [1024, 215], "future_region": "区域公路与机场扩展"},
    {"id": "G04", "edge": "east", "road": "R02", "center_m": [1024, 500], "future_region": "东部城市扩展"},
    {"id": "G05", "edge": "west", "road": "R04", "center_m": [0, 298], "future_region": "西部林区扩展"},
    {"id": "G06", "edge": "west", "road": "R02", "center_m": [0, 500], "future_region": "西部河谷小镇"},
    {"id": "G07", "edge": "west", "road": "R21", "center_m": [0, 705], "future_region": "工业与铁路扩展"},
    {"id": "G08", "edge": "south", "road": "R03", "center_m": [520, 1024], "future_region": "南部监狱与封锁区"},
    {"id": "G09", "edge": "south", "road": "R29", "center_m": [720, 1024], "future_region": "南部乡镇扩展"},
]

TYPE_PLAN = {
    "Z01": ["forest_cabin"] * 5 + ["detached_house"] * 2 + ["ranger_station", "visitor_center", "campground_service", "boathouse", "maintenance_shed"],
    "Z02": ["farmhouse"] * 7 + ["barn"] * 5 + ["rural_outbuilding"] * 4 + ["detached_house"] * 2 + ["feed_store", "farm_supply", "veterinary_clinic", "grain_silo"],
    "Z03": ["motel_unit"] * 4 + ["detached_house"] * 3 + ["gas_station", "diner", "convenience_store", "auto_shop", "car_wash", "truck_stop", "fast_food", "warehouse", "self_storage", "radio_station"],
    "Z04": ["detached_house"] * 18 + ["duplex"] * 4 + ["apartment_lowrise"] * 2 + ["corner_shop", "laundromat", "pharmacy", "daycare"],
    "Z05": ["office_tower"] * 3 + ["apartment_tower"] * 2 + ["hotel_highrise", "shopping_mall", "supermarket", "department_store", "parking_garage"] + ["bank", "pharmacy", "gun_store"] + ["restaurant"] * 2 + ["cafe", "bar", "bookstore", "hair_salon", "liquor_store"] + ["clothing_store", "electronics_store", "hardware_store"] + ["office_midrise"] * 2 + ["mixed_use"] * 2 + ["cinema", "gym", "bus_station"],
    "Z06": ["hospital", "medical_clinic", "police", "fire_station", "town_hall", "courthouse", "library", "elementary_school", "high_school", "sports_center", "public_pool", "community_center", "church", "nursing_home", "daycare", "county_jail"],
    "Z07": ["warehouse"] * 3 + ["factory"] * 2 + ["garage"] * 2 + ["logistics_depot", "industrial_office", "rail_station", "power_substation", "water_treatment", "scrapyard", "construction_yard", "cold_storage", "fuel_depot", "lumber_yard", "waste_transfer"],
    "Z08": ["rowhouse"] * 8 + ["detached_house"] * 6 + ["apartment_lowrise"] * 2 + ["grocery_store", "post_office", "bakery", "restaurant", "bar", "church", "funeral_home", "pawn_shop", "small_hotel"],
    "Z09": ["trailer"] * 6 + ["detached_house"] * 3 + ["self_storage", "campground_service", "rural_clinic"],
}

ROOFS = ["双坡", "四坡", "L形双坡", "交叉双坡", "平顶", "单坡", "带前廊双坡", "车库组合顶", "低坡顶", "谷仓顶", "错层双坡", "小塔楼组合顶"]
FACADES = ["蓝灰木板", "白色木板", "红砖", "旧灰砖", "浅黄灰泥", "深绿木板", "米色石材", "金属挂板"]
PALETTES = ["松绿", "雨灰", "土褐", "旧蓝", "砖红", "奶油", "暗黄", "铁锈", "浅青", "炭灰", "橄榄", "褪白"]
FEATURES = ["前廊", "侧车库", "后露台", "凸窗", "烟囱", "围栏院", "角门廊", "工具棚", "双入口", "雨棚", "侧翼扩建", "无附属结构"]
CONDITIONS = ["维护良好", "轻度老化", "杂草侵占", "窗板封闭", "屋顶轻损", "废弃", "火灾熏黑", "临时加固"]
ROOM_TWISTS = ["独立餐厅", "开放厨房", "狭长走廊", "后置卧室", "前置客厅", "双卫生间", "储藏间", "洗衣房", "车库内门", "阁楼入口", "封闭阳台", "转角厨房"]
RESIDENTIAL_SHAPES = ["矩形", "L形左翼", "L形右翼", "前凸形", "后凸形", "主屋加侧翼", "错位双矩形", "T形"]
NONRESIDENTIAL_SHAPES = ["矩形", "L形左翼", "L形右翼", "前凸形", "后凸形", "主屋加侧翼", "错位双矩形", "T形", "U形"]
FLOORPLAN_FAMILIES = ["中央走廊", "侧走廊", "开放核心", "前厅分流", "L形动线", "纵深串联", "双区分隔", "环形动线"]
WINDOW_PATTERNS = ["前二侧一", "前三侧二", "前一侧二", "前二侧三", "转角窗组", "前窗不对称", "窄窗组合", "宽窗加侧窗", "凸窗组合", "高低窗组合"]
STAIR_PATTERNS = ["无楼梯", "门厅直梯", "中央折梯", "后部直梯", "侧墙折梯", "客厅转角梯"]
TYPE_NAMES = {
    "detached_house": "独栋住宅", "duplex": "双拼住宅", "rowhouse": "联排住宅", "apartment_lowrise": "低层公寓", "apartment_tower": "公寓塔楼",
    "forest_cabin": "林间小屋", "farmhouse": "农舍", "trailer": "拖车住宅", "motel_unit": "汽车旅馆",
    "office_tower": "高层写字楼", "office_midrise": "中层写字楼", "mixed_use": "商住混合楼", "hotel_highrise": "高层酒店",
    "shopping_mall": "购物中心", "supermarket": "大型超市", "department_store": "百货商场", "parking_garage": "停车楼",
    "hospital": "综合医院", "medical_clinic": "社区诊所", "rural_clinic": "乡村诊所", "pharmacy": "药店",
    "police": "警察局", "fire_station": "消防站", "town_hall": "市政厅", "courthouse": "法院", "library": "图书馆",
    "elementary_school": "小学", "high_school": "中学", "sports_center": "体育中心", "public_pool": "公共泳池",
    "community_center": "社区中心", "church": "教堂", "nursing_home": "养老院", "daycare": "托儿所", "post_office": "邮局",
    "bus_station": "公交总站", "gas_station": "加油站", "auto_shop": "汽车维修店", "rail_station": "货运站",
    "warehouse": "仓库", "factory": "工厂", "logistics_depot": "物流中心", "power_substation": "变电站", "water_treatment": "净水厂",
    "visitor_center": "游客中心", "ranger_station": "护林站", "veterinary_clinic": "兽医诊所",
    "bakery": "面包店", "bank": "银行", "bar": "酒吧", "barn": "谷仓", "boathouse": "船屋",
    "cafe": "咖啡馆", "campground_service": "露营服务站", "car_wash": "洗车店", "cinema": "电影院",
    "clothing_store": "服装店", "cold_storage": "冷库", "construction_yard": "建材场",
    "convenience_store": "便利店", "corner_shop": "街角商店", "diner": "公路餐馆",
    "electronics_store": "电器店", "farm_supply": "农资店", "fast_food": "快餐店", "feed_store": "饲料店",
    "fuel_depot": "燃料库", "funeral_home": "殡仪馆", "garage": "维修车库", "grain_silo": "粮仓筒仓",
    "grocery_store": "社区食品店", "gym": "健身房", "hardware_store": "五金店", "industrial_office": "工业办公室",
    "laundromat": "自助洗衣店", "maintenance_shed": "维护站", "pawn_shop": "当铺", "restaurant": "餐厅",
    "rural_outbuilding": "农用附属房", "scrapyard": "废车场", "self_storage": "迷你仓", "small_hotel": "老城旅馆",
    "truck_stop": "卡车服务站",
    "gun_store": "枪械与狩猎店", "liquor_store": "酒类商店", "bookstore": "书店", "hair_salon": "理发店",
    "county_jail": "县拘留所", "radio_station": "广播通信站", "lumber_yard": "木材场", "waste_transfer": "垃圾转运站",
}

LANDMARK_TYPES = {
    "office_tower", "apartment_tower", "hotel_highrise", "shopping_mall", "supermarket", "parking_garage",
    "hospital", "police", "fire_station", "town_hall", "courthouse", "elementary_school", "high_school",
    "sports_center", "bus_station", "logistics_depot", "power_substation", "water_treatment", "rail_station",
}


def life_system(building_type):
    if category(building_type) == "residential":
        return "居住"
    groups = {
        "医疗": {"hospital", "medical_clinic", "rural_clinic", "veterinary_clinic", "pharmacy", "nursing_home"},
        "治安消防": {"police", "fire_station", "county_jail"},
        "教育公共": {"town_hall", "courthouse", "library", "elementary_school", "high_school", "community_center", "daycare", "post_office", "church", "radio_station", "ranger_station"},
        "食品补给": {"supermarket", "grocery_store", "convenience_store", "diner", "restaurant", "cafe", "bar", "bakery", "fast_food"},
        "零售服务": {"shopping_mall", "department_store", "bank", "clothing_store", "electronics_store", "hardware_store", "corner_shop", "laundromat", "pawn_shop", "funeral_home", "feed_store", "farm_supply", "gun_store", "liquor_store", "bookstore", "hair_salon"},
        "交通车辆": {"parking_garage", "bus_station", "gas_station", "auto_shop", "car_wash", "truck_stop", "rail_station", "self_storage"},
        "休闲文化": {"cinema", "gym", "sports_center", "public_pool", "visitor_center", "campground_service", "boathouse"},
        "工业办公": {"office_tower", "office_midrise", "mixed_use", "hotel_highrise", "small_hotel"},
        "工业物流": {"warehouse", "factory", "garage", "logistics_depot", "industrial_office", "scrapyard", "construction_yard", "cold_storage", "lumber_yard", "waste_transfer"},
        "基础设施": {"power_substation", "water_treatment", "fuel_depot", "maintenance_shed"},
        "农业生产": {"barn", "rural_outbuilding", "grain_silo"},
    }
    for name, types in groups.items():
        if building_type in types:
            return name
    return "其他"


def dist_point_segment(p, a, b):
    px, py = p; ax, ay = a; bx, by = b
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay), a
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    q = (ax + t * dx, ay + t * dy)
    return math.hypot(px - q[0], py - q[1]), q


def nearest_road(point):
    best = (1e9, None, None, None)
    for road in ROADS:
        pts = road["points"]
        for a, b in zip(pts, pts[1:]):
            d, q = dist_point_segment(point, a, b)
            if d < best[0]:
                best = (d, road, a, b)
    return best


def category(building_type):
    if building_type in {"detached_house", "duplex", "rowhouse", "apartment_lowrise", "apartment_tower", "forest_cabin", "farmhouse", "trailer", "motel_unit"}:
        return "residential"
    if building_type in {
        "corner_shop", "office_tower", "office_midrise", "mixed_use", "hotel_highrise", "small_hotel",
        "shopping_mall", "supermarket", "department_store", "parking_garage", "bank", "pharmacy",
        "restaurant", "cafe", "bar", "clothing_store", "electronics_store", "hardware_store", "cinema", "gym",
        "bus_station", "diner", "convenience_store", "gas_station", "auto_shop", "car_wash", "truck_stop",
        "fast_food", "self_storage", "laundromat", "feed_store", "farm_supply", "grocery_store", "bakery",
        "funeral_home", "pawn_shop", "gun_store", "liquor_store", "bookstore", "hair_salon",
    }:
        return "commercial"
    if building_type in {
        "hospital", "medical_clinic", "rural_clinic", "veterinary_clinic", "police", "fire_station",
        "town_hall", "courthouse", "library", "elementary_school", "high_school", "sports_center",
        "public_pool", "community_center", "church", "nursing_home", "daycare", "post_office", "county_jail", "radio_station",
    }:
        return "civic"
    if building_type in {
        "warehouse", "factory", "garage", "logistics_depot", "industrial_office", "rail_station",
        "power_substation", "water_treatment", "scrapyard", "construction_yard", "cold_storage", "fuel_depot", "lumber_yard", "waste_transfer",
    }:
        return "industrial"
    if building_type in {"barn", "rural_outbuilding", "grain_silo"}:
        return "rural"
    return "special"


def lot_metrics(building_type, rng):
    c = category(building_type)
    ranges = {
        "residential": ((20, 32), (24, 38), 0.62),
        "commercial": ((24, 42), (26, 46), 0.72),
        "civic": ((24, 38), (26, 42), 0.72),
        "industrial": ((34, 52), (36, 58), 0.76),
        "rural": ((38, 60), (42, 66), 0.58),
        "special": ((34, 62), (38, 70), 0.68),
    }
    xr, yr, fill = ranges[c]
    landmark_ranges = {
        "shopping_mall": ((58, 72), (56, 72), 0.80),
        "hospital": ((62, 78), (58, 74), 0.78),
        "high_school": ((56, 72), (52, 70), 0.75),
        "supermarket": ((48, 62), (46, 60), 0.80),
        "parking_garage": ((45, 58), (44, 58), 0.82),
        "department_store": ((44, 58), (42, 56), 0.80),
        "sports_center": ((48, 64), (46, 62), 0.76),
        "water_treatment": ((46, 60), (46, 62), 0.76),
        "logistics_depot": ((44, 58), (44, 60), 0.80),
        "factory": ((40, 54), (42, 58), 0.80),
        "office_tower": ((34, 46), (34, 48), 0.76),
        "apartment_tower": ((34, 46), (36, 50), 0.74),
        "hotel_highrise": ((38, 50), (40, 54), 0.76),
    }
    if building_type in landmark_ranges:
        xr, yr, fill = landmark_ranges[building_type]
    lot_w, lot_h = rng.uniform(*xr), rng.uniform(*yr)
    return lot_w, lot_h, lot_w * fill, lot_h * fill


def floor_count(building_type, serial):
    if building_type == "office_tower":
        return [8, 10, 12][serial % 3]
    if building_type == "apartment_tower":
        return [7, 9][serial % 2]
    if building_type == "hotel_highrise":
        return 8
    fixed = {
        "hospital": 4, "parking_garage": 4, "town_hall": 3, "courthouse": 3,
        "shopping_mall": 2, "department_store": 2, "high_school": 2, "elementary_school": 2,
        "small_hotel": 2, "sports_center": 2,
    }
    if building_type in fixed:
        return fixed[building_type]
    if building_type in {"office_midrise", "mixed_use"}:
        return 3 + serial % 3
    if building_type == "apartment_lowrise":
        return 2 + serial % 2
    if building_type in {"detached_house", "duplex", "rowhouse"} and serial % 4 == 0:
        return 2
    return 1


def placement_priority(building_type):
    priorities = {
        "hospital": 100, "shopping_mall": 98, "high_school": 96, "water_treatment": 94,
        "logistics_depot": 92, "factory": 90, "sports_center": 88, "supermarket": 86,
        "parking_garage": 84, "department_store": 82, "hotel_highrise": 80,
        "apartment_tower": 78, "office_tower": 76,
    }
    defaults = {"industrial": 60, "civic": 55, "rural": 50, "commercial": 40, "special": 35, "residential": 20}
    return priorities.get(building_type, defaults[category(building_type)])


def parcel_system_data(building_type, parcel_category, floors, district, serial):
    parking_overrides = {
        "shopping_mall": 48, "supermarket": 36, "hospital": 42, "high_school": 28,
        "elementary_school": 20, "office_tower": 24, "apartment_tower": 20,
        "hotel_highrise": 24, "parking_garage": 80, "sports_center": 24,
        "factory": 14, "logistics_depot": 18, "bus_station": 12,
    }
    parking_defaults = {"residential": 2, "commercial": 6, "civic": 8, "industrial": 8, "rural": 3, "special": 3}
    parking_spaces = parking_overrides.get(building_type, parking_defaults[parcel_category])
    if district == "Z05" and building_type != "parking_garage":
        parking_strategy = "shared_parking_garage"
    elif parcel_category in {"commercial", "civic", "industrial"}:
        parking_strategy = "on_lot_and_service_lane"
    else:
        parking_strategy = "driveway_or_curb"

    loading_types = {
        "shopping_mall", "supermarket", "department_store", "hospital", "hotel_highrise", "warehouse",
        "factory", "logistics_depot", "cold_storage", "lumber_yard", "waste_transfer", "bus_station",
    }
    basement_types = {
        "office_tower", "apartment_tower", "hotel_highrise", "hospital", "shopping_mall", "parking_garage",
        "town_hall", "courthouse", "county_jail",
    }
    random_home_basement = parcel_category == "residential" and building_type not in {"trailer", "motel_unit"} and serial % 3 == 0
    basement_levels = 1 if building_type in basement_types or random_home_basement else 0
    if building_type in {"office_tower", "apartment_tower", "hotel_highrise", "hospital"}:
        elevator_count = 2
    elif floors >= 4:
        elevator_count = 1
    else:
        elevator_count = 0
    stairwell_count = 2 if floors >= 3 else 1 if floors == 2 or basement_levels else 0

    zombie_base = {"residential": 1.0, "commercial": 1.8, "civic": 1.7, "industrial": 1.3, "rural": 0.5, "special": 0.7}[parcel_category]
    if building_type in {"shopping_mall", "supermarket", "hospital", "high_school", "bus_station"}:
        zombie_base += 1.2
    vehicle_profile = {
        "residential": "resident_cars", "commercial": "customer_and_staff", "civic": "public_service",
        "industrial": "work_vans_and_trucks", "rural": "farm_vehicles", "special": "rare_or_none",
    }[parcel_category]
    if building_type in {"police", "fire_station", "hospital", "bus_station", "radio_station"}:
        vehicle_profile = building_type + "_fleet"
    utility_profile = "municipal_water_power_sewer"
    if district in {"Z01", "Z02", "Z09"}:
        utility_profile = "well_septic_grid_power"

    return {
        "room_definition_set": f"{building_type}_rooms_v1",
        "loot_profile": f"{building_type}_loot_v1",
        "zombie_heat_weight": round(zombie_base, 1),
        "vehicle_spawn_profile": vehicle_profile,
        "parking_spaces_planned": parking_spaces,
        "parking_strategy": parking_strategy,
        "loading_bays": 2 if building_type in {"shopping_mall", "supermarket", "factory", "logistics_depot"} else 1 if building_type in loading_types else 0,
        "service_entrance_required": building_type in loading_types or parcel_category in {"civic", "industrial"},
        "basement_levels": basement_levels,
        "z_min": -basement_levels,
        "z_max": floors - 1,
        "elevator_count": elevator_count,
        "stairwell_count": stairwell_count,
        "utility_profile": utility_profile,
        "foraging_profile": "urban_none" if district in {"Z05", "Z06"} else "forest" if district == "Z01" else "farmland" if district == "Z02" else "suburban",
        "story_zone": f"{district}_{building_type}",
        "business_name_id": f"BIZ-{serial:03d}" if parcel_category == "commercial" else "",
        "map_reveal_item": building_type in LANDMARK_TYPES or parcel_category == "commercial",
        "interior_state_seed": SEED * 1000 + serial,
    }


def generate_parcels():
    rng = random.Random(SEED)
    parcels = []
    serial = 1
    residential_serial = 1
    nonresidential_serial = 1
    for zone in ZONES:
        x0, y0, x1, y1 = zone["bounds"]
        types = list(TYPE_PLAN[zone["id"]])
        assert len(types) == zone["count"]
        max_access = 78 if zone["id"] not in {"Z01", "Z02"} else 112
        rng.shuffle(types)
        types.sort(key=placement_priority, reverse=True)
        placed_lots = []
        for local_index, building_type in enumerate(types, 1):
            accepted = None
            for attempt in range(12000):
                lot_w, lot_h, build_w, build_h = lot_metrics(building_type, rng)
                provisional = (rng.uniform(x0 + 5, x1 - 5), rng.uniform(y0 + 5, y1 - 5))
                distance, road, a, b = nearest_road(provisional)
                horizontal = abs(b[0] - a[0]) >= abs(b[1] - a[1])
                rotation = 0 if horizontal else 90
                effective_w, effective_h = (lot_w, lot_h) if rotation == 0 else (lot_h, lot_w)
                if x1 - x0 <= effective_w + 8 or y1 - y0 <= effective_h + 8:
                    continue
                point = (
                    rng.uniform(x0 + effective_w / 2 + 4, x1 - effective_w / 2 - 4),
                    rng.uniform(y0 + effective_h / 2 + 4, y1 - effective_h / 2 - 4),
                )
                distance, road, a, b = nearest_road(point)
                horizontal = abs(b[0] - a[0]) >= abs(b[1] - a[1])
                rotation = 0 if horizontal else 90
                effective_w, effective_h = (lot_w, lot_h) if rotation == 0 else (lot_h, lot_w)
                if category(building_type) == "residential" and road["class"] in {"highway", "arterial"}:
                    continue
                if (
                    point[0] - effective_w / 2 < x0 + 4
                    or point[0] + effective_w / 2 > x1 - 4
                    or point[1] - effective_h / 2 < y0 + 4
                    or point[1] + effective_h / 2 > y1 - 4
                ):
                    continue
                candidate_box = (
                    point[0] - effective_w / 2 - 3,
                    point[1] - effective_h / 2 - 3,
                    point[0] + effective_w / 2 + 3,
                    point[1] + effective_h / 2 + 3,
                )
                reserved_overlap = False
                for area in RESERVED_AREAS:
                    if not area["blocks_buildings"] or area["district"] != zone["id"]:
                        continue
                    ax0, ay0, ax1, ay1 = area["bounds"]
                    if candidate_box[0] < ax1 and candidate_box[2] > ax0 and candidate_box[1] < ay1 and candidate_box[3] > ay0:
                        reserved_overlap = True
                        break
                if reserved_overlap:
                    continue
                road_clearance = road["width"] * 0.5 + min(effective_w, effective_h) * 0.38 + 2
                if distance < road_clearance or distance > max_access:
                    continue
                if zone["id"] == "Z01" and math.hypot(point[0] - 118, point[1] - 95) < 82 + max(effective_w, effective_h) * 0.5:
                    continue
                overlaps = False
                for other in placed_lots:
                    if abs(point[0] - other[0]) < (effective_w + other[2]) * 0.5 + 4 and abs(point[1] - other[1]) < (effective_h + other[3]) * 0.5 + 4:
                        overlaps = True
                        break
                if overlaps:
                    continue
                accepted = (point, lot_w, lot_h, build_w, build_h, rotation, distance, road, a, b, effective_w, effective_h)
                break
            if accepted is None:
                raise RuntimeError(f"Could not place {zone['id']} item {local_index}/{zone['count']}")
            point, lot_w, lot_h, build_w, build_h, rotation, distance, road, a, b, effective_w, effective_h = accepted
            placed_lots.append((point[0], point[1], effective_w, effective_h))
            qdist, q = dist_point_segment(point, a, b)
            dx, dy = q[0] - point[0], q[1] - point[1]
            entrance = "东" if abs(dx) > abs(dy) and dx > 0 else "西" if abs(dx) > abs(dy) else "南" if dy > 0 else "北"
            parcel_category = category(building_type)
            floors = floor_count(building_type, serial)
            if parcel_category == "residential":
                plan_number = residential_serial
                base_plan = f"H{plan_number:03d}"
                footprint_shape = RESIDENTIAL_SHAPES[(plan_number - 1) % len(RESIDENTIAL_SHAPES)]
                floorplan_family = FLOORPLAN_FAMILIES[(plan_number * 3 + int(zone["id"][1:])) % len(FLOORPLAN_FAMILIES)]
                if building_type in {"trailer", "motel_unit"}:
                    bedrooms = 1
                elif building_type in {"forest_cabin", "rowhouse"}:
                    bedrooms = 1 + (plan_number % 2)
                elif building_type in {"apartment_lowrise", "apartment_tower", "farmhouse", "duplex"}:
                    bedrooms = 2 + (plan_number % 3)
                else:
                    bedrooms = 1 + (plan_number % 4)
                bathrooms = 2 if bedrooms >= 3 and plan_number % 2 == 0 else 1
                residential_serial += 1
            else:
                plan_number = nonresidential_serial
                base_plan = f"N{plan_number:03d}"
                footprint_shape = NONRESIDENTIAL_SHAPES[(plan_number * 5 + serial) % len(NONRESIDENTIAL_SHAPES)]
                floorplan_family = f"{building_type}-功能分区-{plan_number:02d}"
                bedrooms = 0
                bathrooms = 1 + int(build_w * build_h > 1100)
                nonresidential_serial += 1
            entrance_offset = round(-0.32 + ((serial * 37 + local_index * 11) % 65) / 100.0, 2)
            window_pattern = WINDOW_PATTERNS[(serial * 3 + local_index) % len(WINDOW_PATTERNS)]
            stair_pattern = STAIR_PATTERNS[0] if floors == 1 else STAIR_PATTERNS[1 + ((serial + local_index) % (len(STAIR_PATTERNS) - 1))]
            parcel = {
                "id": f"P{serial:03d}",
                "district": zone["id"],
                "district_name": zone["name"],
                "building_type": building_type,
                "category": parcel_category,
                "center_m": [round(point[0], 1), round(point[1], 1)],
                "lot_size_m": [round(lot_w, 1), round(lot_h, 1)],
                "footprint_m": [round(build_w, 1), round(build_h, 1)],
                "rotation_deg": rotation,
                "nearest_road": road["id"],
                "entrance_side": entrance,
                "floors": floors,
                "height_class": "高层" if floors >= 6 else "中层" if floors >= 3 else "低层",
                "life_system": life_system(building_type),
                "is_landmark": building_type in LANDMARK_TYPES,
                "layout_id": f"L{serial:03d}",
                "base_plan": base_plan,
                "footprint_shape": footprint_shape,
                "floorplan_family": floorplan_family,
                "bedrooms": bedrooms,
                "bathrooms": bathrooms,
                "entrance_offset": entrance_offset,
                "window_pattern": window_pattern,
                "stair_pattern": stair_pattern,
                "roof": ROOFS[(serial * 5 + local_index) % len(ROOFS)],
                "facade": FACADES[(serial * 3 + local_index) % len(FACADES)],
                "palette": PALETTES[(serial * 7 + local_index) % len(PALETTES)],
                "feature": FEATURES[(serial * 11 + local_index) % len(FEATURES)],
                "condition": CONDITIONS[(serial * 5 + local_index) % len(CONDITIONS)],
                "room_twist": ROOM_TWISTS[(serial * 7 + local_index) % len(ROOM_TWISTS)],
                "design_signature": f"{building_type}:{serial:03d}:{(serial * 37) % 997:03d}",
                "status": "planned",
            }
            parcel.update(parcel_system_data(building_type, parcel_category, floors, zone["id"], serial))
            parcel["visual_signature"] = "|".join([
                building_type, footprint_shape, floorplan_family, str(bedrooms), str(bathrooms),
                str(entrance_offset), window_pattern, stair_pattern, parcel["roof"], parcel["facade"],
                parcel["palette"], parcel["feature"], str(parcel["floors"]), str(parcel["footprint_m"]),
                parcel["room_twist"]
            ])
            parcels.append(parcel)
            serial += 1
    return parcels


def rotated_rect(cx, cy, w, h, deg):
    angle = math.radians(deg)
    ca, sa = math.cos(angle), math.sin(angle)
    out = []
    for x, y in [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]:
        out.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return out


def footprint_polygon(cx, cy, w, h, deg, shape):
    shapes = {
        "矩形": [(-.5, -.5), (.5, -.5), (.5, .5), (-.5, .5)],
        "L形左翼": [(-.5, -.5), (.5, -.5), (.5, .12), (.12, .12), (.12, .5), (-.5, .5)],
        "L形右翼": [(-.5, -.5), (.5, -.5), (.5, .5), (-.12, .5), (-.12, .12), (-.5, .12)],
        "前凸形": [(-.5, -.24), (-.18, -.24), (-.18, -.5), (.2, -.5), (.2, -.24), (.5, -.24), (.5, .5), (-.5, .5)],
        "后凸形": [(-.5, -.5), (.5, -.5), (.5, .24), (.18, .24), (.18, .5), (-.2, .5), (-.2, .24), (-.5, .24)],
        "主屋加侧翼": [(-.5, -.5), (.22, -.5), (.22, -.2), (.5, -.2), (.5, .5), (-.08, .5), (-.08, .28), (-.5, .28)],
        "错位双矩形": [(-.5, -.5), (.18, -.5), (.18, -.32), (.5, -.32), (.5, .5), (-.18, .5), (-.18, .32), (-.5, .32)],
        "T形": [(-.5, -.5), (.5, -.5), (.5, -.12), (.18, -.12), (.18, .5), (-.18, .5), (-.18, -.12), (-.5, -.12)],
        "U形": [(-.5, -.5), (-.12, -.5), (-.12, .18), (.12, .18), (.12, -.5), (.5, -.5), (.5, .5), (-.5, .5)],
    }
    angle = math.radians(deg)
    ca, sa = math.cos(angle), math.sin(angle)
    out = []
    for nx, ny in shapes.get(shape, shapes["矩形"]):
        x, y = nx * w, ny * h
        out.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return out


def draw_reserved_areas(draw, pt, scale, labels=True):
    colors = {
        "park": "#6e975f", "sports_field": "#6d8f65", "cemetery": "#687665",
        "evacuation_camp": "#8d8465", "logging_site": "#8a775a", "military_checkpoint": "#777c73",
        "landfill": "#716c5f",
    }
    for area in RESERVED_AREAS:
        if area["type"] == "water":
            continue
        x0, y0, x1, y1 = area["bounds"]
        box = [*pt((x0, y0)), *pt((x1, y1))]
        draw.rectangle(box, fill=colors.get(area["type"], "#74776b"), outline="#d1d7c7", width=2)
        spacing = max(7, int(8 * scale))
        left, top, right, bottom = map(int, box)
        for cursor in range(left - (bottom - top), right, spacing):
            start_x = max(left, cursor)
            end_x = min(right, cursor + (bottom - top))
            if start_x <= end_x:
                start_y = bottom - (start_x - cursor)
                end_y = bottom - (end_x - cursor)
                draw.line([(start_x, start_y), (end_x, end_y)], fill="#aeb8a0", width=1)
        if labels:
            center = pt(((x0 + x1) / 2, (y0 + y1) / 2))
            draw.rounded_rectangle([center[0] - 19, center[1] - 12, center[0] + 19, center[1] + 12], 5, fill="#18201b")
            draw.text(center, area["id"], font=font(11, True), fill="#f1ead6", anchor="mm")


def enriched_roads():
    output = []
    industrial_roads = {"R21", "R22", "R23"}
    for road in ROADS:
        road_class = road["class"]
        profile = {
            "highway": {"lanes": 4, "speed_kmh": 90, "sidewalk": "none", "curb_parking": False},
            "arterial": {"lanes": 2, "speed_kmh": 50, "sidewalk": "both", "curb_parking": False},
            "collector": {"lanes": 2, "speed_kmh": 40, "sidewalk": "both", "curb_parking": True},
            "local": {"lanes": 2, "speed_kmh": 30, "sidewalk": "both", "curb_parking": True},
            "rural": {"lanes": 2, "speed_kmh": 50, "sidewalk": "none", "curb_parking": False},
        }[road_class].copy()
        if road["id"] in industrial_roads:
            profile.update({"sidewalk": "one_side", "curb_parking": False, "truck_route": True})
        else:
            profile["truck_route"] = road_class in {"highway", "arterial"}
        output.append({**road, **profile, "surface": "asphalt", "drainage": "ditch" if road_class == "rural" else "storm_drain"})
    return output


def draw_plan(parcels, parcel_labels=False):
    width, height = (2400, 1900) if not parcel_labels else (2200, 2200)
    image = Image.new("RGB", (width, height), "#202623")
    draw = ImageDraw.Draw(image)
    margin, map_px = 70, 1660 if not parcel_labels else 2040
    scale = map_px / WORLD_M
    ox, oy = margin, 150 if not parcel_labels else 90

    def pt(p): return (ox + p[0] * scale, oy + p[1] * scale)

    draw.rectangle([ox, oy, ox + map_px, oy + map_px], fill="#647b45", outline="#d9dfc8", width=4)
    for zone in ZONES:
        x0, y0, x1, y1 = zone["bounds"]
        draw.rectangle([*pt((x0, y0)), *pt((x1, y1))], fill=zone["color"], outline="#b8c2a3", width=2)

    # Authored landscape anchors.
    draw.ellipse([*pt((38, 24)), *pt((200, 174))], fill="#527d91", outline="#b7cfce", width=4)
    draw.line([pt((120, 165)), pt((90, 330)), pt((70, 520)), pt((95, 700))], fill="#527d91", width=max(7, int(12 * scale)))
    for x in range(365, 685, 62):
        draw.rectangle([*pt((x, 18)), *pt((x + 44, 300))], outline="#a7b979", width=2)
    draw_reserved_areas(draw, pt, scale, True)

    # Rail before roads.
    rail = [pt(point) for point in RAIL_POINTS]
    draw.line(rail, fill="#343735", width=max(6, int(8 * scale)))
    draw.line(rail, fill="#9b9078", width=max(2, int(2 * scale)))

    road_colors = {"highway": "#484c4c", "arterial": "#535758", "collector": "#5e6261", "local": "#666a66", "rural": "#716b59"}
    for road in ROADS:
        points = [pt(p) for p in road["points"]]
        road_width = max(4, int(road["width"] * scale))
        draw.line(points, fill="#313532", width=road_width + 5, joint="curve")
        draw.line(points, fill=road_colors[road["class"]], width=road_width, joint="curve")
        if road["class"] in {"highway", "arterial"}:
            for a, b in zip(points, points[1:]):
                length = math.hypot(b[0] - a[0], b[1] - a[1])
                if length == 0: continue
                ux, uy = (b[0] - a[0]) / length, (b[1] - a[1]) / length
                cursor = 0
                while cursor < length:
                    p1 = (a[0] + ux * cursor, a[1] + uy * cursor)
                    p2 = (a[0] + ux * min(length, cursor + 10), a[1] + uy * min(length, cursor + 10))
                    draw.line([p1, p2], fill="#d6bd5a", width=2)
                    cursor += 22

    category_colors = {"residential": "#e5d7a3", "commercial": "#d9955f", "civic": "#91c8dd", "industrial": "#aaa9a3", "rural": "#b89466", "special": "#b99ac9"}
    small = font(13 if parcel_labels else 10, True)
    for parcel in parcels:
        cx, cy = parcel["center_m"]
        lot_w, lot_h = parcel["lot_size_m"]
        b_w, b_h = parcel["footprint_m"]
        lot = [pt(p) for p in rotated_rect(cx, cy, lot_w, lot_h, parcel["rotation_deg"])]
        building = [pt(p) for p in footprint_polygon(cx, cy, b_w, b_h, parcel["rotation_deg"], parcel["footprint_shape"])]
        draw.polygon(lot, outline="#d8dec0")
        draw.polygon(building, fill=category_colors[parcel["category"]], outline="#262a27")
        effective_w, effective_h = (b_w, b_h) if parcel["rotation_deg"] == 0 else (b_h, b_w)
        entrance_offset = parcel["entrance_offset"]
        if parcel["entrance_side"] in {"北", "南"}:
            door_x = cx + entrance_offset * effective_w
            door_y = cy + (-effective_h / 2 if parcel["entrance_side"] == "北" else effective_h / 2)
            a_door, b_door = pt((door_x - 1.5, door_y)), pt((door_x + 1.5, door_y))
        else:
            door_x = cx + (-effective_w / 2 if parcel["entrance_side"] == "西" else effective_w / 2)
            door_y = cy + entrance_offset * effective_h
            a_door, b_door = pt((door_x, door_y - 1.5)), pt((door_x, door_y + 1.5))
        draw.line([a_door, b_door], fill="#22251f", width=max(2, int(1.5 * scale)))
        if parcel_labels:
            text_pos = pt((cx, cy))
            draw.text((text_pos[0], text_pos[1]), parcel["id"], font=small, fill="#111511", anchor="mm")
        elif parcel["floors"] >= 3:
            text_pos = pt((cx, cy))
            draw.rounded_rectangle([text_pos[0] - 17, text_pos[1] - 10, text_pos[0] + 17, text_pos[1] + 10], 4, fill="#151a17")
            draw.text(text_pos, f"{parcel['floors']}F", font=font(11, True), fill="#f3e7bd", anchor="mm")

    if not parcel_labels:
        title = font(34, True); body = font(19); zone_font = font(22, True); tiny = font(16)
        draw.text((70, 42), f"余烬街区 · 1024×1024 米开放世界总规划 v{PLAN_VERSION}", font=title, fill="#f0f2e7")
        draw.text((70, 91), "规划层：生活设施 / 高低建筑 / 地形 / 道路 / 180 个可进入建筑地块（非最终美术）", font=body, fill="#cbd4c1")
        for zone in ZONES:
            x0, y0, x1, y1 = zone["bounds"]
            pos = pt(((x0 + x1) / 2, (y0 + y1) / 2))
            draw.rounded_rectangle([pos[0] - 112, pos[1] - 29, pos[0] + 112, pos[1] + 29], 8, fill="#17201bd8")
            draw.text(pos, f"{zone['id']}  {zone['name']}", font=zone_font, fill="#f0f2e7", anchor="mm")
        lx = ox + map_px + 38
        draw.text((lx, 150), "区域与节奏", font=font(27, True), fill="#f0f2e7")
        y = 200
        for zone in ZONES:
            draw.rectangle([lx, y + 5, lx + 22, y + 27], fill=zone["color"], outline="#d8dec8")
            draw.text((lx + 34, y), f"{zone['id']} {zone['name']}  {zone['count']} 栋", font=tiny, fill="#e2e6db")
            draw.text((lx + 34, y + 23), zone["pace"], font=font(14), fill="#aeb9a9")
            y += 61
        draw.text((lx, y + 12), "建筑类别", font=font(27, True), fill="#f0f2e7")
        y += 62
        counts = Counter(p["category"] for p in parcels)
        names = {"residential": "住宅与住宿", "commercial": "商业", "civic": "公共设施", "industrial": "工业", "rural": "农业附属", "special": "特殊地点"}
        for key in names:
            draw.rectangle([lx, y + 3, lx + 22, y + 25], fill=category_colors[key], outline="#1e211f")
            draw.text((lx + 34, y), f"{names[key]}  {counts[key]} 栋", font=tiny, fill="#e2e6db")
            y += 38
        draw.text((lx, y + 24), "地图尺度", font=font(27, True), fill="#f0f2e7")
        y += 74
        draw.text((lx, y), "1 逻辑格 = 0.5 米\n32×32 格区块 = 16×16 米\n总计 64×64 区块\n所有边缘保留后续扩展出口", font=body, fill="#d4dacd", spacing=10)
        draw.text((lx, y + 145), "开放世界核心设施", font=font(27, True), fill="#f0f2e7")
        core_lines = [
            "高层写字楼 ×3（8–12 层）",
            "公寓塔楼 ×2 / 高层酒店 ×1",
            "综合医院 / 社区诊所 / 药店",
            "购物中心 / 大型超市 / 百货",
            "小学 / 中学 / 图书馆 / 托儿所",
            "警局 / 消防站 / 市政厅 / 法院",
            "公交总站 / 停车楼 / 加油维修",
            "工厂 / 物流 / 铁路 / 仓储",
            "变电站 / 净水厂 / 燃料库",
        ]
        draw.multiline_text((lx, y + 194), "\n".join(core_lines), font=font(16), fill="#d4dacd", spacing=8)
        # North arrow and scale.
        draw.line([(lx + 370, 255), (lx + 370, 175)], fill="#f0f2e7", width=5)
        draw.polygon([(lx + 370, 155), (lx + 357, 180), (lx + 383, 180)], fill="#f0f2e7")
        draw.text((lx + 370, 125), "N", font=font(26, True), fill="#f0f2e7", anchor="mm")
        sx, sy = lx, 1740
        draw.line([(sx, sy), (sx + 100 * scale, sy)], fill="#f0f2e7", width=6)
        draw.line([(sx, sy - 8), (sx, sy + 8), (sx + 100 * scale, sy + 8), (sx + 100 * scale, sy - 8)], fill="#f0f2e7", width=3)
        draw.text((sx, sy - 34), "100 米", font=tiny, fill="#f0f2e7")
    else:
        draw.text((70, 28), f"余烬街区 · 180 个建筑地块编号图 v{PLAN_VERSION}", font=font(32, True), fill="#f0f2e7")
    return image


def draw_residential_diversity(parcels):
    homes = [parcel for parcel in parcels if parcel["category"] == "residential"]
    columns = 8
    card_w, card_h = 285, 190
    margin_x, top = 45, 105
    rows = math.ceil(len(homes) / columns)
    image = Image.new("RGB", (margin_x * 2 + columns * card_w, top + rows * card_h + 45), "#202623")
    draw = ImageDraw.Draw(image)
    draw.text((45, 25), f"余烬街区 · {len(homes)} 栋住宅差异规划表 v{PLAN_VERSION}", font=font(31, True), fill="#f0f2e7")
    draw.text((45, 66), "每张卡对应一份独立房屋规格；轮廓图为规划示意，室内平面与最终美术将逐栋制作。", font=font(17), fill="#bdc8b9")
    title_font, detail_font = font(16, True), font(13)
    for index, parcel in enumerate(homes):
        column, row = index % columns, index // columns
        x0, y0 = margin_x + column * card_w, top + row * card_h
        x1, y1 = x0 + card_w - 10, y0 + card_h - 10
        draw.rounded_rectangle([x0, y0, x1, y1], 8, fill="#2b332f", outline="#56635b", width=2)
        draw.text((x0 + 12, y0 + 9), f"{parcel['id']} / {parcel['base_plan']}  {TYPE_NAMES.get(parcel['building_type'], parcel['building_type'])}", font=title_font, fill="#f2e8c8")
        b_w, b_h = parcel["footprint_m"]
        ratio = min(100 / max(b_w, 1), 88 / max(b_h, 1))
        polygon = footprint_polygon(x0 + 66, y0 + 101, b_w * ratio, b_h * ratio, 0, parcel["footprint_shape"])
        draw.polygon(polygon, fill="#ddc990", outline="#171b18")
        tx = x0 + 125
        lines = [
            f"轮廓：{parcel['footprint_shape']}",
            f"动线：{parcel['floorplan_family']}",
            f"屋顶：{parcel['roof']}",
            f"外墙：{parcel['facade']} / {parcel['palette']}",
            f"{parcel['floors']}层  {parcel['bedrooms']}卧  {parcel['bathrooms']}卫",
            f"窗组：{parcel['window_pattern']}",
        ]
        draw.multiline_text((tx, y0 + 43), "\n".join(lines), font=detail_font, fill="#dce2d8", spacing=3)
    return image


def draw_facility_matrix(parcels):
    columns, rows = 3, 3
    panel_w, panel_h = 760, 555
    margin, top = 45, 105
    image = Image.new("RGB", (margin * 2 + columns * panel_w, top + rows * panel_h + 45), "#202623")
    draw = ImageDraw.Draw(image)
    draw.text((45, 24), f"余烬街区 · 开放世界设施配置表 v{PLAN_VERSION}", font=font(32, True), fill="#f0f2e7")
    draw.text((45, 66), "生活、医疗、教育、安全、商业、交通、就业和基础设施全部落到具体地块。", font=font(17), fill="#bdc8b9")
    for index, zone in enumerate(ZONES):
        x0 = margin + (index % columns) * panel_w
        y0 = top + (index // columns) * panel_h
        x1, y1 = x0 + panel_w - 12, y0 + panel_h - 12
        draw.rounded_rectangle([x0, y0, x1, y1], 10, fill="#2a322e", outline=zone["color"], width=4)
        draw.text((x0 + 18, y0 + 14), f"{zone['id']}  {zone['name']}  ·  {zone['count']} 栋", font=font(23, True), fill="#f1e9d2")
        zone_parcels = [parcel for parcel in parcels if parcel["district"] == zone["id"]]
        grouped = {}
        for parcel in zone_parcels:
            grouped.setdefault(parcel["building_type"], []).append(parcel)
        ordered = sorted(grouped.items(), key=lambda item: (0 if item[0] in LANDMARK_TYPES else 1, life_system(item[0]), TYPE_NAMES.get(item[0], item[0])))
        split = math.ceil(len(ordered) / 2)
        for item_index, (building_type, records) in enumerate(ordered):
            column = 0 if item_index < split else 1
            line = item_index if column == 0 else item_index - split
            tx, ty = x0 + 22 + column * 365, y0 + 62 + line * 27
            floors = sorted({record["floors"] for record in records})
            floor_text = ""
            if max(floors) >= 2:
                floor_text = f" · {min(floors)}–{max(floors)}层" if len(floors) > 1 else f" · {floors[0]}层"
            marker = "◆ " if building_type in LANDMARK_TYPES else "• "
            draw.text((tx, ty), f"{marker}{TYPE_NAMES.get(building_type, building_type)} ×{len(records)}{floor_text}", font=font(15, building_type in LANDMARK_TYPES), fill="#e0e5dc")
        systems = sorted({parcel["life_system"] for parcel in zone_parcels})
        area_names = [area["name"] for area in RESERVED_AREAS if area["district"] == zone["id"]]
        if area_names:
            draw.text((x0 + 22, y1 - 58), "户外地点：" + " / ".join(area_names), font=font(13), fill="#c9cfbd")
        draw.text((x0 + 22, y1 - 32), "覆盖：" + " / ".join(systems), font=font(13), fill="#aebbac")
    return image


def polyline_midpoint(points):
    lengths = [math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(points, points[1:])]
    target = sum(lengths) / 2
    travelled = 0.0
    for (a, b), length in zip(zip(points, points[1:]), lengths):
        if travelled + length >= target and length > 0:
            t = (target - travelled) / length
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
        travelled += length
    return points[-1]


def draw_road_network():
    width, height = 2400, 1900
    image = Image.new("RGB", (width, height), "#202623")
    draw = ImageDraw.Draw(image)
    margin, map_px, ox, oy = 70, 1660, 70, 150
    scale = map_px / WORLD_M

    def pt(point):
        return (ox + point[0] * scale, oy + point[1] * scale)

    draw.rectangle([ox, oy, ox + map_px, oy + map_px], fill="#647b45", outline="#d9dfc8", width=4)
    for zone in ZONES:
        x0, y0, x1, y1 = zone["bounds"]
        draw.rectangle([*pt((x0, y0)), *pt((x1, y1))], fill=zone["color"], outline="#aebaa0", width=2)
    draw.ellipse([*pt((38, 24)), *pt((200, 174))], fill="#527d91", outline="#b7cfce", width=4)
    draw.line([pt((120, 165)), pt((90, 330)), pt((70, 520)), pt((95, 700))], fill="#527d91", width=max(7, int(12 * scale)))
    draw_reserved_areas(draw, pt, scale, True)
    rail = [pt(point) for point in RAIL_POINTS]
    draw.line(rail, fill="#343735", width=max(6, int(8 * scale)))
    draw.line(rail, fill="#9b9078", width=max(2, int(2 * scale)))

    road_colors = {"highway": "#3c4242", "arterial": "#4c5354", "collector": "#5a6160", "local": "#666c68", "rural": "#766f5c"}
    for road in ROADS:
        points = [pt(point) for point in road["points"]]
        road_width = max(4, int(road["width"] * scale))
        draw.line(points, fill="#272b29", width=road_width + 6, joint="curve")
        draw.line(points, fill=road_colors[road["class"]], width=road_width, joint="curve")
        if road["class"] in {"highway", "arterial"}:
            for a, b in zip(points, points[1:]):
                length = math.hypot(b[0] - a[0], b[1] - a[1])
                if length == 0:
                    continue
                ux, uy = (b[0] - a[0]) / length, (b[1] - a[1]) / length
                cursor = 0
                while cursor < length:
                    p1 = (a[0] + ux * cursor, a[1] + uy * cursor)
                    p2 = (a[0] + ux * min(length, cursor + 10), a[1] + uy * min(length, cursor + 10))
                    draw.line([p1, p2], fill="#d6bd5a", width=2)
                    cursor += 22
        label = pt(polyline_midpoint(road["points"]))
        label_offsets = {"R02": (-42, -22), "R03": (0, 24), "R29": (-28, -24), "R31": (0, 23)}
        offset = label_offsets.get(road["id"], (0, 0))
        label = (label[0] + offset[0], label[1] + offset[1])
        draw.rounded_rectangle([label[0] - 20, label[1] - 14, label[0] + 20, label[1] + 14], 6, fill="#151a17", outline="#dfe4d8")
        draw.text(label, road["id"], font=font(13, True), fill="#f3e7bd", anchor="mm")

    feature_colors = {"stream_bridge": "#80b7c9", "rail_crossing": "#d5b46a", "signalized_intersection": "#d7725f", "highway_exit": "#d7725f"}
    for feature in ROAD_FEATURES:
        center = pt(feature["center_m"])
        draw.ellipse([center[0] - 7, center[1] - 7, center[0] + 7, center[1] + 7], fill=feature_colors[feature["type"]], outline="#171a18", width=2)
        draw.text((center[0] + 10, center[1] - 18), feature["id"], font=font(11, True), fill="#f1ead6")

    draw.text((70, 42), f"余烬街区 · 道路层级与街区结构 v{PLAN_VERSION}", font=font(34, True), fill="#f0f2e7")
    draw.text((70, 91), "道路编号图：高速 / 城市主轴 / 次干道 / 本地街道 / 乡道", font=font(19), fill="#cbd4c1")
    lx = ox + map_px + 38
    draw.text((lx, 150), "路网层级", font=font(28, True), fill="#f0f2e7")
    class_names = {"highway": "高速公路", "arterial": "城市主干道", "collector": "次干道", "local": "本地街道", "rural": "乡道"}
    counts = Counter(road["class"] for road in ROADS)
    y = 205
    for road_class in ["highway", "arterial", "collector", "local", "rural"]:
        draw.line([(lx, y + 12), (lx + 70, y + 12)], fill=road_colors[road_class], width=12)
        draw.text((lx + 88, y), f"{class_names[road_class]}  {counts[road_class]} 条", font=font(18), fill="#e0e5dc")
        y += 52
    draw.text((lx, y + 20), "结构规则", font=font(28, True), fill="#f0f2e7")
    rules = [
        "R01 仅服务东北外围",
        "R08 是唯一高速出口",
        "R02 东西向城市主轴",
        "R03 南北向城市主轴",
        "城区路口以直角为主",
        "住宅入口不直接接高速",
        "商业区形成四个清晰街块",
        "医院与学校各有双向出口",
        "工业道路满足货车转弯",
        "郊区只保留一条弯曲环路",
    ]
    draw.multiline_text((lx, y + 70), "\n".join(rules), font=font(17), fill="#d4dacd", spacing=10)
    draw.text((lx, y + 430), "关键编号", font=font(28, True), fill="#f0f2e7")
    key_roads = [
        "R01 东北州际公路", "R02 余烬大道", "R03 中央大道", "R04 湖畔乡道",
        "R07 服务区前路", "R08 高速出口路", "R13 市场街", "R17 校园北路",
        "R21 工业北路", "R24 旧城北街", "R29 南郊连接路", "R30 东南郊环路",
    ]
    draw.multiline_text((lx, y + 480), "\n".join(key_roads), font=font(16), fill="#d4dacd", spacing=8)
    draw.text((lx, 1740), f"共 {len(ROADS)} 条道路 · 1 个高速出口", font=font(18, True), fill="#f0f2e7")
    return image


def validate(parcels):
    assert len(parcels) == 180
    assert len({p["id"] for p in parcels}) == 180
    assert len({p["layout_id"] for p in parcels}) == 180
    assert len({p["design_signature"] for p in parcels}) == 180
    assert len({p["visual_signature"] for p in parcels}) == 180
    residential = [p for p in parcels if p["category"] == "residential"]
    nonresidential = [p for p in parcels if p["category"] != "residential"]
    assert len({p["base_plan"] for p in residential}) == len(residential)
    assert len({p["base_plan"] for p in nonresidential}) == len(nonresidential)
    appearance_keys = {
        (p["building_type"], p["footprint_shape"], p["roof"], p["facade"], p["palette"], p["feature"], p["floors"], p["window_pattern"], p["entrance_offset"])
        for p in residential
    }
    floorplan_keys = {
        (p["footprint_shape"], p["floorplan_family"], p["bedrooms"], p["bathrooms"], p["entrance_offset"], p["stair_pattern"], p["room_twist"])
        for p in residential
    }
    assert len(appearance_keys) == len(residential)
    assert len(floorplan_keys) == len(residential)
    required_facilities = {
        "office_tower", "apartment_tower", "hotel_highrise", "hospital", "medical_clinic", "pharmacy",
        "supermarket", "shopping_mall", "police", "fire_station", "elementary_school", "high_school",
        "town_hall", "courthouse", "bus_station", "parking_garage", "power_substation", "water_treatment",
        "county_jail", "gun_store", "liquor_store", "bookstore", "hair_salon", "radio_station",
        "lumber_yard", "waste_transfer",
    }
    assert required_facilities.issubset({p["building_type"] for p in parcels})
    assert all(p["life_system"] != "其他" for p in parcels)
    assert all(-2 <= p["z_min"] <= 0 and 0 <= p["z_max"] <= 31 for p in parcels)
    assert all(p["parking_spaces_planned"] >= 0 and p["room_definition_set"] and p["loot_profile"] for p in parcels)
    assert Counter(p["district"] for p in parcels) == Counter({z["id"]: z["count"] for z in ZONES})
    assert all(0 <= p["center_m"][0] <= WORLD_M and 0 <= p["center_m"][1] <= WORLD_M for p in parcels)
    road_ids = {road["id"] for road in ROADS}
    assert all(p["nearest_road"] in road_ids for p in parcels)
    assert all(
        feature.get("road") in road_ids if "road" in feature else set(feature.get("roads", [])).issubset(road_ids)
        for feature in ROAD_FEATURES
    )
    road_by_id = {road["id"]: road for road in ROADS}
    assert all(
        road_by_id[p["nearest_road"]]["class"] not in {"highway", "arterial"}
        for p in parcels if p["category"] == "residential"
    )
    assert all(
        p["footprint_m"][0] <= p["lot_size_m"][0]
        and p["footprint_m"][1] <= p["lot_size_m"][1]
        for p in parcels
    )

    # Every planned lot must fit inside the world and remain separate from its
    # neighbours. This catches the clipping/overlap failures seen in earlier maps.
    lot_boxes = []
    for parcel in parcels:
        cx, cy = parcel["center_m"]
        lot_w, lot_h = parcel["lot_size_m"]
        if parcel["rotation_deg"] == 90:
            lot_w, lot_h = lot_h, lot_w
        box = (cx - lot_w / 2, cy - lot_h / 2, cx + lot_w / 2, cy + lot_h / 2)
        assert box[0] >= 0 and box[1] >= 0 and box[2] <= WORLD_M and box[3] <= WORLD_M
        lot_boxes.append((parcel["id"], box))
    for index, (parcel_id, box) in enumerate(lot_boxes):
        parcel = parcels[index]
        for area in RESERVED_AREAS:
            if area["district"] != parcel["district"] or not area["blocks_buildings"]:
                continue
            ax0, ay0, ax1, ay1 = area["bounds"]
            overlaps_reserved = box[0] < ax1 and box[2] > ax0 and box[1] < ay1 and box[3] > ay0
            assert not overlaps_reserved, f"Reserved area overlap: {parcel_id} / {area['id']}"
        for other_id, other in lot_boxes[index + 1:]:
            overlaps = box[0] < other[2] and box[2] > other[0] and box[1] < other[3] and box[3] > other[1]
            assert not overlaps, f"Lot overlap: {parcel_id} / {other_id}"


def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    DATA.mkdir(parents=True, exist_ok=True)
    parcels = generate_parcels()
    validate(parcels)
    payload = {
        "version": PLAN_VERSION,
        "seed": SEED,
        "world_size_m": [WORLD_M, WORLD_M],
        "supported_z_levels": [-2, 31],
        "logical_cell_m": 0.5,
        "chunk_cells": [32, 32],
        "zones": ZONES,
        "roads": enriched_roads(),
        "road_features": ROAD_FEATURES,
        "rail": {"id": "RAIL-01", "type": "freight", "points": RAIL_POINTS},
        "reserved_areas": RESERVED_AREAS,
        "expansion_gates": EXPANSION_GATES,
        "required_map_data_layers": MAP_DATA_LAYERS,
        "parcels": parcels,
    }
    (DATA / f"world-master-v{PLAN_VERSION}.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    with (DATA / f"world-parcels-v{PLAN_VERSION}.csv").open("w", encoding="utf-8-sig", newline="") as fh:
        fields = ["id", "district", "district_name", "building_type", "category", "life_system", "is_landmark", "center_m", "lot_size_m", "footprint_m", "rotation_deg", "nearest_road", "entrance_side", "floors", "height_class", "basement_levels", "z_min", "z_max", "elevator_count", "stairwell_count", "layout_id", "base_plan", "footprint_shape", "floorplan_family", "bedrooms", "bathrooms", "entrance_offset", "window_pattern", "stair_pattern", "roof", "facade", "palette", "feature", "condition", "room_twist", "room_definition_set", "loot_profile", "zombie_heat_weight", "vehicle_spawn_profile", "parking_spaces_planned", "parking_strategy", "loading_bays", "service_entrance_required", "utility_profile", "foraging_profile", "story_zone", "business_name_id", "map_reveal_item", "interior_state_seed", "design_signature", "visual_signature", "status"]
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        writer.writerows(parcels)
    draw_plan(parcels, False).save(BUILD / f"world-master-plan-v{PLAN_VERSION}.png", quality=95)
    draw_plan(parcels, True).save(BUILD / f"world-parcels-v{PLAN_VERSION}.png", quality=95)
    draw_residential_diversity(parcels).save(BUILD / f"residential-diversity-v{PLAN_VERSION}.png", quality=95)
    draw_facility_matrix(parcels).save(BUILD / f"world-facilities-v{PLAN_VERSION}.png", quality=95)
    draw_road_network().save(BUILD / f"road-network-v{PLAN_VERSION}.png", quality=95)
    print(f"MASTER PLAN v{PLAN_VERSION} PASS: 1024x1024 m, 9 zones, {len(ROADS)} roads, 180 unique parcel/layout/signature records")
    print("CATEGORY COUNTS:", dict(sorted(Counter(p["category"] for p in parcels).items())))


if __name__ == "__main__":
    main()
