local M = {}

local last_cpu_sample
local boot_time_cache
local battery_path_cache

local function term_cmd(cmd)
	local result = vim.fn.system({ "sh", "-c", cmd })
	if vim.v.shell_error ~= 0 then
		return ""
	end
	return vim.trim(result)
end

local function system_type()
	if vim.fn.has("wsl") == 1 then
		return "wsl"
	end

	local sysname = (vim.uv or vim.loop).os_uname().sysname:lower()
	if sysname:find("darwin") then
		return "darwin"
	end
	if sysname:find("linux") then
		return "linux"
	end
	if sysname:find("windows") then
		return "windows"
	end
	return "unknown"
	end

local function read_file(path)
	local fd = vim.uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end
	local stat = vim.uv.fs_fstat(fd)
	local size = stat and stat.size or 0
	local data = vim.uv.fs_read(fd, size > 0 and size or 65536, 0)
	vim.uv.fs_close(fd)
	return data
	end

local function linux_cpu_percent()
	local stat = read_file("/proc/stat")
	if not stat then
		return nil
	end
	local line = stat:match("([^\n]+)")
	if not line then
		return nil
	end
	local fields = {}
	for value in line:gmatch("%S+") do
		table.insert(fields, value)
	end
	if #fields < 5 or fields[1] ~= "cpu" then
		return nil
	end
	local values = {}
	for i = 2, #fields do
		values[i - 1] = tonumber(fields[i]) or 0
	end
	local idle = (values[4] or 0) + (values[5] or 0)
	local total = 0
	for _, value in ipairs(values) do
		total = total + value
	end

	local percent = 0
	if last_cpu_sample then
		local total_delta = total - last_cpu_sample.total
		local idle_delta = idle - last_cpu_sample.idle
		if total_delta > 0 then
			percent = math.floor((((total_delta - idle_delta) / total_delta) * 100) + 0.5)
		end
	end
	last_cpu_sample = { idle = idle, total = total }
	return percent
	end

local function linux_memory_stats()
	local meminfo = read_file("/proc/meminfo")
	if not meminfo then
		return nil, nil, nil, nil
	end
	local total_kb = tonumber(meminfo:match("MemTotal:%s+(%d+)"))
	local available_kb = tonumber(meminfo:match("MemAvailable:%s+(%d+)"))
	local swap_total_kb = tonumber(meminfo:match("SwapTotal:%s+(%d+)")) or 0
	local swap_free_kb = tonumber(meminfo:match("SwapFree:%s+(%d+)")) or 0
	if not total_kb or not available_kb then
		return nil, nil, nil, nil
	end
	local total = total_kb * 1024
	local used = (total_kb - available_kb) * 1024
	local swap_total = swap_total_kb * 1024
	local swap_used = (swap_total_kb - swap_free_kb) * 1024
	return used, total, swap_used, swap_total
	end

local function linux_disk_stats()
	local output = vim.fn.system({ "df", "-B1", "/" })
	if vim.v.shell_error ~= 0 then
		return nil, nil
	end
	local lines = vim.split(vim.trim(output), "\n", { plain = true })
	local line = lines[2]
	if not line then
		return nil, nil
	end
	local parts = {}
	for value in line:gmatch("%S+") do
		table.insert(parts, value)
	end
	return tonumber(parts[3]), tonumber(parts[2])
	end

local function linux_boot_time()
	if boot_time_cache then
		return boot_time_cache
	end
	local stat = read_file("/proc/stat")
	if not stat then
		return nil
	end
	local boot = tonumber(stat:match("btime%s+(%d+)"))
	if not boot then
		return nil
	end
	boot_time_cache = boot
	return boot_time_cache
	end

local function battery_path()
	if battery_path_cache ~= nil then
		return battery_path_cache ~= false and battery_path_cache or nil
	end
	local entries = vim.fn.glob("/sys/class/power_supply/*", false, true)
	for _, entry in ipairs(entries) do
		local kind = read_file(entry .. "/type")
		if kind and vim.trim(kind) == "Battery" then
			battery_path_cache = entry
			return entry
		end
	end
	battery_path_cache = false
	return nil
	end

local function battery_stats()
	local path = battery_path()
	if not path then
		return nil
	end
	local capacity = read_file(path .. "/capacity")
	if not capacity then
		return nil
	end
	local status = read_file(path .. "/status")
	return {
		capacity = tonumber(vim.trim(capacity)),
		status = status and vim.trim(status) or nil,
	}
	end

