tool
extends Spatial
var pair = null								#for storing paired portal node
var binds = 0								#keeps track of how many portals are using a channel
var act = true								#for activating and deactivating portal camera updates
var pd				#portal distance 		#distance between portal pairs
var pre_Channel		#previous Channel		#used to compare channels set in the editor on the fly
export(int, 1, 100, 1) var Channel = 1		#sets the portal channel in editor
export(int, 1,10,1) var max_recursion = 1 	#sets maximum recursion cameras to set
export var size_x = 20.0					#sets portal size
export var size_y = 20.0
export(Color) var color						#sets portal frame and cameras' color
onready var surf = Plane(self.global_transform.basis.z.normalized(),self.global_transform.origin.dot(self.global_transform.basis.z.normalized()))	#a plane set right inside parallel to the portal for the frustum camera to stick on
onready var ren_t = $RenderTargets.get_children()
onready var recs_v = $Recursions.get_children()
onready var size = Vector2(size_x,size_y)
var height		#portal size height

var recs_c := {}

var k = true


#For Diagnostics============================================================================
export(bool) var hidecam = false			#hide mirror camera
#===========================================================================================

func _ready(): 
	add_to_group("portals")
	pre_Channel = Channel	#remembers set channel
	_check_sync(0)
#For Diagnostics=========================================================================================
	if(hidecam==false):

		for cam in recs_v:
		#	cam.get_node("Camera/MeshInstance").get("material/0").set("resource_local_to_scene",true)
			cam.get_node("Camera/MeshInstance").get("material/0").set("albedo_color",color)
			if (cam.name=="View1"):
				cam.get_node("Camera/MeshInstance").get("material/0").set("albedo_color",Color(1.0,1.0,1.0,1.0))
			cam.get_node("Camera/MeshInstance").visible = true

	else:
		for hide in recs_v:
			hide.get_node("Camera/MeshInstance").visible = false
#For Diagnostics=========================================================================================
	var e = 0
	for cam in recs_v: #sifts thru recursion viewports to tidy up cameras
		cam.get_child(0).add_to_group("PortalCams") #each viewport camera is added to group
		cam.get_child(0).global_transform = self.global_transform #sets the cameras at the center of the portal... just to be neat
		cam.get_child(0).rotation.y += PI #turns them around
		recs_c[e] = cam.get_node("Camera") #saves camera to array
		e += 1
	e = 0
	#$DummyCam.rotation.y = PI		#you actually don't need this line anymore, since its already turned around in the scene but I just wanted to get my point accross 
									#having it's rotation preped even before the script ran, actually saved me a lot of process time, beats having to add PI everytime in the "update_cam" function XD


#Checks the total number of portals set in the same channel as this portal
func _check_sync(a):
		for i in range(get_tree().get_nodes_in_group("portals").size()):	#sifts thru portals in the world
			#if a portal is found to have the same channel as this portal (that is not this portal) and as long as it hasn't found more than 2
			if(get_tree().get_nodes_in_group("portals")[i].Channel==Channel && get_tree().get_nodes_in_group("portals")[i]!=self && binds<=1):
				pair = get_tree().get_nodes_in_group("portals")[i]		#we save the portal in 'p' as our pair
				binds += 1	#only increaments if we found another portal with the same channel
						
		_sync(a)


#sync up with portal pair
func _sync(a):

	if(binds == 1):	#If it only found one portal in the same channel
		print(self.name," has one link: ",pair.name)

		if(a!=1):					#this is used to tell this portal's pair to sync up with this
			pair._check_sync(1)		#the "a=1" is used to stop the OTHER portal from going through this function too many times
			render(pair.size_x,pair.size_y) #resizes THIS portal to the size of its paired portal if they're set differently
			height = pair.size_y		#saves pair height size, portal cameras are set to keep height aspect
			
		else:			#this runs only when the OTHER portal calls this portal's 'check_sync()' function with the parameter 'a' set to '1'
			render(size_x,size_y) #the OTHER portal would be telling this portal to stay just the way it is :.)
			height = size_y #keep this portals height

	else:
		if(binds > 1): #if more than one
			print(self.name," has too many links ",binds)
			get_tree().call_group("portals","_unrender",Channel) #switches off portal on the same channel
		if(binds == 0): #if none
			print(self.name," has no link ",binds)
		pair = null #pair is reset to null
		_unrender(Channel) #switches off this portal
	binds = 0 #binds is reset each time this function is called




