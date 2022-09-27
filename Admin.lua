local flydisabled = false
local customidle = nil
local custommove = nil
if customidle then
	for i, v in pairs(game:GetDescendants()) do
		if v:IsA("Animation") and string.lower(v.Name) == string.lower(customidle) then
			customidle = v
		end
	end
end
if custommove then
	for i, v in pairs(game:GetDescendants()) do
		if v:IsA("Animation") and string.lower(v.Name) == string.lower(custommove) then
			custommove = v
		end
	end
end
local camera = game.Workspace.CurrentCamera;
local tweenserv = game:GetService("TweenService")
local swimidle, swim, jumpID, fallID, idleAnim, moveAnim, lastAnim, animate, humanoid, hrp, character
character = game.Players.LocalPlayer.Character
function loadanims()
	animate = character:FindFirstChild("Animate")
	if animate then
		for i, v in pairs(animate:GetDescendants()) do
			if v:IsA("Animation") then
				if v.Name == "SwimIdle" then
					swimidle = v
				elseif v.Name == "Swim" then
					swim = v
				end
			end
		end
		jumpID = animate:FindFirstChild("jump"):FindFirstChildOfClass("Animation").AnimationId
		fallID = animate:FindFirstChild("fall"):FindFirstChildOfClass("Animation").AnimationId
		if humanoid:FindFirstChild("Animator") then
			if customidle then
				idleAnim = humanoid.Animator:LoadAnimation(customidle)
				idleAnim.Looped = true
			elseif swimidle then
				idleAnim = humanoid.Animator:LoadAnimation(swimidle);
			end
			if custommove then
				moveAnim = humanoid.Animator:LoadAnimation(custommove)
				moveAnim.Looped = true
			elseif swimidle then
				moveAnim = humanoid.Animator:LoadAnimation(swim);
			end
		end
		lastAnim = idleAnim;
	end
end
if character then
	if character:FindFirstChild("HumanoidRootPart") then
		hrp = character:FindFirstChild("HumanoidRootPart")
	end
	if character:FindFirstChild("Humanoid") then
		humanoid = character:FindFirstChild("Humanoid")
	end
	loadanims()
end

game.Players.LocalPlayer.CharacterAdded:Connect(function(chr)
	character = chr
	hrp = chr:WaitForChild("HumanoidRootPart")
	humanoid = chr:WaitForChild("Humanoid")
	local loadhum = coroutine.create(humchanged)
	coroutine.resume(loadhum)
	loadanims()
end)

while character and (not character.Parent) do character.AncestryChanged:Wait(); end

local bodyGyro = Instance.new("BodyGyro");
bodyGyro.maxTorque = Vector3.new(1, 1, 1)*10^6;
bodyGyro.P = 10^6;

local bodyVel = Instance.new("BodyVelocity");
bodyVel.maxForce = Vector3.new(1, 1, 1)*10^6;
bodyVel.P = 10^4;

local isFlying = false;
local isJumping = false;
local isMoving = false;
local isStopped = true;
local movement = {forward = 0, backward = 0, right = 0, left = 0};

-- functions

local function setFlying(flying)
	isFlying = flying;
	bodyGyro.Parent = isFlying and hrp or nil;
	bodyVel.Parent = isFlying and hrp or nil;
	bodyGyro.CFrame = hrp.CFrame;
	bodyVel.Velocity = Vector3.new();

	if (isFlying) then
		lastAnim = isMoving and moveAnim or idleAnim;
		if lastAnim then
			lastAnim:Play();
		end
		if animate then
			animate.jump:FindFirstChildOfClass("Animation").AnimationId = "http://www.roblox.com/asset/?id=0"
			animate.fall:FindFirstChildOfClass("Animation").AnimationId = "http://www.roblox.com/asset/?id=0"
		end
	else
		if lastAnim then
			lastAnim:Stop();
		end
		if animate then
			animate.jump:FindFirstChildOfClass("Animation").AnimationId = jumpID
			animate.fall:FindFirstChildOfClass("Animation").AnimationId = fallID
		end
	end
