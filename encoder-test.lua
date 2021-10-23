-- twist knobs
-- draw waveforms
-- see code for hysteresis control

-- TODO: make configurable (need UI or something, UGH)
hyst_ms = {50,50,50}

function init()
  print("INIT")

  samp = {{},{},{}}
  start = {1,1,1}
  last_time = {}
  last_sign = {0,0,0}
  --last_abs = {0,0,0}
  -- silly, but simplifies housekeeping
  for e=1,3 do
    for i=1,128 do
      samp[e][i] = 0
      last_time[e] = util.time()
    end
  end

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
  now = util.time()
  delta_time = now - last_time[n]
  last_time[n] = now

  sign = d < 0 and -1 or 1

  -- cold -> hot
  if delta_time > 0.1 then
  end

  -- looks like we caught a JANK
  if sign ~= last_sign[n] and delta_time < hyst_ms[n]/1000 then
    print("JANK DETECTED")
    --d = 0 - d
    --sign = 0 - sign
    return -- just trash it
  end

  print(delta_time, last_sign[n], sign)
  last_sign[n] = sign

  --last_abs[n] = math.abs(d)

  samp[n][start[n]] = d
  start[n] = start[n] % 128 + 1
end

function key(n,v)
  bit = 8 >> n

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

  line = {{},{},{}}
  for e=1,3 do
    for l=1,7 do
      line[e][l] = ""
    end
  end

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
