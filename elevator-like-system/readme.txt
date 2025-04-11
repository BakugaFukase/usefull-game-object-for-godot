Elevator like system that can be used easily by drop it into your scene. To make it work properly you need add your charactor into group"player" in _onready function to interact with it ,and also need to add 
"	
if on_elevator:
		var elev_vel = on_elevator.velocity
		velocity.x += elev_vel.x/6
		velocity.z += elev_vel.z/6
"
before charactor handle itself's movement.

the first-person-controller is downloaded from assetlib 