end

local function onUpdate(dt)
	if (isFlying) then
		local cf = camera.CFrame;
		local direction = cf.rightVector*(movement.right - movement.left) + cf.lookVector*(movement.forward - movement.backward);
		if (direction:Dot(direction) > 0) then
			direction = direction.unit;
		end

		bodyVel.Velocity = direction * humanoid.WalkSpeed * 1.25;

		if not isMoving then
			tweenserv:Create(bodyGyro, TweenInfo.new(1), {CFrame = cf}):Play()
		else
			local newcf
			if movement.right - movement.left ~= 0 then
				if movement.right ~= 0 then
					newcf = cf * CFrame.Angles(0, math.rad(((movement.left-movement.right)*90)-((movement.backward-movement.forward)*45)), 0)
				elseif movement.left ~= 0 then
					newcf = cf * CFrame.Angles(0, math.rad(((movement.left-movement.right)*90)+((movement.backward-movement.forward)*45)), 0)
				end
			else
				newcf = cf * CFrame.Angles(0, math.rad(movement.backward*180), 0)
			end
			tweenserv:Create(bodyGyro, TweenInfo.new(.25), {CFrame = newcf}):Play()
		end
	end
end

local function onKeyRequest(flytype)

	if (not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead) then
		return;
	end

	if flytype == "Stop" then
		setFlying(false);
		isJumping = false;
		isStopped = true;
		if moveAnim and idleAnim then
			moveAnim:Stop();
			idleAnim:Stop();
		end
	elseif flytype == "Start" then
		setFlying(true);
		isStopped = false;
	end
end

local function onStateChange(old, new)
	if (new == Enum.HumanoidStateType.Landed) then	
		isJumping = false;
	elseif (new == Enum.HumanoidStateType.Jumping) then
		isJumping = true;
	end
end

local function movementBind(actionName, inputState, inputObject)
	if (inputState == Enum.UserInputState.Begin) then
		movement[actionName] = 1;
	elseif (inputState == Enum.UserInputState.End) then
		movement[actionName] = 0;
	end

	if (isFlying) then
		isMoving = movement.right + movement.left + movement.forward + movement.backward > 0;

		if isMoving then
			tweenserv:Create(camera, TweenInfo.new(.5), {FieldOfView = 85}):Play()
		else
			tweenserv:Create(camera, TweenInfo.new(.5), {FieldOfView = 70}):Play()
		end
		local checkmoving = movement.left-movement.right ~= 0 or movement.backward-movement.forward ~= 0
		local nextAnim = checkmoving and moveAnim or idleAnim;
		if (nextAnim ~= lastAnim) then
			lastAnim:Stop()
			lastAnim = nextAnim;
			lastAnim:Play(1, -1, 1)
			for i = 1, 10 do
				if not isStopped then
					lastAnim:AdjustWeight(i/10, 0.05)
					wait(.05)
				end
			end
		end
	end

	return Enum.ContextActionResult.Pass;
end

-- connections

local flydb = false
function humchanged()
	humanoid.StateChanged:Connect(onStateChange);
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Q and not gameProcessed and not flydisabled then
		isMoving = humanoid.MoveDirection.Magnitude ~= 0
		if flydb then
			onKeyRequest("Stop")
			flydb = false
		else
			onKeyRequest("Start")
			flydb = true
		end
	end
end)

game:GetService("ContextActionService"):BindAction("forward", movementBind, false, Enum.PlayerActions.CharacterForward);
game:GetService("ContextActionService"):BindAction("backward", movementBind, false, Enum.PlayerActions.CharacterBackward);
game:GetService("ContextActionService"):BindAction("left", movementBind, false, Enum.PlayerActions.CharacterLeft);
game:GetService("ContextActionService"):BindAction("right", movementBind, false, Enum.PlayerActions.CharacterRight);

game:GetService("RunService").RenderStepped:Connect(onUpdate)

local plrgui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local attaching = false
local siphoning = false
local waittime = 0.25
local dialog
for i, v in pairs(game:GetDescendants()) do
	if v:IsA("RemoteEvent") and v.Name == "Dialog" then
		dialog = v
	end
