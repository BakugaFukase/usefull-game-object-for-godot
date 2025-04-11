extends MeshInstance3D

@export var start_area_path: NodePath  # Inspector 中选择起点区域（Area3D）节点
@export var end_area_path: NodePath    # Inspector 中选择终点区域（Area3D）节点、

@export var start_call_area_path: NodePath  # Inspector 中选择起点召唤区域（Area3D）节点
@export var end_call_area_path: NodePath    # Inspector 中选择终点召唤区域（Area3D）节点

@export var speed: float = 3.0  # 移动速度，单位米/秒

# 内部变量，由 area 的位置确定
var start_position: Vector3
var end_position: Vector3

var velocity: Vector3 = Vector3.ZERO

@export var elevator_area: Area3D
var original_parent: Node = null

@export var ui_manager_path: NodePath  # Inspector中指定 UI 管理器路径

enum ElevatorState { IDLE, MOVING_UP, MOVING_DOWN }
var state = ElevatorState.IDLE
var current_area: String = ""   # 记录当前玩家所在区域："start" 或 "end"

func _ready():
	# 声明局部变量，保存起点与终点区域节点
	var start_area = null
	var end_area = null
	
	var start_call_area = null
	var end_call_area = null
	
	var ui_manager = get_ui_manager()
	if ui_manager:
		ui_manager.hide_instructions()
	
	elevator_area.body_entered.connect(_on_area_body_entered)
	elevator_area.body_exited.connect(_on_area_body_exited)

	# 从 Inspector 指定的 area 节点中读取全局坐标，设置起点与终点
	if start_call_area_path and has_node(start_call_area_path):
		start_call_area = get_node(start_call_area_path)
	else:
		push_error("未指定起点招唤区域！")
	
	if end_call_area_path and has_node(end_call_area_path):
		end_call_area = get_node(end_call_area_path)
	else:
		push_error("未指定终点召唤区域！")
	
	if start_area_path and has_node(start_area_path):
		start_area = get_node(start_area_path)
		start_position = start_area.global_transform.origin
	else:
		push_error("未指定起点区域！")
	
	if end_area_path and has_node(end_area_path):
		end_area = get_node(end_area_path)
		end_position = end_area.global_transform.origin
	else:
		push_error("未指定终点区域！")
	
	# 初始化移动平台位置为起点
	global_transform.origin = start_position
	
	# 连接起点与终点区域的信号
	if start_area:
		start_area.connect("body_entered", Callable(self, "_on_start_area_entered"))
		start_area.connect("body_exited", Callable(self, "_on_start_area_exited"))
	
	if end_area:
		end_area.connect("body_entered", Callable(self, "_on_end_area_entered"))
		end_area.connect("body_exited", Callable(self, "_on_end_area_exited"))
		
	if start_call_area:
		start_call_area.connect("body_entered", Callable(self, "_on_start_call_area_entered"))
		start_call_area.connect("body_exited", Callable(self, "_on_start_call_area_exited"))
	
	if end_call_area:
		end_call_area.connect("body_entered", Callable(self, "_on_end_call_area_entered"))
		end_call_area.connect("body_exited", Callable(self, "_on_end_call_area_exited"))

func _physics_process(delta):
	
	#var old_pos: Vector3 = global_transform.origin
	
	if state == ElevatorState.MOVING_UP:
		move_toward_target(end_position, delta)
	elif state == ElevatorState.MOVING_DOWN:
		move_toward_target(start_position, delta)
	
	#velocity = (global_transform.origin - old_pos) / delta

# 根据目标位置平滑移动
func move_toward_target(target: Vector3, delta: float) -> void:
	var current_pos = global_transform.origin
	var step = speed * delta
	var new_pos = current_pos.move_toward(target, step)
	global_transform.origin = new_pos

	# 如果接近目标，则停止移动
	if new_pos.distance_to(target) < 0.1:
		state = ElevatorState.IDLE
		hide_elevator_ui()
		velocity = Vector3.ZERO
	else:
		# 直接根据状态设置速度向量，不再使用差分计算
		if state == ElevatorState.MOVING_UP:
			# 电梯上行，速度方向为从起点指向终点
			velocity = (end_position - start_position).normalized() * speed
		elif state == ElevatorState.MOVING_DOWN:
			# 电梯下行，速度方向为从终点指向起点
			velocity = (start_position - end_position).normalized() * speed

