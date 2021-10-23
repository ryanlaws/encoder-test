-- twist knobs
-- draw waveforms

local samp
local start
local last_time
local key_state
local redraw_clock_id

function init()
  print("INIT")

  samp = {{},{},{}}
  start = {1,1,1}
  -- silly, but simplifies housekeeping
  for e=1,3 do
    for i=1,128 do
      samp[e][i] = 0
    end
  end

  last_time = util.time()
  key_state = 0

  redraw_clock_id = clock.run(function ()
    while true do
      redraw()
      clock.sleep(1/15)
    end
  end)
end

function enc(n, d)
  -- circular buffer
  --print('samp['..n..']['..start[n]..'] = '..d)
  samp[n][start[n]] = d
  start[n] = start[n] % 128 + 1
end

function key(n,v)
  local bit = 8 >> n

  if v == 1 then
    key_state = key_state | bit
  else
    key_state = key_state & (bit ~ 7)
  end

  -- three-finger salute
  if key_state == 7 then rerun() end
end

function redraw()
  screen.clear()

  local line = {{},{},{}}
  for e=1,3 do
    for l=1,7 do
      line[e][l] = ""
    end
  end

  local pixel
  local thresh
  local index

  for i=0,127 do
    for e=1,3 do
      for l=1,7 do
        thresh = l - 4
        pixel = 0
        index = (i + start[e]) % 128 + 1

        if thresh < 0 then
          if samp[e][index] <= thresh then 
            pixel = 1 
          end
        elseif thresh > 0 then
          if samp[e][index] >= thresh then 
            pixel = 1 
          end
        end

        line[e][l] = line[e][l] .. string.char(pixel)
      end
    end
  end

  for e=1,3 do
    for l=1,7 do
      screen.poke(1, e*19+l-9, 128, 1, line[e][l])
    end
  end

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()
  clock.cancel(redraw_clock_id)
end
