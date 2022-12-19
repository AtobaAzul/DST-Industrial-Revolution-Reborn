

GLOBAL.STRINGS.ACTIONS.CASTSPELL.I = "Set Mode: Input"
GLOBAL.STRINGS.ACTIONS.CASTSPELL.O = "Set Mode: Output"
GLOBAL.STRINGS.ACTIONS.CASTSPELL.IO = "Set Mode: Input/Output"
GLOBAL.STRINGS.ACTIONS.CASTSPELL.NONE = "Set Mode: None"


local ACTIONS = GLOBAL.ACTIONS

local _CastSpellStrFn = ACTIONS.CASTSPELL.strfn

ACTIONS.CASTSPELL.strfn = function(act)
    local staff = act.doer.replica.inventory ~= nil and act.doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    if staff ~= nil and staff.prefab == "ir_wrench" then
        return string.lower(staff.mode)
    else
        return _CastSpellStrFn(act)
    end
end