name = "[DEV] 󰀏 Industrial Revolution"
version = "Pre-alpha v0.0.0.0: \"Industrial Revolution\""

description =
version.."\n"..[[

Industrial Revolution is a mod that adds a new niche in the game: Automation

Planned features:
- Winona Rework
- Power management
- Automation
- A new late-game goal.
]]

author = "Atobá Azul"


forumthread = "/topic/111892-announcement-uncompromising-mode/"

api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
hamlet_compatible = false

forge_compatible = false

all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
	"automation",
	"IR",
	"industrial",
	"industrial revolution"
}

priority = -10

------------------------------
-- local functions to makes things prettier

local function Header(title)
	return { name = "", label = title, hover = "", options = { {description = "", data = false}, }, default = false, }
end

local function SkipSpace()
	return { name = "", label = "", hover = "", options = { {description = "", data = false}, }, default = false, }
end

local function BinaryConfig(name, label, hover, default)
    return { name = name, label = label, hover = hover, options = { {description = "Enabled", data = true, hover = "Enabled."}, {description = "Disabled", data = false, hover = "Disabled."}, }, default = default, }
end
------------------------------

configuration_options =
{

}
