import { useMemo, useState } from 'react';
import { MOCK_USER_MENTIONS } from '../constants/mockUserMentions';

export function useUserMentionWeb() {
  const [mention, setMention] = useState('');

  const data = useMemo(
    () =>
      MOCK_USER_MENTIONS.filter((i) =>
        i.name.toLowerCase().startsWith(mention)
      ),
    [mention]
  );

  const onMentionChange = (value: string) => {
    setMention(value.toLowerCase());
  };

  return { data, onMentionChange };
}