func _unrender(c):
	if((Channel == c)):
		act = false		#stops update_cam function
		$CSGCombiner.get("material_override").set("albedo_color",Color(0.0,0.0,0.0,1.0)) #sets frame to black to indicate off state
		$CSGCombiner.set_scale(Vector3(size_x/20.0,size_y/20.0,1)) #stretches the portal frame AND the visibilityNotifier AND the Area node all in one go
		for n in ren_t:		#switches off render mesh
			n.visible = false


#Resizes portal and its rendering meshes...but it's mainly for the render meshes so the name still stands
func render(size_X,size_Y):
	act = true		#allows update_cam function to run
	pd = self.global_transform.origin.distance_to(pair.global_transform.origin) #gets the distance between the portal pair
	$CSGCombiner.get("material_override").set("albedo_color",color) #sets the color
	$CSGCombiner.set_scale(Vector3(size_X/20.0,size_Y/20.0,1))  #stretches the portal frame AND the visibilityNotifier AND the Area node all in one go
	for f in recs_v: #sifts thru portal camera's viewport
		f.size = Vector2(size_X,size_Y)*20 #sets each viewport size 20 times bigger than the given portal size
										   #...its the best thing I can do right now for the resolution, pls send help
	for r in max_recursion: #turns on the number of render target for recursions
		ren_t[r].visible = true 
		ren_t[r].material_override.set_shader_param("portal", pair.get_node("Recursions").get_child(r).get_texture()) #'this' portal actually renders what the OTHER portals' camera sees
		ren_t[r].mesh.size = Vector2(size_X,size_Y) #set mesh size
	if(max_recursion<10): #as long as the whole set of 10 isn't used,
		ren_t[max_recursion].visible = false #the last mesh is turned off


func flip_H(behind):
			if(behind):
				print(behind," :behind ",self.name)
				for r in max_recursion:
					ren_t[r].material_override.set_shader_param("flip_h", true)
		
			else:
				print(behind," :behind ",self.name)
				for r in max_recursion:
					ren_t[r].material_override.set_shader_param("flip_h", false)


###Much thanks to JewWithGardenBeans for helping me with recursions: https://github.com/DeleteSystem32/godot-portal-example/blob/master/README.md
###I learned how to to use Frustum culling thru JFonS' example build: https://github.com/JFonS/godot-mirror-example

#note this function is only called by the OTHER portal when the player is looking at THAT portal
func update_cam(pgt):	#updated when player moves, 'pgt' player global transform
	if(act):	#as long as the portal is turned on, this 'acts'
		if(pair!=null): #and as long as there's a pair
			var T = pair.global_transform.inverse() * pgt #saves the position of player relative to the OTHER portal, some how this is better than the 'to_local' function
			T = T.rotated(Vector3(0, 1, 0), PI) #this tracks the movement of the player while 'infront' of the OTHER portal and flips it, to look like the movement is happening behind THAT portal
#			$DummyCam.rotation.y = PI	#This is a Position3D node that's in the middle of this portal but turned around
#			$DummyCam.transform.origin= T.origin #DummyCam gets to position using the saved local transform
			$DummyCam.transform.origin= T.origin

#!!EXPERIMENTAL!!#####################################################
#That means I don't actually know what I'm doing but basically this tells me if I'm behind or infront of the portal
			if(T.origin.z > 0):
				if(k==false): #makes sure this runs only when I get behind it
					k=true   #it prevents it from looping too much
					print("behind: ",pair.name)
			else:

				if(k==true):
					k= false
					print("infront: ",pair.name)
