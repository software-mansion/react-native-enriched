import { Mark, mergeAttributes } from '@tiptap/core';

export const EXCLUDED_MARKS = ['link', 'code', 'mention'];

export const EnrichedMention = Mark.create({
  name: 'mention',
  inclusive: false,
  excludes: EXCLUDED_MARKS.join(' '),
  priority: 1000,

  addAttributes() {
    return {
      indicator: {
        default: '@',
      },
      text: {
        default: '',
      },
      attributes: {
        default: {},
        parseHTML(el: HTMLElement): Record<string, string> {
          const out: Record<string, string> = {};
          for (let i = 0; i < el.attributes.length; i++) {
            const attr = el.attributes.item(i);
            if (!attr) continue;
            if (attr.name === 'text' || attr.name === 'indicator') continue;
            out[attr.name] = attr.value;
          }
          return out;
        },
        renderHTML(attrs: Record<string, unknown>): Record<string, string> {
          return (attrs.attributes ?? {}) as Record<string, string>;
        },
      },
    };
  },

  parseHTML() {
    return [{ tag: 'mention' }];
  },

  renderHTML({ mark }) {
    return [
      'mention',
      mergeAttributes(
        {
          text: mark.attrs.text as string,
          indicator: mark.attrs.indicator as string,
        },
        (mark.attrs.attributes ?? {}) as Record<string, string>
      ),
      0,
    ];
  },
});