# 监听输入（假设 F 键映射为 "ui_interact"）
func _input(event):
	if event.is_action_pressed("ui_interact") and state == ElevatorState.IDLE and current_area != "":
#		if current_area == "start":
#			if is_at_start():
#				state = ElevatorState.MOVING_UP
#			else:
#				state = ElevatorState.MOVING_DOWN
#		elif current_area == "end":
#		if is_at_end():
#				state = ElevatorState.MOVING_DOWN
#			else:
#				state = ElevatorState.MOVING_UP
		if current_area == "start" and is_at_start():
			state = ElevatorState.MOVING_UP
		if current_area == "end" and is_at_end():
			state = ElevatorState.MOVING_DOWN
		if current_area == "call at start" and is_at_end():
			state = ElevatorState.MOVING_DOWN
		if current_area == "call at end" and is_at_start():
			state = ElevatorState.MOVING_UP
# 起点区域信号回调
func _on_start_area_entered(body):
	if body.is_in_group("player"):
		current_area = "start"
		show_elevator_ui("起点")

func _on_start_area_exited(body):
	if body.is_in_group("player") and current_area == "start":
		current_area = ""
		hide_elevator_ui()

# 终点区域信号回调
func _on_end_area_entered(body):
	if body.is_in_group("player"):
		current_area = "end"
		show_elevator_ui("终点")

func _on_end_area_exited(body):
	if body.is_in_group("player") and current_area == "end":
		current_area = ""
		hide_elevator_ui()

func _on_start_call_area_entered(body):
	if body.is_in_group("player"):
		current_area = "call at start"
		show_elevator_ui("起点召唤点")

func _on_start_call_area_exited(body):
	if body.is_in_group("player") and current_area == "call at start":
		current_area = ""
		hide_elevator_ui()

func _on_end_call_area_entered(body):
	if body.is_in_group("player"):
		current_area = "call at end"
		show_elevator_ui("终点召唤点")

func _on_end_call_area_exited(body):
	if body.is_in_group("player") and current_area == "call at end":
		current_area = ""
		hide_elevator_ui()

func show_elevator_ui(area_label: String) -> void:
	var ui_manager = get_ui_manager()
	if ui_manager:
		if area_label == "起点" and is_at_start():
			ui_manager.show_instructions("按下 F 键启动升降梯")
		elif area_label == "终点" and is_at_end():
			ui_manager.show_instructions("按下 F 键启动升降梯")
		elif area_label == "起点召唤点" and is_at_end():
			ui_manager.show_instructions("按下 F 键召唤升降梯")
		elif area_label == "终点召唤点" and is_at_start():
			ui_manager.show_instructions("按下 F 键召唤升降梯")

func hide_elevator_ui() -> void:
	var ui_manager = get_ui_manager()
	if ui_manager:
		ui_manager.hide_instructions()


# 判断移动平台是否在起点附近
func is_at_start() -> bool:
	return global_transform.origin.distance_to(start_position) < 0.1

# 判断移动平台是否在终点附近
func is_at_end() -> bool:
	return global_transform.origin.distance_to(end_position) < 0.1

func _on_area_body_entered(body):
	if body.is_in_group("player"):
		body.on_elevator = self  # 将电梯实例传递给玩家，之后玩家在 _physics_process 中可读其 velocity


func _on_area_body_exited(body):
	if body.is_in_group("player"):
		body.on_elevator = null

func get_ui_manager() -> Node:
	if ui_manager_path and has_node(ui_manager_path):
		return get_node(ui_manager_path)
	return null
