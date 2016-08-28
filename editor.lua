local gui_bg = default and default.gui_bg or ""
local gui_bg_img = default and default.gui_bg_img or ""
local contexts = {}

editor.editor = {}
function editor.editor:new(ref)
	ref = ref or {}
	setmetatable(ref, self)
	self.__index = self
	self._buttons = {}
	self._button_map = {}
	self._context = {}

	local filesys = editor.filesystem:new()
	filesys:write("init.lua", "-- this is a test\nprint(\"test\")")
	filesys:write("depends.txt", "default")
	self.default_filesystem = filesys

	self:register_button("New", function(name, context)
		print("New button pressed!")
	end)

	self:register_button("Save", function(name, context)
		print("Save button pressed!")
	end)

	self:register_button("Close", function(name, context)
		print("Close button pressed!")
	end)

	return ref
end

function editor.editor:register_button(name, callback)
	self._buttons[#self._buttons + 1] = name
	self._button_map[name] = callback
end

function editor.editor:get_formspec(name, context)
	local fs = "size[12,6.75]" .. gui_bg .. gui_bg_img
	fs = fs .. "textarea[3.25,0.8;9,7.2;text;;default text]"

	for i = 1, #self._buttons do
		local btn = self._buttons[i]
		fs = fs .. "button[" .. (2 + 1.05 * i) .. ",-0.15;1.2,1;btn_" ..
			btn:lower() .. ";" .. btn .. "]"
	end
	return fs
end

function editor.editor:show(name, formname)
	self._context[name] = self._context[name] or {
		filesystem = self.default_filesystem:clone_filesystem(),
		open = "init.lua",
		minimised = {
			"depends.txt"
		},
		buffer = {}
	}
	minetest.show_formspec(name, formname, self:get_formspec(name, self._context[name]))
end

function editor.editor:on_event(name, fields)
	local context = self._context[name] or {}

	for i = 1, #self._buttons do
		local btn = self._buttons[i]
		context.buffer[context.open] = fields.text
		print(fields.text)
		if fields["btn_" .. btn:lower()] then
			self._button_map[btn](name, context)
		end
	end
end