local function format_duration(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local days = math.floor(seconds / 86400)
	seconds = seconds % 86400
	local hours = math.floor(seconds / 3600)
	seconds = seconds % 3600
	local minutes = math.floor(seconds / 60)
	if days > 0 then
		return string.format("%dd %02dh %02dm", days, hours, minutes)
	end
	return string.format("%02dh %02dm", hours, minutes)
	end

local function lightweight_stats()
	local system = system_type()
	if system ~= "linux" and system ~= "wsl" then
		return nil
	end

	local memory_used, memory_total, swap_used, swap_total = linux_memory_stats()
	local disk_used, disk_total = linux_disk_stats()
	local boot_time = linux_boot_time()
	local cpu = linux_cpu_percent()
	local battery = battery_stats()

	return {
		cpu = cpu,
		memory_used = memory_used,
		memory_total = memory_total,
		swap_used = swap_used,
		swap_total = swap_total,
		disk_used = disk_used,
		disk_total = disk_total,
		boot_time = boot_time and os.date("%Y-%m-%d %H:%M:%S", boot_time) or nil,
		uptime = boot_time and format_duration(os.time() - boot_time) or nil,
		battery = battery,
	}
	end

local function format_gib(value)
	if not value then
		return nil
	end
	return string.format("%.1fG", value / 1024 / 1024 / 1024)
	end

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
	end

local function make_bar(percent, width)
	percent = clamp(tonumber(percent) or 0, 0, 100)
	width = width or 18
	local filled = math.floor(((percent / 100) * width) + 0.5)
	return string.rep("=", filled) .. string.rep("-", width - filled)
	end

local function battery_icon(capacity, status)
	if status and (status == "Charging" or status == "Full") then
		return "󰂄"
	end
	local icons = {
		"󰂎",
		"󰁺",
		"󰁻",
		"󰁼",
		"󰁽",
		"󰁾",
		"󰁿",
		"󰂀",
		"󰂁",
		"󰂂",
		"󰁹",
	}
	local idx = math.max(1, math.min(#icons, math.floor((tonumber(capacity or 0) / 10) + 1)))
	return icons[idx]
	end

local function pad_right(text, width)
	text = tostring(text or "")
	if #text >= width then
		return text:sub(1, width)
	end
	return text .. string.rep(" ", width - #text)
	end

local function line_width(text)
	return vim.api.nvim_strwidth(text)
	end

local function fit_text(text, width)
	text = tostring(text or "")
	if line_width(text) <= width then
		return text .. string.rep(" ", width - line_width(text))
	end
	if width <= 1 then
		return text:sub(1, width)
	end
	local out = ""
	for _, char in ipairs(vim.fn.split(text, "\\zs")) do
		if line_width(out .. char .. "…") > width then
			break
		end
		out = out .. char
	end
	return out .. "…" .. string.rep(" ", width - line_width(out .. "…"))
	end

local function stat_row(label, value, icon, percent)
	local label_width = 6
	local value_width = 19
	local graph_width = 16
	local graph = fit_text(string.format("%s %s", icon, make_bar(percent, 13)), graph_width)
	return string.format(
		"│ %s │ %s │ %s │",
		fit_text(label, label_width),
		fit_text(value, value_width),
		graph
	)
	end

local function info_stat_row(label, value, icon)
	local label_width = 6
	local value_width = 19
	local info_width = 16
	return string.format(
		"│ %s │ %s │ %s │",
		fit_text(label, label_width),
		fit_text(value, value_width),
		fit_text(icon or "", info_width)
	)
	end


local function memory_percent(stats)
	if not stats.memory_used or not stats.memory_total or stats.memory_total == 0 then
		return nil
	end
	return (stats.memory_used / stats.memory_total) * 100
	end

local function disk_percent(stats)
	if not stats.disk_used or not stats.disk_total or stats.disk_total == 0 then
		return nil
	end
	return (stats.disk_used / stats.disk_total) * 100
	end

local function swap_percent(stats)
	if not stats.swap_used or not stats.swap_total or stats.swap_total == 0 then
		return nil
	end
	return (stats.swap_used / stats.swap_total) * 100
	end

local function os_label()
	local system = system_type()
	if system == "darwin" then
		local name = term_cmd("sw_vers -productName")
		local version = term_cmd("sw_vers -productVersion")
		if name ~= "" and version ~= "" then
			return "macOS " .. name .. " " .. version
		end
		return "macOS"
	end

	if system == "linux" or system == "wsl" then
		local pretty = term_cmd("[ -r /etc/os-release ] && . /etc/os-release && printf '%s' \"$PRETTY_NAME\"")
		if pretty ~= "" then
			if system == "wsl" then
				return pretty .. " (WSL)"
			end
			return pretty
		end
	end

	if system == "wsl" then
		return "Windows Subsystem for Linux"
	end

	return system
	end

local function version_label()
	local version = vim.version()
	return string.format("Neovim %d.%d.%d", version.major, version.minor, version.patch)
	end

local function info_line()
	return os_label() .. " | " .. version_label()
	end

function M.stats_card()
	local stats = lightweight_stats()
	if not stats then
		return table.concat({
			"╭────────┬─────────────────────┬──────────────────╮",
			info_stat_row("INFO", "stats unavailable", ""),
			"╰────────┴─────────────────────┴──────────────────╯",
			"",
			os.date("%a. %d %b %Y %H:%M:%S"),
		}, "\n")
	end

	local lines = {
		"╭────────┬─────────────────────┬──────────────────╮",
	}

	if stats.cpu then
		table.insert(lines, stat_row("CPU", string.format("%d%%", stats.cpu), "", stats.cpu))
	end

	if stats.memory_used and stats.memory_total then
		table.insert(
			lines,
			stat_row(
				"RAM",
				string.format("%s / %s", format_gib(stats.memory_used), format_gib(stats.memory_total)),
				"",
				memory_percent(stats)
			)
		)
	end

	if stats.swap_total and stats.swap_total > 0 then
		table.insert(
			lines,
			stat_row(
				"SWAP",
				string.format("%s / %s", format_gib(stats.swap_used), format_gib(stats.swap_total)),
				"󰯍",
				swap_percent(stats)
			)
		)
	end

	if stats.disk_used and stats.disk_total then
		table.insert(
			lines,
			stat_row(
				"DISK",
				string.format("%s / %s", format_gib(stats.disk_used), format_gib(stats.disk_total)),
				"",
				disk_percent(stats)
			)
		)
	end

	if stats.uptime then
		table.insert(lines, info_stat_row("UPTIME", stats.uptime, "󰅐"))
	end

	if stats.battery and stats.battery.capacity then
		table.insert(
			lines,
			stat_row(
				"BAT",
				string.format("%d%% %s", stats.battery.capacity, (stats.battery.status or ""):gsub("Unknown", "")),
				battery_icon(stats.battery.capacity, stats.battery.status),
				stats.battery.capacity
			)
		)
	end

	table.insert(lines, "╰────────┴─────────────────────┴──────────────────╯")
	table.insert(lines, "")
	table.insert(lines, os.date("%a. %d %b %Y %H:%M:%S"))
	return table.concat(lines, "\n")
	end

function M.stats_card_lines()
	return vim.split(M.stats_card(), "\n", { plain = true })
	end

function M.stats_card_block_lines(width)
	local lines = M.stats_card_lines()
	local size = M.stats_card_size()
	width = width or size.width
	local centered = {}
	for _, line in ipairs(lines) do
		if line == "" then
			centered[#centered + 1] = string.rep(" ", width)
		else
			local content_width = line_width(line)
			local left = math.max(0, math.floor((width - content_width) / 2))
			local right = math.max(0, width - content_width - left)
			centered[#centered + 1] = string.rep(" ", left) .. line .. string.rep(" ", right)
		end
	end
	return centered
	end

function M.stats_card_virtual_lines(width)
	local lines = M.stats_card_block_lines(width)
	local virt_lines = {}
	for _, line in ipairs(lines) do
		virt_lines[#virt_lines + 1] = { { line, "Special" } }
	end
	return virt_lines
	end

function M.stats_card_size()
	local lines = M.stats_card_lines()
	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, vim.api.nvim_strwidth(line))
	end
	return {
		width = width,
		height = #lines,
	}
	end

local header_art = {
	"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
	"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
	"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
	"██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
	"██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
	"╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
}

local header_art_orange = {
	"███╗   ██╗███████╗ ██████╗ ",
	"████╗  ██║██╔════╝██╔═══██╗",
	"██╔██╗ ██║█████╗  ██║   ██║",
	"██║╚██╗██║██╔══╝  ██║   ██║",
	"██║ ╚████║███████╗╚██████╔╝",
	"╚═╝  ╚═══╝╚══════╝ ╚═════╝ ",
}

local header_art_rest = {
	"██╗   ██╗██╗███╗   ███╗",
	"██║   ██║██║████╗ ████║",
	"██║   ██║██║██╔████╔██║",
	"╚██╗ ██╔╝██║██║╚██╔╝██║",
	" ╚████╔╝ ██║██║ ╚═╝ ██║",
	"  ╚═══╝  ╚═╝╚═╝     ╚═╝",
}

function M.header()
	local lines = vim.list_extend(vim.deepcopy(header_art), { "" })
	table.insert(lines, info_line())
	return table.concat(lines, "\n")
	end

function M.header_text()
	local text = {}
	for i = 1, #header_art_orange do
		text[#text + 1] = { header_art_orange[i], hl = "Special" }
		text[#text + 1] = { header_art_rest[i] .. "\n", hl = "Title" }
	end
	text[#text + 1] = { "\n", hl = "Title" }
	text[#text + 1] = { info_line(), hl = "Title" }
	return text
	end

function M.dotfiles_root()
	return vim.fs.normalize(vim.fn.expand("~/dotfiles"))
	end

function M.in_git_repo()
	local output = vim.fn.system({ "git", "rev-parse", "--show-toplevel" })
	return vim.v.shell_error == 0 and vim.trim(output) ~= ""
	end

function M.git_branch()
	local output = vim.fn.system({ "git", "branch", "--show-current" })
	if vim.v.shell_error ~= 0 then
		return nil
	end
	output = vim.trim(output)
	return output ~= "" and output or nil
	end

function M.git_status_title()
	local branch = M.git_branch()
	if branch then
		return "Git Status [" .. branch .. "]"
	end
	return "Git Status"
	end

function M.git_status_text()
	local output = vim.fn.system({ "sh", "-c", "git --no-pager diff --stat -B -M -C && git status --short --renames" })
	if vim.v.shell_error ~= 0 then
		return "Git status unavailable"
	end
	output = vim.trim(output)
	if output == "" then
		return "Working tree clean"
	end
	return output
	end

local function diff_segments(symbols)
	local segments = {}
	local current_hl
	local chunk = ""
	for char in symbols:gmatch(".") do
		local hl = char == "+" and "Added" or char == "-" and "Error" or "Comment"
		if current_hl and hl ~= current_hl then
			table.insert(segments, { chunk, hl = current_hl })
			chunk = ""
		end
		current_hl = hl
		chunk = chunk .. char
	end
	if chunk ~= "" then
		table.insert(segments, { chunk, hl = current_hl })
	end
	return segments
	end

local function git_code_hl(code)
	if code:find("%?") or code:find("A") then
		return "Added"
	end
	if code:find("D") then
		return "Error"
	end
	if code:find("M") or code:find("R") then
		return "Special"
	end
	return "Comment"
	end

local function append_diff_item(items, path, count, symbols)
	local max_width = 48
	local suffix_width = vim.api.nvim_strwidth("| " .. count .. " " .. symbols)
	local path_width = vim.api.nvim_strwidth(path)
	if path_width + 1 + suffix_width <= max_width then
		local text = {
			{ path .. " ", hl = "file" },
			{ "| ", hl = "Comment" },
			{ count .. " ", hl = "Number" },
		}
		vim.list_extend(text, diff_segments(symbols))
		table.insert(items, { text = text, indent = 2 })
		return
	end

	table.insert(items, { text = { { path, hl = "file" } }, indent = 2 })
	local wrapped = {
		{ "| ", hl = "Comment" },
		{ count .. " ", hl = "Number" },
	}
	vim.list_extend(wrapped, diff_segments(symbols))
	table.insert(items, { text = wrapped, indent = 4 })
	end

local function append_status_item(items, code, file)
	local max_width = 48
	if vim.api.nvim_strwidth(code .. " " .. file) <= max_width then
		table.insert(items, {
			text = {
				{ code .. " ", hl = git_code_hl(code) },
				{ file, hl = "file" },
			},
			indent = 2,
		})
		return
	end

	table.insert(items, { text = { { code, hl = git_code_hl(code) } }, indent = 2 })
	table.insert(items, { text = { { file, hl = "file" } }, indent = 4 })
	end

function M.git_status_items()
	local output = M.git_status_text()
	if output == "Git status unavailable" or output == "Working tree clean" then
		return {
			{ text = { { output, hl = output == "Working tree clean" and "Special" or "Error" } }, indent = 2, padding = 1 },
		}
	end

	local items = {}
	local lines = vim.split(output, "\n", { plain = true })
	for _, line in ipairs(lines) do
		local path, count, symbols = line:match("^(.-)%s+|%s+(%d+)%s+([+%-]+)$")
		if path and count and symbols then
			append_diff_item(items, path, count, symbols)
		elseif line:match("files? changed") then
			table.insert(items, { text = { { line, hl = "Comment" } }, indent = 2 })
		else
			local code, file = line:match("^(%S+)%s+(.+)$")
			if code and file then
				append_status_item(items, code, file)
			else
				table.insert(items, { text = { { line, hl = "Comment" } }, indent = 2 })
			end
		end
	end
	if items[#items] then
		items[#items].padding = 1
	end
	return items
	end

return M
