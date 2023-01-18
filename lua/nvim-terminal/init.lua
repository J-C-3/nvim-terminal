M = {}
local config = require("nvim-terminal.config")
local Util = require("nvim-terminal.util")
local Window = require("nvim-terminal.window")
local S = Util.String
local Terminal = require("nvim-terminal.terminal")

M.NewTerminalInstance = function(windowOpts)
    return vim.deepcopy(Terminal:new(Window:new(windowOpts)))
end

M.setup = function(opts)
    config = Util.Lua.merge_tables(config, opts or {})

    if config.terminals == nil then
        return
    end

    if not config.disable_default_keymaps then
        -- setting toggle keymap
        if S.is_not_empty(config.toggle_keymap) then
            vim.keymap.set("n", config.toggle_keymap, function()
                NTGlobal["terminal"]:toggle()
            end, { silent = true })
        end

        -- setting window width keymap
        if S.is_not_empty(config.increase_width_keymap) then
            vim.keymap.set("n", config.increase_width_keymap, function()
                NTGlobal["window"]:change_width(config.window_width_change_amount)
            end, { silent = true })
        end

        -- setting window width keymap
        if S.is_not_empty(config.decrease_width_keymap) then
            vim.keymap.set("n", config.decrease_width_keymap, function()
                NTGlobal["window"]:change_width(-config.window_width_change_amount)
            end, { silent = true })
        end

        -- setting window height keymap
        if S.is_not_empty(config.increase_height_keymap) then
            vim.keymap.set("n", config.increase_height_keymap, function()
                NTGlobal["window"]:change_height(config.window_height_change_amount)
            end, { silent = true })
        end

        -- setting window height keymap
        if S.is_not_empty(config.decrease_height_keymap) then
            vim.keymap.set("n", config.decrease_height_keymap, function()
                NTGlobal["window"]:change_height(-config.window_height_change_amount)
            end, { silent = true })
        end

        for index, term_conf in ipairs(config.terminals) do
            -- setting terminal keymap
            vim.keymap.set("n", term_conf.keymap, function()
                NTGlobal["terminal"]:open(index)
            end, { silent = true })
        end
    end
end

return M
