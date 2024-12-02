-- Keybindings for AwesomeWM

globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "h", function () awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey,           }, "l", function () awful.tag.incmwfact( 0.05) end),
    awful.key({ modkey,           }, "j", function () awful.client.focus.byidx( 1) end),
    awful.key({ modkey,           }, "k", function () awful.client.focus.byidx(-1) end)
)

root.keys(globalkeys)
