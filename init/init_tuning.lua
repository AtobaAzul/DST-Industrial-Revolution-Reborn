local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end


local seg_time = 30

local day_segs = 10
local dusk_segs = 4
local night_segs = 2

local day_time = seg_time * day_segs
local total_day_time = seg_time * 16

local day_time = seg_time * day_segs
local dusk_time = seg_time * dusk_segs
local night_time = seg_time * night_segs

TUNING = GLOBAL.TUNING

TUNING.IR =
{

}
print("Loaded init_tuning successfully.")