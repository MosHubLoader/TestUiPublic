--// U Hub - giao diện Luau (LocalScript)
--// Đặt vào: StarterPlayer > StarterPlayerScripts (hoặc StarterGui)
--// Nút tròn chữ U kéo thả được, bấm hoặc nhấn phím U để đóng mở lắc lư.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("UHub") then
	playerGui.UHub:Destroy()
end

--// ===== Theme =====
local THEMES = {
	{ name = "Hồng cam", a = Color3.fromRGB(255, 77, 141), b = Color3.fromRGB(255, 159, 69) },
	{ name = "Xanh ngọc", a = Color3.fromRGB(25, 211, 197), b = Color3.fromRGB(123, 228, 149) },
	{ name = "Tím hồng", a = Color3.fromRGB(155, 107, 255), b = Color3.fromRGB(255, 107, 214) },
	{ name = "Xanh trời", a = Color3.fromRGB(58, 160, 255), b = Color3.fromRGB(89, 227, 255) },
	{ name = "Vàng chanh", a = Color3.fromRGB(255, 194, 51), b = Color3.fromRGB(255, 122, 61) },
}
local C = {
	panel = Color3.fromRGB(20, 15, 29),
	panel2 = Color3.fromRGB(32, 25, 45),
	row = Color3.fromRGB(38, 31, 52),
	text = Color3.fromRGB(241, 238, 247),
	muted = Color3.fromRGB(154, 145, 173),
	accentA = THEMES[1].a,
	accentB = THEMES[1].b,
}

local state = {
	open = false,
	busy = false,
	wobble = true,
	scaleBase = 1,
	winCenter = nil, -- UDim2 (offset)
}

--// ===== Helpers =====
local function make(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(r)
	return make("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(color, transparency, thickness)
	return make("UIStroke", {
		Color = color,
		Transparency = transparency or 0.9,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local accentGradients = {}
local accentFns = {}

local function accentGradient(rotation)
	local g = make("UIGradient", {
		Color = ColorSequence.new(C.accentA, C.accentB),
		Rotation = rotation or 45,
	})
	table.insert(accentGradients, g)
	return g
end

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function applyTheme(theme)
	C.accentA, C.accentB = theme.a, theme.b
	for _, g in ipairs(accentGradients) do
		g.Color = ColorSequence.new(theme.a, theme.b)
	end
	for _, fn in ipairs(accentFns) do
		fn()
	end
end

--// ===== ScreenGui =====
local gui = make("ScreenGui", {
	Name = "UHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
})

--// ===== Thông báo nhỏ =====
local toastHolder = make("Frame", {
	Name = "Toasts",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(300, 150),
	BackgroundTransparency = 1,
	ZIndex = 50,
}, {
	make("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
toastHolder.Parent = gui

local function toast(msg)
	local t = make("TextLabel", {
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.1,
		Text = msg,
		TextColor3 = C.text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		ZIndex = 51,
	}, {
		corner(10),
		stroke(C.accentA, 0.45, 1),
		make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
	})
	t.Parent = toastHolder
	task.delay(1.8, function()
		if t.Parent then
			tween(t, 0.3, { BackgroundTransparency = 1, TextTransparency = 1 })
			task.wait(0.32)
			t:Destroy()
		end
	end)
end

--// ===== Cửa sổ =====
local win = make("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(580, 380),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.06,
	Visible = false,
	ZIndex = 10,
}, {
	corner(20),
	stroke(Color3.new(1, 1, 1), 0.88, 1),
})
local winScale = make("UIScale", { Scale = 1 })
winScale.Parent = win
win.Parent = gui

-- vầng sáng góc cửa sổ
local glow = make("Frame", {
	Size = UDim2.fromOffset(260, 260),
	Position = UDim2.new(1, -170, 0, -150),
	BackgroundColor3 = C.accentA,
	BackgroundTransparency = 0.82,
	BorderSizePixel = 0,
	ZIndex = 9,
}, { corner(130) })
glow.Parent = win
table.insert(accentFns, function()
	glow.BackgroundColor3 = C.accentA
end)

local clip = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 10,
}, { corner(20) })
clip.Parent = win

-- thanh tiêu đề
local bar = make("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 52),
	BackgroundTransparency = 1,
	ZIndex = 12,
})
bar.Parent = clip

local logo = make("TextLabel", {
	Position = UDim2.fromOffset(16, 11),
	Size = UDim2.fromOffset(30, 30),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Text = "U",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBlack,
	TextSize = 16,
	ZIndex = 13,
}, { corner(10), accentGradient(45) })
logo.Parent = bar

make("TextLabel", {
	Parent = bar,
	Position = UDim2.fromOffset(56, 0),
	Size = UDim2.new(1, -140, 1, 0),
	BackgroundTransparency = 1,
	Text = "U Hub",
	TextColor3 = C.text,
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 13,
})

local function titleButton(text, xOffset)
	local b = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, xOffset, 0, 11),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = C.panel2,
		Text = text,
		TextColor3 = C.muted,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
		ZIndex = 13,
	}, { corner(10) })
	b.Parent = bar
	return b
