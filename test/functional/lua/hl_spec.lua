local t = require('test.testutil')
local n = require('test.functional.testnvim')()
local Screen = require('test.functional.ui.screen')

local exec_lua = n.exec_lua
local eq = t.eq
local eval = n.eval
local command = n.command
local clear = n.clear
local api = n.api

describe('vim.hl.range', function()
  local screen

  before_each(function()
    clear()
    screen = Screen.new(60, 6)
    screen:add_extra_attr_ids({
      [100] = { foreground = Screen.colors.Blue, background = Screen.colors.Yellow, bold = true },
    })
    api.nvim_set_option_value('list', true, {})
    api.nvim_set_option_value('listchars', 'eol:$', {})
    api.nvim_buf_set_lines(0, 0, -1, true, {
      'asdfghjkl',
      '«口=口»',
      'qwertyuiop',
      '口口=口口',
      'zxcvbnm',
    })
    screen:expect([[
      ^asdfghjkl{1:$}                                                  |
      «口=口»{1:$}                                                    |
      qwertyuiop{1:$}                                                 |
      口口=口口{1:$}                                                  |
      zxcvbnm{1:$}                                                    |
                                                                  |
    ]])
  end)

  it('works with charwise selection', function()
    exec_lua(function()
      local ns = vim.api.nvim_create_namespace('')
      vim.hl.range(0, ns, 'Search', { 1, 5 }, { 3, 10 })
    end)
    screen:expect([[
      ^asdfghjkl{1:$}                                                  |
      «口{10:=口»}{100:$}                                                    |
      {10:qwertyuiop}{100:$}                                                 |
      {10:口口=口}口{1:$}                                                  |
      zxcvbnm{1:$}                                                    |
                                                                  |
    ]])
  end)

  it('works with linewise selection', function()
    exec_lua(function()
      local ns = vim.api.nvim_create_namespace('')
      vim.hl.range(0, ns, 'Search', { 0, 0 }, { 4, 0 }, { regtype = 'V' })
    end)
    screen:expect([[
      {10:^asdfghjkl}{100:$}                                                  |
      {10:«口=口»}{100:$}                                                    |
      {10:qwertyuiop}{100:$}                                                 |
      {10:口口=口口}{100:$}                                                  |
      {10:zxcvbnm}{100:$}                                                    |
                                                                  |
    ]])
  end)

  it('works with blockwise selection', function()
    exec_lua(function()
      local ns = vim.api.nvim_create_namespace('')
      vim.hl.range(0, ns, 'Search', { 0, 0 }, { 4, 4 }, { regtype = '\022' })
    end)
    screen:expect([[
      {10:^asdf}ghjkl{1:$}                                                  |
      {10:«口=}口»{1:$}                                                    |
      {10:qwer}tyuiop{1:$}                                                 |
      {10:口口}=口口{1:$}                                                  |
      {10:zxcv}bnm{1:$}                                                    |
                                                                  |
    ]])
  end)

  it('works with blockwise selection with width', function()
    exec_lua(function()
      local ns = vim.api.nvim_create_namespace('')
      vim.hl.range(0, ns, 'Search', { 0, 4 }, { 4, 7 }, { regtype = '\0226' })
    end)
    screen:expect([[
      ^asdf{10:ghjkl}{1:$}                                                  |
      «口={10:口»}{1:$}                                                    |
      qwer{10:tyuiop}{1:$}                                                 |
      口口{10:=口口}{1:$}                                                  |
      zxcv{10:bnm}{1:$}                                                    |
                                                                  |
    ]])
  end)

  it('can use -1 or v:maxcol to indicate end of line', function()
    exec_lua(function()
      local ns = vim.api.nvim_create_namespace('')
      vim.hl.range(0, ns, 'Search', { 0, 4 }, { 1, -1 }, {})
      vim.hl.range(0, ns, 'Search', { 2, 6 }, { 3, vim.v.maxcol }, {})
    end)
    screen:expect([[
      ^asdf{10:ghjkl}{100:$}                                                  |
      {10:«口=口»}{100:$}                                                    |
      qwerty{10:uiop}{100:$}                                                 |
      {10:口口=口口}{1:$}                                                  |
      zxcvbnm{1:$}                                                    |
                                                                  |
    ]])
  end)

  it('removes highlight after given `timeout`', function()
    local timeout = 300
    exec_lua(function()
      local ns = vim.api.nvim_create_namespace('')
      vim.hl.range(0, ns, 'Search', { 0, 0 }, { 4, 0 }, { timeout = timeout })
    end)
    screen:expect({
      grid = [[
      {10:^asdfghjkl}{100:$}                                                  |
      {10:«口=口»}{100:$}                                                    |
      {10:qwertyuiop}{100:$}                                                 |
      {10:口口=口口}{1:$}                                                  |
      zxcvbnm{1:$}                                                    |
                                                                  |
    ]],
      timeout = timeout / 3,
    })
    screen:expect([[
      ^asdfghjkl{1:$}                                                  |
      «口=口»{1:$}                                                    |
      qwertyuiop{1:$}                                                 |
      口口=口口{1:$}                                                  |
      zxcvbnm{1:$}                                                    |
                                                                  |
    ]])
  end)

  it('shows multiple highlights with different timeouts simultaneously', function()
    local timeout1 = 300
    local timeout2 = 600
    exec_lua(function()
      local ns = vim.api.nvim_create_namespace('')
      vim.hl.range(0, ns, 'Search', { 0, 0 }, { 4, 0 }, { timeout = timeout1 })
      vim.hl.range(0, ns, 'Search', { 2, 6 }, { 3, 5 }, { timeout = timeout2 })
    end)
    screen:expect({
      grid = [[
        {10:^asdfghjkl}{100:$}                                                  |
        {10:«口=口»}{100:$}                                                    |
        {10:qwertyuiop}{100:$}                                                 |
        {10:口口=口口}{1:$}                                                  |
        zxcvbnm{1:$}                                                    |
                                                                    |
      ]],
      timeout = timeout1 / 3,
    })
    screen:expect({
      grid = [[
        ^asdfghjkl{1:$}                                                  |
        «口=口»{1:$}                                                    |
        qwerty{10:uiop}{100:$}                                                 |
        {10:口口}=口口{1:$}                                                  |
        zxcvbnm{1:$}                                                    |
                                                                    |
      ]],
      timeout = timeout1 + ((timeout2 - timeout1) / 3),
    })
    screen:expect([[
      ^asdfghjkl{1:$}                                                  |
      «口=口»{1:$}                                                    |
      qwertyuiop{1:$}                                                 |
      口口=口口{1:$}                                                  |
      zxcvbnm{1:$}                                                    |
                                                                  |
    ]])
  end)

  it('allows cancelling a highlight that has not timed out', function()
    exec_lua(function()
      local timeout = 3000
      local range_timer
      local range_hl_clear
      local ns = vim.api.nvim_create_namespace('')
      range_timer, range_hl_clear = vim.hl.range(
        0,
        ns,
        'Search',
        { 0, 0 },
        { 4, 0 },
        { timeout = timeout }
      )
      if range_timer and not range_timer:is_closing() then
        range_timer:close()
        assert(range_hl_clear)
        range_hl_clear()
        range_hl_clear() -- Exercise redundant call
      end
    end)
    screen:expect({
      grid = [[
        ^asdfghjkl{1:$}                                                  |
        «口=口»{1:$}                                                    |
        qwertyuiop{1:$}                                                 |
        口口=口口{1:$}                                                  |
        zxcvbnm{1:$}                                                    |
                                                                    |
      ]],
      unchanged = true,
    })
  end)
end)

