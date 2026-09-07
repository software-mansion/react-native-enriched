import React from 'react';
import { No, Version, Yes } from './index';

const REACT_NATIVE_VERSIONS = [
  '0.80',
  '0.81',
  '0.82',
  '0.83',
  '0.84',
  '0.85',
  '0.86',
  '0.87',
];

const LIBRARY_VERSIONS = [
  { version: 'nightly', supportedFrom: '0.82', supportedTo: '0.87' },
  { version: '1.2.x (next)', supportedFrom: '0.82', supportedTo: '0.87' },
  { version: '1.1.x', supportedFrom: '0.81', supportedTo: '0.86' },
  { version: '1.0.x', supportedFrom: '0.81', supportedTo: '0.85' },
] as const;

function isSupported(
  reactNativeVersion: string,
  supportedFrom: string,
  supportedTo: string,
) {
  return (
    reactNativeVersion.localeCompare(supportedFrom, undefined, {
      numeric: true,
    }) >= 0 &&
    reactNativeVersion.localeCompare(supportedTo, undefined, {
      numeric: true,
    }) <= 0
  );
}

export default function EnrichedCompatibility() {
  return (
    <div className="compatibility">
      <table>
        <thead>
          <tr>
            <th scope="col"></th>
            {REACT_NATIVE_VERSIONS.map(version => (
              <th key={version} scope="col">
                {version}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {LIBRARY_VERSIONS.map(({ version, supportedFrom, supportedTo }) => (
            <tr key={version}>
              <td>
                <Version version={version} />
              </td>
              {REACT_NATIVE_VERSIONS.map(reactNativeVersion => (
                <td key={reactNativeVersion}>
                  {isSupported(
                    reactNativeVersion,
                    supportedFrom,
                    supportedTo,
                  ) ? (
                    <Yes />
                  ) : (
                    <No />
                  )}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
