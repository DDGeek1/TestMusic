local dfpwm = require("cc.audio.dfpwm")

local leftSpk = assert(peripheral.wrap("left"), "No speaker on left")
local rightSpk = assert(peripheral.wrap("right"), "No speaker on right")
local speakers = { leftSpk, rightSpk }

local mon = peripheral.wrap("top")
local w, h = 0, 0
if mon then
  mon.setTextScale(1)
  mon.setBackgroundColor(colors.black)
  mon.clear()
  mon.setCursorPos(2, 2)
  mon.setTextColor(colors.lime)
  mon.write("NOW PLAYING: kids.dfpwm")
  w, h = mon.getSize()
end

local url = "https://raw.githubusercontent.com/DDGeek1/TestMusic/main/kids.dfpwm"
local handle = assert(http.get(url, nil, true), "Failed to fetch kids.dfpwm")
local decoder = dfpwm.make_decoder()

while true do
  local chunk = handle.read(32 * 1024)
  if not chunk then break end
  local buffer = decoder(chunk)

  if mon then
    local peak = 0
    for i = 1, #buffer, 64 do
      local v = math.abs(buffer[i])
      if v > peak then peak = v end
    end
    local barWidth = math.floor((peak / 128) * (w - 4))
    mon.setCursorPos(2, 4)
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", w - 4))
    mon.setCursorPos(2, 4)
    mon.setBackgroundColor(colors.cyan)
    mon.write(string.rep(" ", math.max(1, barWidth)))
    mon.setBackgroundColor(colors.black)
  end

  while true do
    local all_accepted = true
    for _, spk in ipairs(speakers) do
      if not spk.playAudio(buffer) then
        all_accepted = false
      end
    end
    if all_accepted then break end
    os.pullEvent("speaker_audio_empty")
  end
end

handle.close()