end

game.Players.LocalPlayer.Chatted:Connect(function(msg)
	msg = string.lower(msg)
	if string.sub(msg, 1, 5) == ";goto" then
		msg = msg:sub(7)
		if findplr(msg) then
			local chr = findplr(msg).Character
			character:PivotTo(chr.HumanoidRootPart.CFrame)
		end
	elseif string.sub(msg, 1, 5) == "lacus" then
		msg = msg:sub(7)
		if findchr(msg) then
			local chr = findchr(msg).Parent.Parent.Parent
			character:PivotTo(chr.HumanoidRootPart.CFrame)
		end
	elseif string.sub(msg, 1, 5) == ";view" then
		msg = msg:sub(7)
		if findplr(msg) then
			local chr = findplr(msg).Character
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			workspace.CurrentCamera.CameraSubject = chr.Humanoid
		end
		if findchr(msg) then
			local chr = findchr(msg).Parent.Parent.Parent
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			workspace.CurrentCamera.CameraSubject = chr.Humanoid
		end
	elseif string.sub(msg, 1, 7) == ";unview" then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		workspace.CurrentCamera.CameraSubject = character.Humanoid
	elseif string.match(msg, ";sky") then
		character:PivotTo(character.HumanoidRootPart.CFrame + Vector3.new(0, 1000, 0))
	elseif string.match(msg, ";ground") then
		character:PivotTo(character.HumanoidRootPart.CFrame - Vector3.new(0, 100, 0))
	elseif string.sub(msg, 1, 6) == ";speed" then
		msg = msg:sub(8)
		character.Humanoid.WalkSpeed = msg
	elseif string.sub(msg, 1, 5) == ";jump" then
		msg = msg:sub(7)
		character.Humanoid.JumpPower = msg
		character.Humanoid.JumpHeight = msg^2 / (2 * workspace.Gravity) -- formula for jump height
	elseif string.sub(msg, 1, 3) == ";tp" then
		msg = msg:sub(5)
		for i, v in pairs(game:GetDescendants()) do
			if v:IsA("BasePart") and string.lower(v.Name) == msg then
				character:PivotTo(v.CFrame + Vector3.new(0, 2, 0))
			elseif v:IsA("Model") and string.lower(v.Name) == msg then
				character:PivotTo(v.PrimaryPart.CFrame)
			end
		end
	elseif string.sub(msg, 1, 4) == ";chr" then
		msg = msg:sub(6)
		local folder = game:GetService("StarterGui"):WaitForChild("Menu"):WaitForChild("LocalScript"):WaitForChild("CharLines")
		local first = string.sub(msg, 1, 1)
		first = first:upper()
		msg = first..string.sub(msg, 2, -1)
		if folder:FindFirstChild(msg) then
			local found = false
			for i, text in pairs(workspace:GetDescendants()) do
				if text:IsA("TextLabel") and text.Name == "CharacterName" and text.Text == msg then
					found = true
				end
			end
			if not found then
				for i, v in pairs(game:GetDescendants()) do
					if v:IsA("RemoteEvent") then
						if v.Name == "Character" then
							local cframe = character.HumanoidRootPart.CFrame
							v:FireServer(msg, "Outfit1")
							task.wait(1)
							while task.wait() and not game.Players.LocalPlayer.CharacterAppearanceLoaded do
								-- wait for character to load
							end
							character:PivotTo(cframe)
						end
					end
				end
			end
		end
	elseif string.sub(msg, 1, 5) == ";kill" then
		msg = msg:sub(7)
		if findchr(msg)then
			local chr = findchr(msg).Parent.Parent.Parent
			local cframe = character.HumanoidRootPart.CFrame
			attaching = true
			local startattach = coroutine.create(attach)
			coroutine.resume(startattach, chr)
			task.wait(0.5)
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") then
					if v.Name == "Energy" then
						v:FireServer(-1000) -- refill energy
					end
					if v.Name == "VampireKeybind" then
						v:FireServer(chr, Enum.UserInputType.MouseButton1, "Heart Rip", chr.HumanoidRootPart.CFrame)
					end
				end
			end
			attaching = false
			task.wait()
			character:PivotTo(cframe)
		elseif findplr(msg) then
			local chr = findplr(msg).Character
			local cframe = character.HumanoidRootPart.CFrame
			attaching = true
			local startattach = coroutine.create(attach)
			coroutine.resume(startattach, chr)
			task.wait(0.5)
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") then
					if v.Name == "Energy" then
						v:FireServer(-1000) -- refill energy
					end
					if v.Name == "VampireKeybind" then
						v:FireServer(chr, Enum.UserInputType.MouseButton1, "Heart Rip", chr.HumanoidRootPart.CFrame)
					end
				end
			end
			attaching = false
			task.wait()
			character:PivotTo(cframe)
		end
	elseif string.sub(msg, 1, 5) == ";head" then
		msg = msg:sub(7)
		if findchr(msg)then
			local chr = findchr(msg).Parent.Parent.Parent
			local cframe = character.HumanoidRootPart.CFrame
			attaching = true
			local startattach = coroutine.create(attach)
			coroutine.resume(startattach, chr)
			task.wait(0.5)
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") then
					if v.Name == "Energy" then
						v:FireServer(-1000) -- refill energy
					end
					if v.Name == "VampireKeybind" then
						v:FireServer(chr, Enum.UserInputType.MouseButton1, "Head Rip", chr.HumanoidRootPart.CFrame)
					end
				end
			end
			attaching = false
			task.wait()
			character:PivotTo(cframe)
		elseif findplr(msg) then
			local chr = findplr(msg).Character
			local cframe = character.HumanoidRootPart.CFrame
			attaching = true
			local startattach = coroutine.create(attach)
			coroutine.resume(startattach, chr)
			task.wait(0.5)
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") then
					if v.Name == "Energy" then
						v:FireServer(-1000) -- refill energy
					end
					if v.Name == "VampireKeybind" then
						v:FireServer(chr, Enum.UserInputType.MouseButton1, "Head Rip", chr.HumanoidRootPart.CFrame)
					end
				end
			end
			attaching = false
			task.wait()
			character:PivotTo(cframe)
		end
	elseif string.sub(msg, 1, 7) == ";summon" then
		msg = msg:sub(9)
		if findplr(msg) then
			local istvl
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("TextLabel") and v.Name == "NameChar" then
					istvl = true
				end
			end
			if istvl then
				local chr = findplr(msg).Character
				local cframe = character.HumanoidRootPart.CFrame
				attaching = true
				local startattach = coroutine.create(attach)
				coroutine.resume(startattach, chr)
				task.wait(0.1)
				game.ReplicatedStorage.Events.CharacterSystems.Ictus:FireServer({Target = chr.HumanoidRootPart})
				task.wait(0.75)
				game.ReplicatedStorage.RemoteEvents.CarryRagdoll:FireServer(chr.HumanoidRootPart)
				task.wait(0.125)
				attaching = false
				task.wait(0.125)
				character:PivotTo(cframe)
			end
		end
		if findchr(msg) then
			local istvl
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("TextLabel") and v.Name == "NameChar" then
					istvl = true
				end
			end
			if istvl then
				local chr = findchr(msg).Parent.Parent.Parent
				local cframe = character.HumanoidRootPart.CFrame
				character:PivotTo(chr.HumanoidRootPart.CFrame)
				task.wait(0.1)
				game.ReplicatedStorage.Events.CharacterSystems.Ictus:FireServer({Target = chr.HumanoidRootPart})
				attaching = true
				local startattach = coroutine.create(attach)
				coroutine.resume(startattach, chr)
				task.wait(0.75)
				game.ReplicatedStorage.RemoteEvents.CarryRagdoll:FireServer(chr.HumanoidRootPart)
				task.wait(0.125)
				attaching = false
				task.wait(0.125)
				character:PivotTo(cframe)
			end
		end
	elseif string.sub(msg, 1, 7) == ";siphon" then
		msg = msg:sub(9)
		local event
		if findplr(msg) then
			local chr = findplr(msg).Character
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") and v.Name == "Siphon" then
					event = v
				end
			end
			if event then
				local startsiphoning = coroutine.create(siphon)
				coroutine.resume(startsiphoning, chr, event)
			end
		end
		if findchr(msg) then
			local chr = findchr(msg).Parent.Parent.Parent
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") and v.Name == "Siphon" then
					event = v
				end
			end
			if event then
				local startsiphoning = coroutine.create(siphon)
				coroutine.resume(startsiphoning, chr, event)
			end
		end
	elseif msg == ";stop" then
		siphoning = false
	elseif string.sub(msg, 1, 4) == ";var" then
		msg = msg:sub(6)
		waittime = msg
	elseif msg == ";passive" then
		local event
		for i, v in pairs(game:GetDescendants()) do
			if v:IsA("RemoteEvent") and v.Name == "Siphon" then
				event = v
			end
		end
		if event then
			local startsiphoning = coroutine.create(passive)
			coroutine.resume(startsiphoning, event)
		end
	elseif string.sub(msg, 1, 6) == ";stake" then
		msg = msg:sub(8)
		local respawn
		local morph
		local stake
		if findplr(msg) then
			local chr = findplr(msg).Character
			if character:FindFirstChildWhichIsA("Tool") then
				for i, v in pairs(game:GetDescendants()) do
					if v:IsA("RemoteEvent") and v.Name == "Stake" then
						local cframe = character.HumanoidRootPart.CFrame
						character:PivotTo(chr.HumanoidRootPart.CFrame)
						task.wait(0.2)
						v:FireServer(chr, "Original")
						task.wait(0.1)
						character:PivotTo(cframe)
					end
				end
			end
		end
	elseif msg == ";getstake" then
		local respawn
		local morph
		if dialog then
			dialog:FireServer("Stake")
		end
		if not dialog then
			if not game.Players.LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool") then
				for i, v in pairs(game:GetDescendants()) do
					if v:IsA("RemoteEvent") then
						if v.Name == "Respawn" then
							respawn = v
						elseif v.Name == "Morph" then
							morph = v
						end
					end
				end
				while not game.Players.LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool") do
					respawn:FireServer()
					task.wait(1.5)
					morph:FireServer("Mortal")
					task.wait(0.5)
				end
			end
		end
	elseif msg == ";findtools" then
		local cframe = character.HumanoidRootPart.CFrame
		for i, v in pairs(workspace:GetChildren()) do
			if v:IsA("Tool") and v.Name ~= "Heart" then
				character:PivotTo(v.Handle.CFrame)
				task.wait()
			end
			character:PivotTo(cframe)
		end
	elseif msg == ";cure" then
		local cframe = character.HumanoidRootPart.CFrame
		character:PivotTo(CFrame.new(684.647156, -12.2312202, 470.537628, 0.352202594, 0, 0.935923815, 0, 1, 0, -0.935923815, 0, 0.352202594))
		task.wait(5)
		character:PivotTo(cframe)
	elseif msg == ";turn" then
		if dialog then
			for i, v in pairs(workspace:GetDescendants()) do
				if v.Parent.Name == "Interactables" and v:FindFirstChild("HumanoidRootPart") then
					if v.HumanoidRootPart.CFrame == CFrame.new(-6.293396, 2.59430313, -354.34787, -0.511033654, 0, 0.859560847, 0, 1, 0, -0.859560847, 0, -0.511033654) then
						dialog:FireServer("TurnVampire", v)
					end
				end
			end
		end
	elseif msg == ";heal" then
		if dialog then
			for i, v in pairs(workspace:GetDescendants()) do
				if v.Parent.Name == "Interactables" and v:FindFirstChild("HumanoidRootPart") then
					if v.HumanoidRootPart.CFrame == CFrame.new(-56.6536102, 13.9026957, 60.2701302, 0.891115725, 0, 0.453776121, 0, 1, 0, -0.453776121, 0, 0.891115725) then
						dialog:FireServer("Healing", v)
					end
				end
			end
		end
	elseif msg == ";blood" then
		local cframe = character.HumanoidRootPart.CFrame
		character:PivotTo(CFrame.new(-749.365234, 13.1201143, 510.599823, 9.47713852e-06, 0.997051895, 0.076730296, -1, 9.47713852e-06, 3.65078449e-07, -3.65078449e-07, -0.076730296, 0.997051895))
		task.wait(3)
		character:PivotTo(cframe)
	elseif string.sub(msg, 1, 4) == ";cam" then
		msg = msg:sub(6)
		if findplr(msg) then
			local chr = findplr(msg).Character
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			workspace.CurrentCamera.CFrame = chr.HumanoidRootPart.CFrame + chr.HumanoidRootPart.CFrame.LookVector * -10 + Vector3.new(0, 5, 0)
		end
		if findchr(msg) then
			local chr = findchr(msg).Parent.Parent.Parent
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			workspace.CurrentCamera.CFrame = chr.HumanoidRootPart.CFrame + chr.HumanoidRootPart.CFrame.LookVector * -10 + Vector3.new(0, 5, 0)
		end
	elseif msg == ";nowhere" then
		character:PivotTo(CFrame.new(Vector3.new(25000, 10000, 25000)))
	elseif msg == ";all" then
		local stake
		if character:FindFirstChildWhichIsA("Tool") then
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") and v.Name == "Stake" then
					stake = v
				end
			end
			for i, v in pairs(workspace.Live:GetChildren()) do
				if v:FindFirstChild("Humanoid") and v ~= character then
					stake:FireServer(v, "Original")
				end
			end
		end
	end
end)

