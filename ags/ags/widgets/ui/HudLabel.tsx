type Props = {
  text: string
  bright?: boolean
  brackets?: boolean
  extraClass?: string
}

// Uppercase monospace label, tracked, optionally wrapped in [ ].
export default function HudLabel({ text, bright, brackets, extraClass }: Props) {
  const label = brackets ? `[ ${text} ]` : text
  const classes = ["hud-label"]
  if (bright) classes.push("bright")
  if (extraClass) classes.push(extraClass)
  return <label label={label} cssClasses={classes} />
}
