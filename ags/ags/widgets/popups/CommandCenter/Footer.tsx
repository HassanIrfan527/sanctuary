import KeyPill from "../../ui/KeyPill"

export default function Footer() {
  return (
    <box cssClasses={["cc-footer"]} spacing={8}>
      <KeyPill text="↑↓" />
      <label cssClasses={["cc-footer-hint"]} label="navigate" />
      <KeyPill text="⏎" />
      <label cssClasses={["cc-footer-hint"]} label="select" />
      <KeyPill text="esc" />
      <label cssClasses={["cc-footer-hint"]} label="close" />
    </box>
  )
}
