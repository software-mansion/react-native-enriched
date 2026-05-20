import { Fragment } from '@tiptap/pm/model';
import type { Node } from '@tiptap/pm/model';

export function stripPartialMentionMarks(fragment: Fragment): Fragment {
  const nodes: Node[] = [];
  fragment.forEach((node) =>
    nodes.push(
      node.isText
        ? node.mark(
            node.marks.filter(
              (m) =>
                m.type.name !== 'mention' ||
                node.text === (m.attrs.text as string)
            )
          )
        : node.copy(stripPartialMentionMarks(node.content))
    )
  );
  return Fragment.from(nodes);
}
