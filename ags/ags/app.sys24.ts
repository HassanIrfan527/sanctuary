import app from "ags/gtk4/app"
import style from "./styles/sys24/sys24.scss"
import Bar from "./widgets/bar/sys24/Bar"
import Sys24Notifications from "./widgets/popups/Sys24Notifications/Sys24Notifications"
import Sys24NotifCenter from "./widgets/popups/Sys24NotifCenter/Sys24NotifCenter"
import Sys24Session from "./widgets/popups/Sys24Session/Sys24Session"
import AstalNotifd from "gi://AstalNotifd?version=0.1"

app.start({
  instanceName: "sys24",
  css: style,
  requestHandler(req, res) {
    if (req === "toggle session") {
      const w = app.get_window("sys24-session")
      if (w) w.visible = !w.visible
      res("ok")
      return
    }
    if (req === "toggle notifications") {
      const w = app.get_window("sys24-notif-center")
      if (w) w.visible = !w.visible
      res("ok")
      return
    }
    res("unknown")
  },
  main() {
    const notifd = AstalNotifd.get_default()
    if (notifd.dontDisturb) {
      print("[sys24] DND was enabled; turning off")
      notifd.dontDisturb = false
    }
    app.get_monitors().forEach((m) => {
      Bar(m)
      Sys24Notifications(m)
    })
    Sys24Session()
    Sys24NotifCenter()
  },
})