end
local btnClose = titleButton("✕", -14)
local btnMin = titleButton("–", -50)

make("Frame", {
	Parent = clip,
	Position = UDim2.fromOffset(0, 52),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0,
	ZIndex = 12,
})

-- sidebar tab
local sidebar = make("Frame", {
	Name = "Sidebar",
	Position = UDim2.fromOffset(0, 53),
	Size = UDim2.new(0, 150, 1, -53),
	BackgroundTransparency = 1,
	ZIndex = 11,
}, {
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}),
})
sidebar.Parent = clip

local indicator = make("Frame", {
	Name = "Indicator",
	Size = UDim2.new(0, 130, 0, 40),
	Position = UDim2.fromOffset(10, 12),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.78,
	ZIndex = 10,
}, { corner(12), accentGradient(45), stroke(C.accentA, 0.5, 1) })
indicator.Parent = clip -- nằm dưới các nút tab nhờ ZIndex

local contentArea = make("Frame", {
	Name = "Content",
	Position = UDim2.fromOffset(150, 53),
	Size = UDim2.new(1, -150, 1, -53),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 11,
})
contentArea.Parent = clip

make("Frame", {
	Parent = clip,
	Position = UDim2.fromOffset(150, 53),
	Size = UDim2.new(0, 1, 1, -53),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.92,
	BorderSizePixel = 0,
	ZIndex = 12,
})

--// ===== Trang và thành phần =====
local pages, tabButtons, tabIcons = {}, {}, {}
local currentTab

local function newPage(name, title, subtitle)
	local page = make("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.muted,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 12,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		make("UIPadding", {
			PaddingTop = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
		}),
	})
	page.Parent = contentArea

	local head = make("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 0, ZIndex = 13 })
	head.Parent = page
	make("TextLabel", {
		Parent = head,
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = C.text,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	})
	make("TextLabel", {
		Parent = head,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = subtitle,
		TextColor3 = C.muted,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
	})
	pages[name] = page
	return page
end

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function rowFrame(parent, height)
	local r = make("Frame", {
		Size = UDim2.new(1, 0, 0, height or 52),
		BackgroundColor3 = C.row,
		BackgroundTransparency = 0.35,
		LayoutOrder = nextOrder(),
		ZIndex = 13,
	}, { corner(14), stroke(Color3.new(1, 1, 1), 0.92, 1) })
	r.Parent = parent
	return r
end

local function rowLabels(row, title, sub)
	make("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, sub and 9 or 0),
		Size = UDim2.new(1, -90, 0, sub and 18 or 52),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = C.text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 14,
	})
	if sub then
		make("TextLabel", {
			Parent = row,
			Position = UDim2.fromOffset(14, 27),
			Size = UDim2.new(1, -90, 0, 16),
			BackgroundTransparency = 1,
			Text = sub,
			TextColor3 = C.muted,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 14,
		})
	end
end

