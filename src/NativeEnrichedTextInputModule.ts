import { TurboModuleRegistry } from 'react-native';
import type { TurboModule } from 'react-native';
import type { Int32 } from 'react-native/Libraries/Types/CodegenTypes';

interface Spec extends TurboModule {
  getHTMLValue(inputTag: Int32): string;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'EnrichedTextInputModule'
);
