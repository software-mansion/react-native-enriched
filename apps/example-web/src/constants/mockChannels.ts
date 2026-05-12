export interface MockChannel {
  id: string;
  name: string;
}

export const MOCK_CHANNELS: MockChannel[] = [
  { id: 'c1', name: 'general' },
  { id: 'c2', name: 'engineering' },
  { id: 'c3', name: 'random' },
  { id: 'c4', name: 'announcements' },
];