local function addToggle(page, title, sub, default, callback)
	local row = rowFrame(page, 52)
	rowLabels(row, title, sub)
	local on = default and true or false

	local track = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(44, 25),
		BackgroundColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(70, 62, 88),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 14,
	}, { corner(13) })
	local grad = accentGradient(0)
	grad.Enabled = on
	grad.Parent = track
	track.Parent = row

	local knob = make("Frame", {
		Size = UDim2.fromOffset(19, 19),
		Position = on and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 15,
	}, { corner(10) })
	knob.Parent = track

	local function set(v, silent)
		on = v
		grad.Enabled = on
		tween(track, 0.25, { BackgroundColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(70, 62, 88) })
		tween(knob, 0.35, { Position = on and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3) },
			Enum.EasingStyle.Back)
		if not silent then
			toast(title .. ": " .. (on and "Bật" or "Tắt"))
		end
		if callback then
			task.spawn(callback, on)
		end
	end
	track.MouseButton1Click:Connect(function()
		set(not on)
	end)
	if callback then
		task.spawn(callback, on)
	end
	return { Set = set }
end

local activeSlider -- slider đang kéo
local function addSlider(page, title, min, max, default, callback)
	local row = rowFrame(page, 66)
	make("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -90, 0, 18),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = C.text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 14,
	})
	local valueLabel = make("TextLabel", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.fromOffset(60, 18),
		BackgroundTransparency = 1,
		Text = tostring(default),
		TextColor3 = C.accentB,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 14,
	})
	table.insert(accentFns, function()
		valueLabel.TextColor3 = C.accentB
	end)

	local track = make("TextButton", {
		Position = UDim2.fromOffset(14, 42),
		Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Color3.fromRGB(70, 62, 88),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 14,
	}, { corner(3) })
	track.Parent = row

	local fill = make("Frame", {
		Size = UDim2.fromScale((default - min) / (max - min), 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 15,
	}, { corner(3), accentGradient(0) })
	fill.Parent = track

	local knob = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 16,
	}, { corner(8), stroke(C.accentB, 0.4, 3) })
	knob.Parent = track

	local value = default
	local function update(x)
		local alpha = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		value = math.floor(min + (max - min) * alpha + 0.5)
		local a = (value - min) / (max - min)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
		if callback then
			callback(value)
		end
	end
	local entry = { update = update }
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			activeSlider = entry
			tween(knob, 0.15, { Size = UDim2.fromOffset(20, 20) }, Enum.EasingStyle.Back)
			update(input.Position.X)
		end
	end)
	entry.release = function()
		tween(knob, 0.2, { Size = UDim2.fromOffset(16, 16) }, Enum.EasingStyle.Back)
	end
	if callback then
		callback(default)
	end
end

local function addButton(page, title, sub, buttonText, callback)
	local row = rowFrame(page, 52)
	rowLabels(row, title, sub)
	local b = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(72, 30),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = buttonText,
		TextColor3 = Color3.fromRGB(26, 13, 22),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 14,
	}, { corner(10), accentGradient(45) })
	b.Parent = row
	b.MouseEnter:Connect(function()
		tween(b, 0.2, { Size = UDim2.fromOffset(78, 32) }, Enum.EasingStyle.Back)
	end)
	b.MouseLeave:Connect(function()
		tween(b, 0.2, { Size = UDim2.fromOffset(72, 30) })
	end)
	b.MouseButton1Click:Connect(function()
		callback()
	end)
end

--// ===== Tab =====
local function moveIndicator(btn, instant)
	local y = btn.AbsolutePosition.Y - clip.AbsolutePosition.Y
	local goal = { Position = UDim2.fromOffset(10, y) }
	if instant then
		indicator.Position = goal.Position
	else
		tween(indicator, 0.45, goal, Enum.EasingStyle.Back)
	end
end

