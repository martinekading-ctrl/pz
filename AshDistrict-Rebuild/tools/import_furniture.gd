extends SceneTree
func _initialize() -> void:
	var source := Image.load_from_file("res://art/house_blue/furniture-v08-keyed.png")
	source.convert(Image.FORMAT_RGBA8)
	var regions := [Rect2i(0,0,580,535),Rect2i(610,0,310,480),Rect2i(1010,65,515,475),Rect2i(45,550,440,405),Rect2i(600,470,340,520),Rect2i(1070,550,365,430)]
	for i in regions.size():
		var image := source.get_region(regions[i])
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x,y)
				if c.r-c.g>0.28 and c.b-c.g>0.28:
					image.set_pixel(x,y,Color(0,0,0,0))
		var used := image.get_used_rect()
		image = image.get_region(used.grow(2).intersection(Rect2i(0,0,image.get_width(),image.get_height())))
		image.save_png("res://art/house_blue/prop-v08-"+str(i)+".png")
	print("IMPORTED 6 RGBA sprites")
	quit()