function attach(chr)
	while attaching and task.wait() do
		character:PivotTo(chr.HumanoidRootPart.CFrame)
	end
end

function siphon(chr, event)
	siphoning = true
	if character:FindFirstChild("Stats") and character.Stats:FindFirstChild("Magic") then
		local magic = character.Stats.Magic:FindFirstChild("Magic")
		if magic.Value >= 250 then
			for i, v in pairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") and v.Name == "SpellEvent" then
					v:FireServer("invisique", nil, character.HumanoidRootPart.CFrame)
					v:FireServer("resistus maledi", nil, character.HumanoidRootPart.CFrame)
				end
			end
		end
	end
	while task.wait() and siphoning do
		event:FireServer("Siphon", "start", chr)
		task.wait(3.1)
	end
	event:FireServer("Siphon", "stop", chr)
end

function passive(event)
	local cframe = character.HumanoidRootPart.CFrame
	siphoning = true
	local tomb = workspace.Map.Interactables:FindFirstChild("TombDoor")
	if not tomb then
		character:PivotTo(CFrame.new(Vector3.new(670, -11, 570)))
		task.wait(1)
		character:PivotTo(cframe)
		tomb = workspace.Map.Interactables:FindFirstChild("TombDoor")
	end
	while task.wait() and siphoning and tomb do
		character:PivotTo(tomb.CFrame)
		task.wait(1)
		event:FireServer("Siphon", "start", tomb, tomb, false)
		task.wait(0.5)
		character:PivotTo(cframe)
		task.wait(2.51)
	end
	event:FireServer("Siphon", "stop", tomb, tomb, false)
end

function findplr(str)
	for i, v in pairs(game.Players:GetPlayers()) do
		if str.match(str, (string.lower(v.Name)):sub(1, #str)) then
			return v
		end 
	end
end

function findchr(str)
	for i, v in pairs(workspace:GetDescendants()) do
		if v:IsA("TextLabel") and v.Name == "CharacterName" then -- TVO
			if str == string.sub(string.lower(v.Text), 1, #str) then
				return v
			end
		elseif v:IsA("TextLabel") and v.Name == "NameChar" then -- TVL
			if str == string.sub(string.lower(v.Text), 1, #str) then
				return v
			end
		end
	end
end