local function selectTab(name, instant)
	if currentTab == name then
		return
	end
	currentTab = name
	for n, page in pairs(pages) do
		page.Visible = (n == name)
	end
	for n, btn in pairs(tabButtons) do
		local active = n == name
		tween(btn, 0.25, { TextColor3 = active and C.text or C.muted })
		tween(tabIcons[n], 0.25, { TextTransparency = active and 0 or 0.45 })
		if active then
			moveIndicator(btn, instant)
		end
	end
	local page = pages[name]
	page.Position = UDim2.fromOffset(0, 14)
	page.CanvasPosition = Vector2.new()
	tween(page, 0.45, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
end

local function addTab(name, icon, label, order_)
	local btn = make("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Text = "      " .. label,
		TextColor3 = C.muted,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		LayoutOrder = order_,
		ZIndex = 14,
	}, { make("UIPadding", { PaddingLeft = UDim.new(0, 14) }) })
	btn.Parent = sidebar
	local ic = make("TextLabel", {
		Position = UDim2.fromOffset(-2, 0),
		Size = UDim2.fromOffset(24, 40),
		BackgroundTransparency = 1,
		Text = icon,
		TextColor3 = C.text,
		TextTransparency = 0.45,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		ZIndex = 15,
	})
	ic.Parent = btn
	tabButtons[name], tabIcons[name] = btn, ic

	btn.MouseEnter:Connect(function()
		tween(ic, 0.3, { Rotation = -12, TextSize = 19 }, Enum.EasingStyle.Back)
	end)
	btn.MouseLeave:Connect(function()
		tween(ic, 0.3, { Rotation = 0, TextSize = 16 })
	end)
	btn.MouseButton1Click:Connect(function()
		selectTab(name)
	end)
end

--// ===== Nội dung các tab =====
addTab("home", "⌂", "Trang chính", 1)
addTab("player", "☻", "Nhân vật", 2)
addTab("visual", "◉", "Hiển thị", 3)
addTab("tp", "⌖", "Dịch chuyển", 4)
addTab("set", "⚙", "Cài đặt", 5)

