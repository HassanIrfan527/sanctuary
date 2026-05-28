export default function KeyPill({ text, bright }: { text: string; bright?: boolean }) {
  const classes = ["keypill"]
  if (bright) classes.push("bright")
  return <label label={text} cssClasses={classes} />
}
