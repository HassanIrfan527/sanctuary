import app from "ags/gtk4/app"
import style from "./styles/grid/grid.scss"
import Bar from "./widgets/bar/grid/Bar"
import CommandCenter from "./widgets/popups/CommandCenter/CommandCenter"
import NotificationPopups from "./widgets/popups/NotificationPopups"
import AstalNotifd from "gi://AstalNotifd?version=0.1"

app.start({
  css: style,
  main() {
    AstalNotifd.get_default()
    app.get_monitors().forEach((m) => {
      Bar(m)
      NotificationPopups(m)
    })
    // Global overlay — parent-less, appears centered on focused monitor.
    CommandCenter()
  },
})
