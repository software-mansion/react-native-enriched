import { useMemo, useState } from 'react';
import { MOCK_USERS } from '../constants/mockUsers';

export function useUserMention() {
  const [mention, setMention] = useState('');

  const data = useMemo(
    () => MOCK_USERS.filter((i) => i.name.toLowerCase().startsWith(mention)),
    [mention]
  );

  const onMentionChange = (value: string) => {
    setMention(value.toLowerCase());
  };

  return { data, onMentionChange };
}
