tool
extends Spatial
var p = null								#for storing paired portal node
var b = 0									#keeps track of how many portals are using a channel
export(int, 1, 100, 1) var Channel = 1		#sets the portal channel
export(int, 1,10,1) var max_recursion = 1 
export(float) var size_x = 2
export(float) var size_y = 2
export(Color) var color						#sets portal frame color
#For Diagnostics============================================================================
export(bool) var hidecam = false			#hide mirror camera
#===========================================================================================
var vis = true

onready var recs = $Recursions.get_children()
onready var ren_t = $RenderTargets.get_children()
onready var dyna_rec = max_recursion
onready var surf = Plane(self.global_transform.basis.z.normalized(),self.global_transform.origin.dot(self.global_transform.basis.z.normalized()))
var pd										#portal distance - distance between portal pairs


func _ready(): 
	add_to_group("portals")
	$CSGCombiner.get("material_override").set("albedo_color",color)
	_sync(0)
#For Diagnostics=========================================================================================
	if(hidecam==false):

		for cam in recs:
		#	cam.get_node("Camera/MeshInstance").get("material/0").set("resource_local_to_scene",true)
			cam.get_node("Camera/MeshInstance").get("material/0").set("albedo_color",color)
			cam.get_node("Camera/MeshInstance").show()

	else:
		for hide in recs:
			hide.get_node("Camera/MeshInstance").hide()
#For Diagnostics=========================================================================================
	for cam in recs:
		cam.add_to_group("PortalCams")
		cam.get_child(0).global_transform = self.global_transform
		#cam.get_child(0).rotation = self.rotation
		cam.get_child(0).rotation.y += PI
		print(cam)


func _sync(a):
	for i in range(get_tree().get_nodes_in_group("portals").size()):
		if(get_tree().get_nodes_in_group("portals")[i].Channel==Channel && get_tree().get_nodes_in_group("portals")[i]!=self && b<=1):
			p = get_tree().get_nodes_in_group("portals")[i]
			b += 1

	if(b == 1):
		print(self.name," has one link: ",p.name)
		pd = self.global_transform.origin.distance_to(p.global_transform.origin)

		if(a!=1):					#used to tell this portal's pair to sync up
			p._sync(1)				#the "a=1" is used to stop the other portal from going through
									#this function too many times
		_render()

	else:
		if(b > 1):
			print(self.name," has too many links ",b)
		if(b == 0):
			print(self.name," has no link ",b)
		p = null

#	$DummyCam.rotation.y = PI		#you actually don't need this line anymore, since its already turned around in the scene but I just wanted o get my point accross 
									#having it's rotation preped even before the script ran, actually saved me a lot of process time, beats having to add PI everytime in the "update_cam" function XD



func _render():
	$CSGCombiner.set_scale(Vector3(size_x/20.0,size_y/20.0,1))

	var rec = Vector2(size_x,size_y)*20
	for f in recs:
		f.size = rec

	var e = 0

	for r in max_recursion:
		ren_t[r].show()
		ren_t[r].material_override.set_shader_param("portal", p.get_node("Recursions").get_child(e).get_texture())
		ren_t[r].mesh.size.x = size_x
		ren_t[r].mesh.size.y = size_y
		e+=1
	e=0
	if(max_recursion<10):
		ren_t[max_recursion].hide()


func update_cam(mt):
		if(b==1&&vis):
			var T = p.global_transform.inverse() * mt
			#var NP = T.origin #p.global_transform.xform_inv(mt.origin)

			var NP = -Vector2(T.origin.x,T.origin.y)
			#print(T.origin," T\n ",NP," NP\n")
			T = T.rotated(Vector3(0, 1, 0), PI)
			$DummyCam.transform.origin= T.origin
			
#Recursion levels are brought to you by: JewWithGardenBeans: https://github.com/DeleteSystem32/godot-portal-example/blob/master/README.md
#Frustum  culling are brought to you by: JFons: https://github.com/JFonS/godot-mirror-example

			for j in range (max_recursion):

				$Recursions.get_child(j).get_child(0).set_frustum(size_y,NP,surf.project($Recursions.get_child(j).get_child(0).global_transform.origin).distance_to($Recursions.get_child(j).get_child(0).global_transform.origin),100000)
				$Recursions.get_child(j).get_child(0).global_transform = $DummyCam.global_transform
				$DummyCam.transform.origin.z -= pd






func _on_VisibilityNotifier_camera_entered(camera):
#		if(camera.is_in_group("PortalCams")):
#			print(self.name," is visible to a Portal")
		if(camera is PlayerCams):
		#print(camera.get_parent().get_parent().get_parent().name," ",camera.get_parent().name," is looking at: ",self.name)
			print(self.name," is visible to a Player")
			vis =true



func _on_VisibilityNotifier_camera_exited(camera):
	if(camera is PlayerCams):
		#print(camera.get_parent().get_parent().get_parent().name," ",camera.get_parent().name," is looking at: ",self.name)
		print(self.name," is not visible to a Player")
		vis = false













