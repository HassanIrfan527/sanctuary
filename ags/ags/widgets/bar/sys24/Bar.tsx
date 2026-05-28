import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland"
import Clock from "./Clock"
import Workspaces from "./Workspaces"
import SysStats from "./SysStats"
import ActiveWindow from "./ActiveWindow"
import Media from "./Media"

const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

function Pipe() {
  return <label cssClasses={["bar-pipe"]} label="│" />
}

function attachScroll(box: any) {
  const ctl = new Gtk.EventControllerScroll({
    flags: Gtk.EventControllerScrollFlags.VERTICAL,
  })
  ctl.connect("scroll", (_, _dx: number, dy: number) => {
    const hypr = AstalHyprland.get_default()
    hypr.dispatch("workspace", dy > 0 ? "e+1" : "e-1")
    return true
  })
  box.add_controller(ctl)
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
  return (
    <window
      visible
      namespace="bar"
      name="bar"
      cssClasses={["sys24-root", "Bar"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <box cssClasses={["bar-root"]} hexpand $={attachScroll}>
        <box cssClasses={["bar-side"]} halign={Gtk.Align.START} spacing={10} hexpand>
          <Workspaces />
          <Pipe />
          <ActiveWindow />
        </box>
        <box cssClasses={["bar-center"]} halign={Gtk.Align.CENTER}>
          <Clock />
        </box>
        <box cssClasses={["bar-side"]} halign={Gtk.Align.END} spacing={10} hexpand>
          <Media />
          <Pipe />
          <SysStats />
        </box>
      </box>
    </window>
  )
}
