import { useMemo, useState } from 'react';
import { MOCK_CHANNELS } from '../constants/mockChannels';

export function useChannelMention() {
  const [mention, setMention] = useState('');

  const data = useMemo(
    () => MOCK_CHANNELS.filter((i) => i.name.toLowerCase().startsWith(mention)),
    [mention]
  );

  const onMentionChange = (value: string) => {
    setMention(value.toLowerCase());
  };

  return { data, onMentionChange };
}
