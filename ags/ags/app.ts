import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widgets/bar/zen/Bar"
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
  },
})