-- Trang chính
do
	local p = newPage("home", "Trang chính", "Tổng quan nhanh và các nút hay dùng.")
	order = 0

	local hello = make("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8,
		LayoutOrder = nextOrder(),
		ZIndex = 13,
	}, { corner(16), accentGradient(30), stroke(C.accentA, 0.55, 1) })
	hello.Parent = p
	make("TextLabel", {
		Parent = hello,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 22),
		BackgroundTransparency = 1,
		Text = "Chào mừng đến U Hub, " .. player.DisplayName,
		TextColor3 = C.text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 14,
	})
	make("TextLabel", {
		Parent = hello,
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 0, 28),
		BackgroundTransparency = 1,
		Text = "Kéo thanh tiêu đề để di chuyển, bấm chữ U hoặc phím U để đóng mở.",
		TextColor3 = C.muted,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 14,
	})

	-- số liệu thật: FPS và ping
	local tiles = make("Frame", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		ZIndex = 13,
	}, {
		make("UIGridLayout", {
			CellSize = UDim2.new(0.333, -6, 1, 0),
			CellPadding = UDim2.fromOffset(8, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	tiles.Parent = p
	local function tile(label, order_)
		local t = make("Frame", {
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.35,
			LayoutOrder = order_,
			ZIndex = 13,
		}, { corner(14), stroke(Color3.new(1, 1, 1), 0.92, 1) })
		t.Parent = tiles
		make("TextLabel", {
			Parent = t,
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -24, 0, 14),
			BackgroundTransparency = 1,
			Text = string.upper(label),
			TextColor3 = C.muted,
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 14,
		})
		return make("TextLabel", {
			Parent = t,
			Position = UDim2.fromOffset(12, 24),
			Size = UDim2.new(1, -24, 0, 30),
			BackgroundTransparency = 1,
			Text = "--",
			TextColor3 = C.text,
			Font = Enum.Font.Code,
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 14,
		})
	end
	local fpsLabel, pingLabel, upLabel = tile("FPS", 1), tile("Ping", 2), tile("Phiên", 3)

	local frames, acc, started = 0, 0, os.clock()
	RunService.Heartbeat:Connect(function(dt)
		frames += 1
		acc += dt
		if acc >= 0.5 then
			fpsLabel.Text = tostring(math.floor(frames / acc + 0.5))
			frames, acc = 0, 0
			local ok, ping = pcall(function()
				return player:GetNetworkPing() * 2000
			end)
			pingLabel.Text = ok and (tostring(math.floor(ping)) .. " ms") or "--"
			local s = math.floor(os.clock() - started)
			upLabel.Text = string.format("%02d:%02d", s // 60, s % 60)
		end
	end)

	addButton(p, "Thử hiệu ứng lắc", "Cửa sổ lắc lư một lần", "Lắc thử", function()
		task.spawn(function()
			for _, rot in ipairs({ -1.6, 1.3, -0.8, 0.4, 0 }) do
				tween(win, 0.09, { Rotation = rot }, Enum.EasingStyle.Sine).Completed:Wait()
			end
		end)
		toast("Lắc lắc lắc")
	end)
end

-- Nhân vật: chỉnh chính nhân vật của bạn (dùng khi test game của mình)
do
	local p = newPage("player", "Nhân vật", "Tùy chỉnh chỉ số nhân vật của bạn.")
	order = 0
	local function humanoid()
		local char = player.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end
	addSlider(p, "Tốc độ chạy", 16, 100, 16, function(v)
		local h = humanoid()
		if h then
			h.WalkSpeed = v
		end
	end)
	addSlider(p, "Độ cao nhảy", 50, 200, 50, function(v)
		local h = humanoid()
		if h then
			h.UseJumpPower = true
			h.JumpPower = v
		end
	end)
	local infJump = false
	addToggle(p, "Nhảy liên tục", "Không giới hạn số lần nhảy", false, function(v)
		infJump = v
	end)
	UserInputService.JumpRequest:Connect(function()
		local h = humanoid()
		if infJump and h then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
	addToggle(p, "Chạy nhanh", "Ví dụ công tắc, tự nối chức năng", false, nil)
end

-- Hiển thị
do
	local p = newPage("visual", "Hiển thị", "Làm cho màn hình dễ nhìn hơn.")
	order = 0
	local Lighting = game:GetService("Lighting")
	local camera = workspace.CurrentCamera
	addToggle(p, "Sáng toàn cảnh", "Tăng độ sáng môi trường", false, function(v)
		Lighting.Brightness = v and 3 or 2
	end)
	addSlider(p, "Tầm nhìn (FOV)", 40, 120, 70, function(v)
		if camera then
			camera.FieldOfView = v
		end
	end)
	addToggle(p, "Hiện tên", "Ví dụ công tắc, tự nối chức năng", true, nil)
end

-- Dịch chuyển: danh sách điểm đến, sửa lại theo game của bạn
do
	local p = newPage("tp", "Dịch chuyển", "Chọn điểm đến trong danh sách.")
	order = 0
	local places = {
		{ "Điểm xuất phát", Vector3.new(0, 10, 0) },
		{ "Tháp đồng hồ", Vector3.new(120, 10, 40) },
		{ "Bãi biển", Vector3.new(-200, 10, 90) },
		{ "Đỉnh núi", Vector3.new(60, 150, -300) },
	}
	for _, place in ipairs(places) do
		addButton(p, place[1], "Tọa độ đã đặt sẵn", "Đi", function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = CFrame.new(place[2])
				toast("Đã tới: " .. place[1])
			end
		end)
	end
end

-- Cài đặt
do
	local p = newPage("set", "Cài đặt", "Màu sắc và hiệu ứng của giao diện.")
	order = 0

	local row = rowFrame(p, 78)
	make("TextLabel", {
		Parent = row,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 18),
		BackgroundTransparency = 1,
		Text = "Màu chủ đạo",
		TextColor3 = C.text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 14,
	})
	local swatchHolder = make("Frame", {
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -28, 0, 30),
		BackgroundTransparency = 1,
		ZIndex = 14,
	}, { make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }) })
	swatchHolder.Parent = row
	for _, theme in ipairs(THEMES) do
		local s = make("TextButton", {
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 15,
		}, {
			corner(14),
			make("UIGradient", { Color = ColorSequence.new(theme.a, theme.b), Rotation = 45 }),
		})
		s.Parent = swatchHolder
		s.MouseEnter:Connect(function()
			tween(s, 0.25, { Size = UDim2.fromOffset(32, 32), Rotation = -8 }, Enum.EasingStyle.Back)
		end)
		s.MouseLeave:Connect(function()
			tween(s, 0.25, { Size = UDim2.fromOffset(28, 28), Rotation = 0 })
		end)
		s.MouseButton1Click:Connect(function()
			applyTheme(theme)
			toast("Màu: " .. theme.name)
		end)
	end

	addToggle(p, "Hiệu ứng lắc lư", "Khi đóng và mở cửa sổ", true, function(v)
		state.wobble = v
	end)
	addSlider(p, "Độ đục của kính", 30, 100, 94, function(v)
		win.BackgroundTransparency = 1 - v / 100
	end)
	local keyRow = rowFrame(p, 52)
	rowLabels(keyRow, "Phím tắt", "Mở hoặc đóng cửa sổ")
	make("TextLabel", {
		Parent = keyRow,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(30, 26),
		BackgroundColor3 = C.panel2,
		Text = "U",
		TextColor3 = C.text,
		Font = Enum.Font.Code,
		TextSize = 14,
		ZIndex = 14,
	}, { corner(8) })
end

--// ===== Nút tròn chữ U =====
local orb = make("TextButton", {
	Name = "Orb",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(60, 60),
	Position = UDim2.new(1, -52, 1, -56),
	BackgroundColor3 = Color3.fromRGB(18, 12, 26),
	Text = "U",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBlack,
	TextSize = 28,
	AutoButtonColor = false,
	ZIndex = 30,
}, { corner(30) })
local orbStroke = make("UIStroke", {
	Thickness = 3,
	Color = Color3.new(1, 1, 1),
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
orbStroke.Parent = orb
local ringGradient = make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.accentA),
		ColorSequenceKeypoint.new(0.5, C.accentB),
		ColorSequenceKeypoint.new(1, C.accentA),
	}),
})
ringGradient.Parent = orbStroke
local letterGradient = accentGradient(45)
letterGradient.Parent = orb
-- chữ U dùng gradient của chính nút: nền nút tối nên đặt gradient lên TextLabel riêng
letterGradient.Parent = nil

