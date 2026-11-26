class_name Item
extends RefCounted
## An item instance. Its rules come from the content definition `template_id`;
## the instance holds only what can differ between two copies.

var id: int = 0
var template_id: String = ""
var quantity: int = 1
var pos: Vector2i = Vector2i.ZERO


func def(db: ContentDB) -> Dictionary:
	return db.get_def("items", template_id)


func display_name(db: ContentDB) -> String:
	var n := String(def(db).get("name", template_id))
	return n if quantity <= 1 else "%d x %s" % [quantity, n]


func to_dict() -> Dictionary:
	return {"id": id, "t": template_id, "q": quantity, "x": pos.x, "y": pos.y}


static func from_dict(d: Dictionary) -> Item:
	var it := Item.new()
	it.id = int(d["id"])
	it.template_id = String(d["t"])
	it.quantity = int(d["q"])
	it.pos = Vector2i(int(d["x"]), int(d["y"]))
	return it
