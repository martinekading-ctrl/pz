extends RefCounted

const ITEMS := {
	"food":{"name":"罐装食品","category":"consumable","weight":0.4,"stack":5,"icon":"▣","desc":"耐储存的食物补给。食用恢复 25 点饱食。","effects":{"food":25.0},"use_text":"食用了罐装食品，饱食 +25"},
	"water":{"name":"瓶装饮用水","category":"consumable","weight":0.5,"stack":5,"icon":"◈","desc":"饮水恢复 30 点水分。","effects":{"water":30.0},"use_text":"饮用了瓶装水，水分 +30"},
	"empty_bottle":{"name":"空塑料瓶","category":"container","weight":0.08,"stack":8,"icon":"♢","desc":"可在仍有供水的水龙头处灌装成瓶装饮用水。"},
	"fresh_food":{"name":"面包","category":"consumable","weight":0.32,"stack":4,"icon":"▤","desc":"新鲜时恢复 22 点饱食；全地图同批面包约两天半后变质。","effects":{"food":22.0},"use_text":"吃下面包，饱食 +22","perishable":true},
	"canned_soup":{"name":"罐头汤","category":"consumable","weight":0.48,"stack":4,"icon":"▦","desc":"耐储存的汤罐头，同时补充少量水分。","effects":{"food":20.0,"water":10.0},"use_text":"喝下罐头汤，饱食 +20，水分 +10"},
	"energy_bar":{"name":"能量棒","category":"consumable","weight":0.08,"stack":8,"icon":"▰","desc":"轻便食物，恢复饱食和少量体力。","effects":{"food":14.0,"stamina":12.0},"use_text":"吃下能量棒，饱食 +14，体力 +12"},
	"soda":{"name":"罐装汽水","category":"consumable","weight":0.35,"stack":6,"icon":"◆","desc":"恢复水分并略微降低疲劳。","effects":{"water":18.0,"fatigue":-8.0},"use_text":"喝下汽水，水分 +18，疲劳 -8"},
	"coffee":{"name":"速溶咖啡","category":"consumable","weight":0.06,"stack":5,"icon":"◉","desc":"短时间提神，降低疲劳并恢复少量体力。","effects":{"fatigue":-24.0,"stamina":8.0},"use_text":"喝下咖啡，疲劳 -24，体力 +8"},
	"bandage":{"name":"医用绷带","category":"consumable","weight":0.1,"stack":10,"icon":"✚","desc":"包扎指定身体部位的伤口，大幅减缓出血。"},
	"painkillers":{"name":"止痛药","category":"consumable","weight":0.08,"stack":5,"icon":"●","desc":"暂时缓解伤口疼痛，药效持续约三小时。"},
	"disinfectant":{"name":"消毒剂","category":"consumable","weight":0.22,"stack":4,"icon":"✣","desc":"处理一个感染伤口；咬伤只能减缓感染。"},
	"antibiotics":{"name":"抗生素","category":"consumable","weight":0.06,"stack":4,"icon":"✜","desc":"降低全身非咬伤感染；不能治愈僵尸咬伤。"},
	"duct_tape":{"name":"强力胶带","category":"consumable","weight":0.18,"stack":5,"icon":"◎","desc":"修补当前装备的武器，恢复约 20% 最大耐久。"},
	"gas_can":{"name":"汽油桶","category":"fuel","weight":7.5,"stack":1,"icon":"▨","desc":"装有约 10 升汽油，可在车辆检查页面加入油箱。"},
	"baseball_cap":{"name":"棒球帽","category":"clothing","slot":"head","weight":0.18,"stack":1,"icon":"⌒","desc":"轻便帽子，只能提供少量头部防护。","scratch_protection":0.12,"laceration_protection":0.05,"bite_protection":0.02,"durability":40.0},
	"motorcycle_helmet":{"name":"摩托车头盔","category":"clothing","slot":"head","weight":1.2,"stack":1,"icon":"◒","desc":"坚固的头部防护，重量较高。","scratch_protection":0.42,"laceration_protection":0.30,"bite_protection":0.16,"durability":85.0},
	"denim_jacket":{"name":"牛仔夹克","category":"clothing","slot":"torso","weight":0.95,"stack":1,"icon":"♜","desc":"保护躯干与手臂的耐磨外套。","scratch_protection":0.28,"laceration_protection":0.18,"bite_protection":0.08,"durability":70.0},
	"leather_jacket":{"name":"皮夹克","category":"clothing","slot":"torso","weight":1.35,"stack":1,"icon":"♛","desc":"厚实外套，对撕裂和咬伤有较好防护。","scratch_protection":0.40,"laceration_protection":0.31,"bite_protection":0.17,"durability":90.0},
	"jeans":{"name":"牛仔裤","category":"clothing","slot":"legs","weight":0.8,"stack":1,"icon":"Ⅱ","desc":"结实的长裤，保护腿部。","scratch_protection":0.24,"laceration_protection":0.15,"bite_protection":0.06,"durability":65.0},
	"cargo_pants":{"name":"工装裤","category":"clothing","slot":"legs","weight":1.0,"stack":1,"icon":"▥","desc":"厚实耐磨的工装长裤。","scratch_protection":0.32,"laceration_protection":0.22,"bite_protection":0.10,"durability":78.0},
	"sneakers":{"name":"运动鞋","category":"clothing","slot":"feet","weight":0.55,"stack":1,"icon":"⌁","desc":"轻便鞋，提供少量腿脚防护。","scratch_protection":0.14,"laceration_protection":0.07,"bite_protection":0.02,"durability":45.0},
	"work_boots":{"name":"工作靴","category":"clothing","slot":"feet","weight":1.15,"stack":1,"icon":"⌙","desc":"高帮工作靴，可与裤装共同保护腿部。","scratch_protection":0.30,"laceration_protection":0.20,"bite_protection":0.09,"durability":80.0},
	"parts":{"name":"机械零件","category":"material","weight":0.25,"stack":10,"icon":"⚙","desc":"制作与修理材料，暂不能直接使用。"},
	"bed_sheet":{"name":"旧床单","category":"material","weight":0.35,"stack":4,"icon":"▧","desc":"可撕成布条，用于制作简易绷带。"},
	"ripped_cloth":{"name":"撕布","category":"material","weight":0.06,"stack":12,"icon":"≈","desc":"从旧床单撕下的布条，可制作简易绷带。"},
	"plank":{"name":"木板","category":"material","weight":1.15,"stack":4,"icon":"▬","desc":"用于封堵门窗的建筑材料。"},
	"nails":{"name":"钉子","category":"material","weight":0.015,"stack":30,"icon":"⋮","desc":"锤子施工时使用的紧固件。"},
	"hammer":{"name":"木工锤","category":"tool","weight":0.75,"stack":1,"icon":"⌕","desc":"封窗和拆除木板路障所需的工具，不会在施工时消耗。"},
	"pistol_ammo":{"name":"9mm 子弹","category":"ammunition","weight":0.012,"stack":30,"icon":"•","desc":"9mm 手枪使用的散装弹药，需要弹匣才能装入武器。"},
	"pistol_magazine":{"name":"9mm 弹匣","category":"magazine","weight":0.12,"stack":4,"icon":"▥","desc":"手枪弹匣。放在背包中即可用散装 9mm 子弹装填手枪。"},
	"crowbar":{"name":"撬棍","category":"weapon","weight":2.1,"stack":1,"icon":"⌁","desc":"结实可靠的钝器，攻击与击退较均衡。","damage":34,"range":1.35,"swing":0.48,"knockback":0.42,"durability":100.0,"wear":1.0,"visual_length":30.0,"visual_color":"9a7060"},
	"baseball_bat":{"name":"棒球棍","category":"weapon","weight":1.3,"stack":1,"icon":"▰","desc":"攻击距离较长，擅长击退。","damage":30,"range":1.55,"swing":0.58,"knockback":0.56,"durability":80.0,"wear":2.0,"visual_length":34.0,"visual_color":"8b603f"},
	"kitchen_knife":{"name":"厨房刀","category":"weapon","weight":0.45,"stack":1,"icon":"†","desc":"挥动迅速，但攻击距离与耐久较低。","damage":24,"range":0.95,"swing":0.32,"knockback":0.16,"durability":55.0,"wear":1.0,"visual_length":21.0,"visual_color":"b9bec0"},
	"hand_axe":{"name":"手斧","category":"weapon","weight":1.4,"stack":1,"icon":"◆","desc":"伤害高，但攻击前后动作较慢。","damage":42,"range":1.20,"swing":0.68,"knockback":0.38,"durability":70.0,"wear":1.5,"visual_length":27.0,"visual_color":"6f5844"},
	"pistol":{"name":"9mm 手枪","category":"firearm","weight":0.95,"stack":1,"icon":"⌐","desc":"近距离自卫手枪。必须瞄准后射击，枪声会吸引远处僵尸。","damage":46,"range":12.0,"swing":0.26,"knockback":0.16,"durability":100.0,"wear":0.12,"visual_length":18.0,"visual_color":"646a6c","mag_capacity":12,"reload_seconds":1.55,"noise_radius":26.0,"ammo_item":"pistol_ammo","magazine_item":"pistol_magazine"}
}

const FUNCTIONAL_ITEM_IDS := ["fresh_food","canned_soup","energy_bar","soda","coffee","disinfectant","antibiotics","duct_tape"]
const CLOTHING_IDS := ["baseball_cap","motorcycle_helmet","denim_jacket","leather_jacket","jeans","cargo_pants","sneakers","work_boots"]
const LOOT_EXPANSION_IDS := ["fresh_food","canned_soup","energy_bar","soda","coffee","disinfectant","antibiotics","duct_tape","baseball_cap","motorcycle_helmet","denim_jacket","leather_jacket","jeans","cargo_pants","sneakers","work_boots"]

static func has(item_id: String) -> bool:
	return ITEMS.has(item_id)

static func item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id,{})

static func is_weapon(item_id: String) -> bool:
	return str(item(item_id).get("category","")) in ["weapon", "firearm"]

static func is_firearm(item_id: String) -> bool:
	return str(item(item_id).get("category", "")) == "firearm"

static func is_clothing(item_id: String) -> bool:
	return str(item(item_id).get("category", "")) == "clothing"