local letter = make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "U",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBlack,
	TextSize = 28,
	ZIndex = 31,
}, { accentGradient(45) })
letter.Parent = orb
orb.Text = ""
orb.Parent = gui

table.insert(accentFns, function()
	ringGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.accentA),
		ColorSequenceKeypoint.new(0.5, C.accentB),
		ColorSequenceKeypoint.new(1, C.accentA),
	})
end)

RunService.RenderStepped:Connect(function(dt)
	ringGradient.Rotation = (ringGradient.Rotation + dt * 90) % 360
end)

--// ===== Đóng mở lắc lư =====
local function orbCenter()
	return orb.AbsolutePosition + orb.AbsoluteSize / 2
end

local function computeScaleBase()
	local vp = gui.AbsoluteSize
	state.scaleBase = math.clamp(math.min((vp.X - 24) / 580, (vp.Y - 24) / 380), 0.4, 1)
end

local function playOpen()
	if state.busy then
		return
	end
	state.busy = true
	state.open = true
	computeScaleBase()
	local base = state.scaleBase
	local vp = gui.AbsoluteSize
	state.winCenter = state.winCenter or UDim2.fromOffset(vp.X / 2, vp.Y / 2)

	local oc = orbCenter()
	win.Rotation = -18
	winScale.Scale = 0.1
	win.Position = UDim2.fromOffset(oc.X, oc.Y)
	win.Visible = true
	moveIndicator(tabButtons[currentTab], true)

	if not state.wobble then
		win.Rotation = 0
		winScale.Scale = base
		win.Position = state.winCenter
		state.busy = false
		return
	end

	tween(win, 0.6, { Position = state.winCenter }, Enum.EasingStyle.Back)
	task.spawn(function()
		local steps = {
			{ 1.1 * base, 7, 0.2 },
			{ 0.94 * base, -5, 0.12 },
			{ 1.035 * base, 2.6, 0.12 },
			{ 0.99 * base, -1.2, 0.1 },
			{ base, 0, 0.1 },
		}
		for _, s in ipairs(steps) do
			tween(win, s[3], { Rotation = s[2] }, Enum.EasingStyle.Sine)
			tween(winScale, s[3], { Scale = s[1] }, Enum.EasingStyle.Sine).Completed:Wait()
		end
		state.busy = false
	end)
