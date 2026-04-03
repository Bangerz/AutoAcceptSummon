--[[
  Auto-accepts when C_SummonInfo.GetSummonConfirmTimeLeft() is in (0, threshold],
  where threshold is configurable (default 5 sec, range 5–120 sec). Feedback bar below the summon dialog.
]]

local ADDON_NAME = "AutoAcceptSummon"
local DISPLAY_NAME = "Auto Accept Summon"

local SECONDS_MIN = 5
local SECONDS_MAX = 120
local POLL_INTERVAL = 0.2

AutoAcceptSummonDB = AutoAcceptSummonDB or {}

-- Bar just under the summon prompt (same pattern as Auto Accept Rez)
local feedback = CreateFrame("Frame", "AutoAcceptSummonFeedback", UIParent, "BackdropTemplate")
feedback:SetSize(520, 36)
feedback:SetFrameStrata("FULLSCREEN_DIALOG")
feedback:SetFrameLevel(5000)
feedback:EnableMouse(false)
feedback:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  tile = false,
  tileSize = 0,
  edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 },
})
feedback:SetBackdropColor(0, 0, 0, 0.55)
feedback:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)
local feedbackText = feedback:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
feedbackText:SetPoint("CENTER")
feedbackText:SetText("")
feedback:Hide()

local function clampThreshold(n)
  n = math.floor(tonumber(n) or SECONDS_MIN)
  if n < SECONDS_MIN then
    return SECONDS_MIN
  end
  if n > SECONDS_MAX then
    return SECONDS_MAX
  end
  return n
end

local function getThreshold()
  return clampThreshold(AutoAcceptSummonDB.acceptWhenSecondsLeft)
end

local eventFrame = CreateFrame("Frame")
local activeToken
local ticker

local function summonToken()
  return (C_SummonInfo.GetSummonConfirmSummoner() or "")
    .. "\0"
    .. (C_SummonInfo.GetSummonConfirmAreaName() or "")
end

local function getSummonPopup()
  if StaticPopup_FindVisible then
    return StaticPopup_FindVisible("CONFIRM_SUMMON")
  end
  local name = StaticPopup_Visible and StaticPopup_Visible("CONFIRM_SUMMON")
  return name and _G[name]
end

local function hideFeedback()
  feedback:Hide()
  feedbackText:SetText("")
end

local function updateFeedback()
  if not activeToken then
    hideFeedback()
    return
  end
  if summonToken() ~= activeToken then
    hideFeedback()
    return
  end

  local popup = getSummonPopup()
  if not popup then
    hideFeedback()
    return
  end

  feedback:ClearAllPoints()
  feedback:SetPoint("TOP", popup, "BOTTOM", 0, -8)

  local timeLeft = C_SummonInfo.GetSummonConfirmTimeLeft()
  if timeLeft <= 0 then
    hideFeedback()
    return
  end

  local threshold = getThreshold()
  local inCombat = UnitAffectingCombat("player")

  if timeLeft > threshold then
    local untilAuto = math.max(0, math.ceil(timeLeft - threshold))
    feedbackText:SetFormattedText("Auto Accept Summon: auto-accept in %d sec.", untilAuto)
    feedbackText:SetTextColor(0.85, 0.85, 0.85)
    feedback:Show()
  elseif inCombat then
    feedbackText:SetText("Auto Accept Summon: paused (in combat).")
    feedbackText:SetTextColor(1, 0.82, 0)
    feedback:Show()
  else
    feedbackText:SetText("Auto Accept Summon: accepting…")
    feedbackText:SetTextColor(0.6, 1, 0.6)
    feedback:Show()
  end
end

local function stopWatching()
  if ticker then
    ticker:Cancel()
    ticker = nil
  end
  hideFeedback()
  activeToken = nil
end

local function tryAutoAccept()
  if not activeToken then
    return
  end

  updateFeedback()

  local timeLeft = C_SummonInfo.GetSummonConfirmTimeLeft()
  if timeLeft <= 0 then
    stopWatching()
    return
  end

  local threshold = getThreshold()
  if timeLeft > threshold then
    return
  end

  if UnitAffectingCombat("player") then
    return
  end

  if summonToken() ~= activeToken then
    stopWatching()
    return
  end

  C_SummonInfo.ConfirmSummon()
  StaticPopup_Hide("CONFIRM_SUMMON")
  stopWatching()
end

local function startWatching()
  stopWatching()
  if C_SummonInfo.GetSummonConfirmTimeLeft() <= 0 then
    return
  end
  activeToken = summonToken()
  ticker = C_Timer.NewTicker(POLL_INTERVAL, tryAutoAccept)
  tryAutoAccept()
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CONFIRM_SUMMON")
eventFrame:RegisterEvent("CANCEL_SUMMON")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    AutoAcceptSummonDB.acceptWhenSecondsLeft = clampThreshold(AutoAcceptSummonDB.acceptWhenSecondsLeft or SECONDS_MIN)
  elseif event == "CONFIRM_SUMMON" then
    startWatching()
  elseif event == "CANCEL_SUMMON" then
    stopWatching()
  end
end)

hooksecurefunc("StaticPopup_Show", function(which)
  if which == "CONFIRM_SUMMON" and activeToken then
    C_Timer.After(0, updateFeedback)
  end
end)

SLASH_AUTOACCEPTSUMMON1 = "/autoacceptsummon"
SLASH_AUTOACCEPTSUMMON2 = "/aas"
SlashCmdList["AUTOACCEPTSUMMON"] = function(msg)
  local trimmed = strtrim(msg or "")
  if trimmed == "" then
    print(
      format(
        "|cffedd100%s|r: Auto-accept when the summon has |cffffffff%d|r sec left (allowed: %d–%d). "
          .. "Usage: |cffffffff/aas 30|r",
        DISPLAY_NAME,
        getThreshold(),
        SECONDS_MIN,
        SECONDS_MAX
      )
    )
    return
  end
  local raw = tonumber(trimmed)
  if not raw then
    print(format("|cffedd100%s|r: Invalid number. Example: |cffffffff/aas 15|r", DISPLAY_NAME))
    return
  end
  local n = math.floor(raw + 0.5)
  if n < SECONDS_MIN or n > SECONDS_MAX then
    print(format("|cffedd100%s|r: Use a whole number between %d and %d.", DISPLAY_NAME, SECONDS_MIN, SECONDS_MAX))
    return
  end
  AutoAcceptSummonDB.acceptWhenSecondsLeft = n
  print(format("|cffedd100%s|r: Will auto-accept when |cffffffff%d|r sec remain on the summon.", DISPLAY_NAME, n))
end
