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

export const useUserMention = () => {
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
