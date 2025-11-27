import { useMemo, useState } from 'react';

const MOCKED_DATA = [
  {
    id: '1',
    name: 'General',
  },
  {
    id: '2',
    name: 'Random',
  },
  {
    id: '3',
    name: 'Engineering',
  },
  {
    id: '4',
    name: 'Private channel',
  },
];

export const useChannelMention = () => {
  const [mention, setMention] = useState('');

  const data = useMemo(
    () => MOCKED_DATA.filter((i) => i.name.toLowerCase().startsWith(mention)),
    [mention]
  );

  const onMentionChange = (value: string) => {
    setMention(value.toLowerCase());
  };

  return { data, onMentionChange };
};
