import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import Logo from "./Logo"
import Clock from "./Clock"
import Workspaces from "./Workspaces"
import MusicStrip from "./MusicStrip"
import SysStats from "./SysStats"

const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

export default function Bar(gdkmonitor: Gdk.Monitor) {
  return (
    <window
      visible
      namespace="bar"
      name="bar"
      cssClasses={["grid", "Bar"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <box cssClasses={["bar-outer"]}>
        <overlay cssClasses={["bar-inner"]}>
          <box hexpand>
            <box
              cssClasses={["bar-section"]}
              halign={Gtk.Align.START}
              hexpand
              spacing={12}
            >
              <Logo />
              <box cssClasses={["sep-v"]} />
              <MusicStrip />
            </box>
            <box
              cssClasses={["bar-section"]}
              halign={Gtk.Align.END}
              hexpand
              spacing={10}
            >
              <SysStats />
            </box>
          </box>
          <box
            $type="overlay"
            cssClasses={["bar-section", "bar-center"]}
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
            spacing={12}
          >
            <Workspaces />
            <box cssClasses={["sep-v"]} />
            <Clock />
          </box>
        </overlay>
      </box>
    </window>
  )
}
