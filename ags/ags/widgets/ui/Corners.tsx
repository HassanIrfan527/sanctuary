import { Gtk } from "ags/gtk4"

// L-shaped bracket corners. Wraps children in a Gtk.Overlay with 4 corner
// boxes pinned to each edge. Use for Command Center frame + any HUD panel.
export default function Corners({ children }: { children: any }) {
  return (
    <overlay>
      {children}
      <box
        $type="overlay"
        cssClasses={["corner", "tl"]}
        halign={Gtk.Align.START}
        valign={Gtk.Align.START}
      />
      <box
        $type="overlay"
        cssClasses={["corner", "tr"]}
        halign={Gtk.Align.END}
        valign={Gtk.Align.START}
      />
      <box
        $type="overlay"
        cssClasses={["corner", "bl"]}
        halign={Gtk.Align.START}
        valign={Gtk.Align.END}
      />
      <box
        $type="overlay"
        cssClasses={["corner", "br"]}
        halign={Gtk.Align.END}
        valign={Gtk.Align.END}
      />
    </overlay>
  )
}