describe('vim.hl.on_yank', function()
  before_each(function()
    clear()
  end)

  it('does not show errors even if buffer is wiped before timeout', function()
    command('new')
    n.feed('ifoo<esc>') -- set '[, ']
    exec_lua(function()
      vim.hl.on_yank({
        timeout = 10,
        on_macro = true,
        event = { operator = 'y', regtype = 'v' },
      })
      vim.cmd('bwipeout!')
    end)
    vim.uv.sleep(10)
    n.feed('<cr>') -- avoid hang if error message exists
    eq('', eval('v:errmsg'))
  end)

  it('does not close timer twice', function()
    exec_lua(function()
      vim.hl.on_yank({ timeout = 10, on_macro = true, event = { operator = 'y' } })
      vim.uv.sleep(10)
      vim.schedule(function()
        vim.hl.on_yank({ timeout = 0, on_macro = true, event = { operator = 'y' } })
      end)
    end)
    eq('', eval('v:errmsg'))
  end)

  it('does not show in another window', function()
    command('vsplit')
    exec_lua(function()
      vim.api.nvim_buf_set_mark(0, '[', 1, 1, {})
      vim.api.nvim_buf_set_mark(0, ']', 1, 1, {})
      vim.hl.on_yank({ timeout = math.huge, on_macro = true, event = { operator = 'y' } })
    end)
    local ns = api.nvim_create_namespace('nvim.hlyank')
    local win = api.nvim_get_current_win()
    eq({ win }, api.nvim__ns_get(ns).wins)
    command('wincmd w')
    eq({ win }, api.nvim__ns_get(ns).wins)
    -- Use a new vim.hl.on_yank() call to cancel the previous timer
    exec_lua(function()
      vim.hl.on_yank({ timeout = 0, on_macro = true, event = { operator = 'y' } })
    end)
  end)

  it('removes old highlight if new one is created before old one times out', function()
    command('vnew')
    exec_lua(function()
      vim.api.nvim_buf_set_mark(0, '[', 1, 1, {})
      vim.api.nvim_buf_set_mark(0, ']', 1, 1, {})
      vim.hl.on_yank({ timeout = math.huge, on_macro = true, event = { operator = 'y' } })
    end)
    local ns = api.nvim_create_namespace('nvim.hlyank')
    eq(api.nvim_get_current_win(), api.nvim__ns_get(ns).wins[1])
    command('wincmd w')
    exec_lua(function()
      vim.api.nvim_buf_set_mark(0, '[', 1, 1, {})
      vim.api.nvim_buf_set_mark(0, ']', 1, 1, {})
      vim.hl.on_yank({ timeout = math.huge, on_macro = true, event = { operator = 'y' } })
    end)
    local win = api.nvim_get_current_win()
    eq({ win }, api.nvim__ns_get(ns).wins)
    command('wincmd w')
    eq({ win }, api.nvim__ns_get(ns).wins)
    -- Use a new vim.hl.on_yank() call to cancel the previous timer
    exec_lua(function()
      vim.hl.on_yank({ timeout = 0, on_macro = true, event = { operator = 'y' } })
    end)
  end)

  it('highlights last character with exclusive motion', function()
    local screen = Screen.new(60, 4)
    screen:add_extra_attr_ids({
      [100] = { foreground = Screen.colors.Blue, background = Screen.colors.Yellow, bold = true },
    })
    command('autocmd TextYankPost * lua vim.hl.on_yank{timeout=100000}')
    api.nvim_buf_set_lines(0, 0, -1, true, {
      [[foo(bar) 'baz']],
      [[foo(bar) 'baz']],
    })
    n.feed('yw')
    screen:expect([[
      {2:^foo}(bar) 'baz'                                              |
      foo(bar) 'baz'                                              |
      {1:~                                                           }|
                                                                  |
    ]])
    n.feed("yi'")
    screen:expect([[
      foo(bar) '{2:^baz}'                                              |
      foo(bar) 'baz'                                              |
      {1:~                                                           }|
                                                                  |
    ]])
    n.feed('yvj')
    screen:expect([[
      foo(bar) '{2:^baz'}                                              |
      {2:foo(bar) '}baz'                                              |
      {1:~                                                           }|
                                                                  |
    ]])
    -- Use a new vim.hl.on_yank() call to cancel the previous timer
    exec_lua(function()
      vim.hl.on_yank({ timeout = 0, on_macro = true, event = { operator = 'y' } })
    end)
  end)
end)
