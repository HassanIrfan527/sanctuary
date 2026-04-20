import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import Logo from "./Logo"
import Clock from "./Clock"
import Workspaces from "./Workspaces"
import Notifications from "./Notifications"
import MusicPlayer from "../../MusicPlayer"

const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

export default function Bar(gdkmonitor: Gdk.Monitor) {
  return (
    <window
      visible
      namespace="bar"
      name="bar"
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox cssClasses={["bar-inner"]}>
        <box $type="start" spacing={10}>
          <Logo />
          <MusicPlayer />
        </box>
        <box $type="center" cssClasses={["bar-pill"]} spacing={12}>
          <Clock />
          <box cssClasses={["sep"]} />
          <Workspaces />
        </box>
        <box $type="end" halign={Gtk.Align.END}>
          <Notifications />
        </box>
      </centerbox>
    </window>
  )
}
