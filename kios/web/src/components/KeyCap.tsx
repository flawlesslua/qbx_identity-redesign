export function KeyCap({ k }: { k: string }) {
  return <span className={`keycap ${k.length > 1 ? 'keycap--wide' : ''}`}>{k}</span>;
}
