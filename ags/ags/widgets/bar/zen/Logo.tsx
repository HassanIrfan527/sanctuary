const LOGO_PATH = "/home/anonymous/.dotfiles/ags/ags/assets/night.svg"

export default function Logo() {
  return (
    <button cssClasses={["logo"]}>
      <image file={LOGO_PATH} pixelSize={18} />
    </button>
  )
}
