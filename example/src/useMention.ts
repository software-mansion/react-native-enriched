import { useMemo, useState } from 'react';

const MOCKED_DATA = [
  {
    id: '1',
    name: 'John Doe',
  },
  {
    id: '2',
    name: 'Jane Smith',
  },
  {
    id: '3',
    name: 'Alice Johnson',
  },
  {
    id: '4',
    name: 'Bob Brown',
  },
];

export type MentionItem = (typeof MOCKED_DATA)[number];
export type MentionData = MentionItem[];

export const useMention = () => {
  const [mention, setMention] = useState('');

  const mentionData = useMemo(
    () => MOCKED_DATA.filter((i) => i.name.toLowerCase().startsWith(mention)),
    [mention]
  );

  const onMentionChange = (value: string) => {
    setMention(value.toLowerCase());
  };

  return { mentionData, onMentionChange };
};
