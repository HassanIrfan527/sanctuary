Name = "notifications"
NamePretty = "Notifications"
Icon = "preferences-system-notifications"
Description = "notification history"
HideFromProviderlist = false
FixedOrder = true
-- Enter on a row dismisses it (Value = that row's id). The "clear all" row
-- carries the sentinel id "__ALL__", which the helper treats as wipe-all.
Action = "/home/anonymous/.config/swaync/scripts/notif-history.sh remove %VALUE%"

function GetEntries()
    local entries = {}

    local cmd = [[
tac '/home/anonymous/.local/state/swaync/history.jsonl' 2>/dev/null | jq -r '
  (now - .ts) as $d |
  (if   $d < 60    then "now"
   elif $d < 3600  then "\(($d/60)|floor)m"
   elif $d < 86400 then "\(($d/3600)|floor)h"
   else                 "\(($d/86400)|floor)d" end) as $rel |
  [(.id // ""), (.app // ""), (.summary // ""), (.body // ""), $rel] | @tsv
' 2>/dev/null
]]

    local count = 0
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            local id, app, summary, body, rel =
                line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$")
            if id then
                count = count + 1

                local title = app
                if summary ~= "" then title = app .. "  ·  " .. summary end

                local sub = rel
                if body ~= "" then sub = rel .. "   " .. body end

                table.insert(entries, {
                    Text = title,
                    Subtext = sub,
                    Value = id,
                })
            end
        end
        handle:close()
    end

    if count == 0 then
        table.insert(entries, {
            Text = "all caught up",
            Subtext = "no notifications  󰂠",
            Value = "",
        })
    else
        table.insert(entries, {
            Text = "clear all",
            Subtext = "dismiss every notification",
            Value = "__ALL__",
        })
    end

    return entries
end