end

local function playClose()
	if state.busy then
		return
	end
	state.busy = true
	state.open = false
	local oc = orbCenter()
	task.spawn(function()
		if state.wobble then
			tween(win, 0.12, { Rotation = -4 }, Enum.EasingStyle.Sine)
			tween(winScale, 0.12, { Scale = state.scaleBase * 1.05 }, Enum.EasingStyle.Sine).Completed:Wait()
			tween(win, 0.38, { Rotation = 20, Position = UDim2.fromOffset(oc.X, oc.Y) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			tween(winScale, 0.38, { Scale = 0.08 }, Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed:Wait()
		end
		win.Visible = false
		state.busy = false
	end)
end

local function toggleWindow()
	if state.open then
		playClose()
	else
		playOpen()
	end
end

btnClose.MouseButton1Click:Connect(playClose)
btnMin.MouseButton1Click:Connect(function()
	playClose()
	toast("Đã thu gọn về chữ U")
end)
for _, b in ipairs({ btnClose, btnMin }) do
	b.MouseEnter:Connect(function()
		tween(b, 0.2, { TextColor3 = C.text, BackgroundColor3 = b == btnClose and Color3.fromRGB(220, 60, 80) or C.row })
	end)
	b.MouseLeave:Connect(function()
		tween(b, 0.2, { TextColor3 = C.muted, BackgroundColor3 = C.panel2 })
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.U then
		toggleWindow()
	end
end)

--// ===== Kéo thả: cửa sổ, nút U, thanh trượt =====
local dragWin, dragOrb -- { start = Vector2, origin = Vector2, moved = bool }

bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragWin = {
			start = Vector2.new(input.Position.X, input.Position.Y),
			origin = Vector2.new(win.Position.X.Offset, win.Position.Y.Offset),
		}
	end
end)

orb.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragOrb = {
			start = Vector2.new(input.Position.X, input.Position.Y),
			origin = orbCenter(),
			moved = false,
		}
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local pos = Vector2.new(input.Position.X, input.Position.Y)
	local vp = gui.AbsoluteSize

	if activeSlider then
		activeSlider.update(pos.X)
	end
	if dragWin and not state.busy then
		local p = dragWin.origin + (pos - dragWin.start)
		local halfW, halfH = 290 * state.scaleBase, 190 * state.scaleBase
		p = Vector2.new(math.clamp(p.X, halfW * 0.4, vp.X - halfW * 0.4), math.clamp(p.Y, halfH * 0.3, vp.Y - halfH * 0.3))
		win.Position = UDim2.fromOffset(p.X, p.Y)
		state.winCenter = win.Position
	end
	if dragOrb then
		local delta = pos - dragOrb.start
		if dragOrb.moved or delta.Magnitude > 6 then
			dragOrb.moved = true
			local p = dragOrb.origin + delta
			orb.Position = UDim2.fromOffset(math.clamp(p.X, 34, vp.X - 34), math.clamp(p.Y, 34, vp.Y - 34))
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if activeSlider then
		activeSlider.release()
		activeSlider = nil
	end
	dragWin = nil
	if dragOrb then
		local wasMove = dragOrb.moved
		dragOrb = nil
		if not wasMove then
			toggleWindow()
		end
	end
end)

-- nút U nảy nhẹ khi rê chuột và lắc định kỳ lúc cửa sổ đóng
orb.MouseEnter:Connect(function()
	tween(orb, 0.3, { Size = UDim2.fromOffset(66, 66) }, Enum.EasingStyle.Back)
end)
orb.MouseLeave:Connect(function()
	tween(orb, 0.3, { Size = UDim2.fromOffset(60, 60) })
end)
task.spawn(function()
	while gui.Parent do
		task.wait(5)
		if not state.open and not dragOrb then
			for _, rot in ipairs({ -16, 12, -8, 4, 0 }) do
				tween(orb, 0.1, { Rotation = rot }, Enum.EasingStyle.Sine).Completed:Wait()
			end
		end
	end
end)

--// ===== Khởi động =====
gui.Parent = playerGui
selectTab("home", true)
task.wait(0.1)
playOpen()
