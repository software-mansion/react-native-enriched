import { Fragment } from '@tiptap/pm/model';
import type { Node } from '@tiptap/pm/model';

/**
 * Strip link marks with `auto: true` from a pasted slice. ProseMirror's clipboard
 * round-trip preserves the `auto` attribute when pasting from one of our editors
 * back into another (the original slice is embedded alongside the HTML), so any
 * link marked `auto: true` was an autolink at copy time. Stripping it lets the
 * autolink plugin re-detect the URL on the new doc, keeping the per-doc state
 * consistent (e.g. positions, dedup against onLinkDetected).
 *
 * Manual links (`auto: false`, no `auto` attribute) are left untouched, as are
 * external pastes whose `<a>` tags arrive without `data-auto`.
 */
export function stripAutolinkMarksOnPaste(fragment: Fragment): Fragment {
  const nodes: Node[] = [];
  fragment.forEach((node) => {
    if (node.isText) {
      const filtered = node.marks.filter(
        (m) => !(m.type.name === 'link' && m.attrs.auto === true)
      );
      nodes.push(node.mark(filtered));
      return;
    }
    nodes.push(node.copy(stripAutolinkMarksOnPaste(node.content)));
  });
  return Fragment.from(nodes);
}