#######################################################################

			for j in range (max_recursion):
					#gets the local position of THIS portal's cameras relative to the OTHER portals' position
					var t = pair.global_transform.inverse() * $Recursions.get_child(j).get_child(0).global_transform

					t = t.rotated(Vector3(0, 1, 0), PI) #turns it around
					#takes the x and y coordinates of THIS portals cameras relative to THIS portals position
					#PC is used for frustum offset
					var PC = Vector2($Recursions.get_child(j).get_child(0).to_local(self.global_transform.origin).x,$Recursions.get_child(j).get_child(0).to_local(self.global_transform.origin).y)
					
					#this sets the cameras in frustum mode
					#height: portal size height
					#PC: XY coordinates for frustum offset, the cameras don't actually rotate they just move their frustum up and down and side to side to keep the near plane parallel to the portal
					
					#the third parameter sets the cameras near plane to stick right behind THIS portal by changing the distance as the camera moves
						#it does this by getting the distance between the portals camera position and the projected position of that camera on the plane:'surf'
						#this makes it so that anything behind the portal gets culled (hiden) from showing up in the render target
					#the last parameter sets the distance of the far plane
					$Recursions.get_child(j).get_child(0).set_frustum(
						height,
						PC,
						surf.project($Recursions.get_child(j).get_child(0).global_transform.origin
							).distance_to($Recursions.get_child(j).get_child(0).global_transform.origin),100000)

					#sets the camera's position to the Dummycam's position
					$Recursions.get_child(j).get_child(0).global_transform = $DummyCam.global_transform
					$DummyCam.transform.origin = t.origin #moves the DummyCam away from THIS portal mimicking the relative position of THIS camera to the OTHER portal



func _on_VisibilityNotifier_camera_entered(camera):
	if((pair!=null)): #as long as THIS portal has a valid pair
		if((camera is PlayerCams)):#and when THIS portal is visible to the player(I used a class name instead to make thing easier, I'll get other things to use class names if I ever get around to using C# or something in the future)
			camera.connect("camera_moved", pair, "update_cam") #THIS portal would call the update_cam function of the OTHER portal
															   #basically telling the OTHER portal to only update when THIS portal is in view... for performance
															   #but I still have to work on the camera's a bit more, 
															   #need to find a way to stop the ones from updating when the they can't see the other portal (ie if they don't contribute to recursions)



func _on_VisibilityNotifier_camera_exited(camera):
	if((camera is PlayerCams)&&(pair!=null)): #screw it I made it into one statement
		camera.disconnect("camera_moved", pair, "update_cam")
		print(self.name," is not visible to a Player ")
 
	#when a new channel and size is set in the editor while running the game
	#the portal updates when the player isn't looking
	if((camera is PlayerCams)&&(Channel != pre_Channel)):
		pre_Channel = Channel #saves new channel setting
		print(self.name," has changed channel\n ")
		if(pair!=null): #if it has a pair it tells it to recheck itself
			pair._check_sync(0)
		_check_sync(0)  #tells THIS portal to re check itself as well
	if(size != Vector2(size_x,size_y)):#when  edited to a new size
		_check_sync(1) #THIS portal recheck's itself to change into its new size without letting the OTHER portal change its size yet
		pair._check_sync(0) #the OTHER portal is then called to copy THIS portals size
		#I had to go thru _check_sync to check if the portals involved are valid for transmission
		print("yeet")	#Yeet
		size = Vector2(size_x,size_y) #remembers new size



func _on_Area_body_entered(body):
#!!EXPERIMENTAL!!#####################################################
#I still don't know what I'm doing
	if(body.is_class("RigidBody")):
		if(self.global_transform.basis.z.normalized().dot(body.linear_velocity.normalized()) < 0): #checks if its moving towards the entrance
			print("yeeting towards ",self.name) #the memes will stop when I finish this
	
	
	
	
	
	
	
	
	
	
