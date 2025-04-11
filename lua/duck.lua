local M = {}
M.ducks_list = {}
local conf = {character="🦆", speed=10, width=2, height=1, color="none", blend=100}

-- TODO: a mode to wreck the current buffer?
local waddle
local hatch_location
waddle = function(character, duck, speed)
    local timer = vim.loop.new_timer()
    local new_duck = { name = duck, timer = timer }
    table.insert(M.ducks_list, new_duck)

    local waddle_period = 1000 / (speed or conf.speed)
    vim.loop.timer_start(timer, 1000, waddle_period, vim.schedule_wrap(function()
        if vim.api.nvim_win_is_valid(duck) then
            local config = vim.api.nvim_win_get_config(duck)
            local col, row = 0, 0
            if vim.version().minor < 10 then -- Neovim 0.9
                col, row = config["col"][false], config["row"][false]
            else -- Neovim 0.10
                col, row = config["col"], config["row"]
            end

            math.randomseed(os.time()*duck)
            local angle = 2 * math.pi * math.random()
            local s = math.sin(angle)
            local c = math.cos(angle)

            if row < 0 and s < 0 then
              row = vim.o.lines
            end

            if row > vim.o.lines  and s > 0 then
              row = 0
            end

            if col < 0 and c < 0 then
              col = vim.o.columns
            end

            if col > vim.o.columns and c > 0 then
              col = 0
            end

            config["row"] = row + 0.5 * s
            config["col"] = col + 1 * c

            local status, err = pcall(function() vim.api.nvim_win_set_config(duck, config) end)

            if not status then
                local _, _ = pcall(function() M.cook() end)
                hatch_location(character, speed, color, 'editor', row, col)
            end
        end
    end))
end

hatch_location = function(character, speed, color, relative, row, col)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf , 0, 1, true, {character})

    local duck = vim.api.nvim_open_win(buf, false, {
        relative=relative, style='minimal', row=row, col=col, width=conf.width, height=conf.height, focusable=false, border={""}
    })
    vim.cmd("hi Duck"..duck.." guifg=" .. (color or conf.color) .. " guibg=none blend=" .. conf.blend)
    vim.api.nvim_win_set_option(duck, 'winhighlight', 'Normal:Duck'..duck)

    waddle(character, duck, speed)
end

M.hatch = function(character, speed, color)
    hatch_location(character or conf.character, speed, color, 'cursor', 1, 1)
end

M.cook = function()
    local last_duck = M.ducks_list[#M.ducks_list]

    if not last_duck then
        vim.notify("No ducks to cook!")
        return
    end

    local duck = last_duck['name']
    local timer = last_duck['timer']
    table.remove(M.ducks_list, #M.ducks_list)
    timer:stop()

    vim.api.nvim_win_close(duck, true)
end

M.cook_all = function()
    if #M.ducks_list <= 0 then
        vim.notify("No ducks to cook!")
        return
    end

    while (#M.ducks_list > 0) do
        M.cook()
    end
end

M.setup = function(opts)
    conf = vim.tbl_deep_extend('force', conf, opts or {})
end

return M
