local Window = require("nvim-terminal.window")
local Util = require("nvim-terminal.util")

local Terminal = { bufs = {}, last_winid = nil, last_term = nil }

function Terminal:new(window, opt)
    self.window = window or Window:new()
    return self
end

function Terminal:delete(term_number)
    local last = self.last_term
    local count = Util.Lua.len(self.bufs)
    local deleteMe = self.bufs[term_number]

    if count == 1 then
        vim.api.nvim_buf_delete(deleteMe, { force = true })
        self.bufs = {}
        return false
    end

    if term_number <= last then
        last = last - 1
    end

    local temp = {}

    local i = 1
    for _, buf in ipairs(self.bufs) do
        if buf == deleteMe then
            goto continue
        end

        temp[i] = buf

        i = i + 1

        ::continue::
    end

    self.last_term = last

    vim.api.nvim_buf_delete(deleteMe, { force = true })

    self.bufs = temp

    self:open(self.last_term)

    return Util.Lua.len(temp) ~= 0
end

function Terminal:open(term_number)
    term_number = term_number or 1

    local create_win = not self.window:is_valid()
    -- create buffer if it does not exist by the given term_number or the stored
    -- buffer number is no longer valid
    local create_buf = self.bufs[term_number] == nil or not vim.api.nvim_buf_is_valid(self.bufs[term_number])

    -- window and buffer does not exist
    if create_win and create_buf then
        self.last_winid = vim.api.nvim_get_current_win()
        self.window:create_term()
        self.bufs[term_number] = self.window:get_bufno()
        vim.bo[self.bufs[term_number]].buflisted = false
        vim.bo[self.bufs[term_number]].filetype = "toggleterm"
        vim.api.nvim_buf_set_var(self.bufs[term_number], "name", vim.o.shell)

        -- window does not exist but buffer does
    elseif create_win then
        self.last_winid = vim.api.nvim_get_current_win()
        self.window:create(self.bufs[term_number])

        -- buffer does not exist but window does
    elseif create_buf then
        self.window:focus()
        vim.cmd(":terminal")
        self.bufs[term_number] = self.window:get_bufno()
        vim.bo[self.bufs[term_number]].buflisted = false
        vim.bo[self.bufs[term_number]].filetype = "toggleterm"
        vim.api.nvim_buf_set_var(self.bufs[term_number], "name", vim.o.shell)

        -- buffer and window exist
    else
        local curr_term_buf = self.bufs[term_number]
        local last_term_buf = self.bufs[self.last_term]

        if curr_term_buf ~= last_term_buf then
            self.window:set_buf(curr_term_buf)
        end
    end

    self.last_term = term_number
end

function Terminal:close()
    local current_winid = vim.api.nvim_get_current_win()

    if self.window:is_valid() then
        self.window:close()

        if current_winid == self.window.winid then
            vim.api.nvim_set_current_win(self.last_winid)
        end
    end
end

function Terminal:toggle()
    self.last_term = self.last_term and self.last_term or 1

    local opened = self.window:is_valid()

    if opened then
        self:close()
    else
        self:open(self.last_term)
    end
end

function getTabTerminal(tabnr)
    for _, v in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(v)].filetype == "toggleterm" then
            return v
        end
    end
end

function HandleClickTab(minwid, clicks, btn, mods)
    local t = getTabTerminal(vim.api.nvim_get_current_tabpage())
    if t == nil then return end
    t:open(minwid)
    TF.UpdateWinbar()
end

function HandleClickClose(minwid, clicks, btn, mods)
    local t = getTabTerminal(vim.api.nvim_get_current_tabpage())
    if t == nil then return end
    if t:delete(minwid) then
        TF.UpdateWinbar()
    end
end

function Terminal:pickTerm()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    local opts = require("telescope.themes").get_dropdown({})

    local termPretty = {}
    local termBufs = {}
    for i, v in ipairs(self.bufs) do
        table.insert(termPretty, string.format("%d: %s", i, vim.api.nvim_buf_get_var(v, "name")))
        table.insert(termBufs, i)
    end

    pickers.new(opts, {
        prompt_title = "Terminals",
        finder = finders.new_table({
            results = termPretty,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()

                if selection == nil then
                    return
                end

                local nvt = require("nvim-tree.view").is_visible()
                if nvt then
                    require("nvim-tree.api").tree.close()
                end

                self:open(termBufs[selection.index])
                TF.UpdateWinbar()

                if nvt then
                    require("nvim-tree.api").tree.open()
                    vim.cmd("wincmd p")
                end
            end)

            return true
        end,
    }):find()
end

function Terminal:NextTerm()
    if self == nil then
        return
    end

    local nextTerm = self.last_term + 1

    if self.bufs[nextTerm] == nil then
        nextTerm = 1
    end

    self:open(nextTerm)
    TF.UpdateWinbar()
end

function Terminal:PrevTerm()
    if self == nil then
        return
    end

    local nextTerm = self.last_term - 1

    if self.bufs[nextTerm] == nil then
        return
    end

    self:open(nextTerm)
    TF.UpdateWinbar()
end

return Terminal
