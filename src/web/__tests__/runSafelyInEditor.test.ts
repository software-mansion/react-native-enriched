import type { Editor } from '@tiptap/react';
import { runSafelyInEditor } from '../utils/runSafelyInEditor';

function makeEditor(isDestroyed: boolean): Editor {
  return { isDestroyed } as Editor;
}

describe('runSafelyInEditor', () => {
  test('runs the callback and returns its result when editor is alive', () => {
    const editor = makeEditor(false);
    const callback = jest.fn((e: Editor) => e);

    const result = runSafelyInEditor(editor, callback);

    expect(callback).toHaveBeenCalledWith(editor);
    expect(result).toBe(editor);
  });

  test('does not run the callback and returns null when editor is destroyed', () => {
    const editor = makeEditor(true);
    const callback = jest.fn();

    const result = runSafelyInEditor(editor, callback);

    expect(callback).not.toHaveBeenCalled();
    expect(result).toBeNull();
  });

  test('does not run the callback and returns null when editor is null', () => {
    const callback = jest.fn();

    const result = runSafelyInEditor(null, callback);

    expect(callback).not.toHaveBeenCalled();
    expect(result).toBeNull();
  });
});
