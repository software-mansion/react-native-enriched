import {
  memo,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
} from 'react';
import type { EnrichedTextProps } from '../types';
import './EnrichedText.css';
import { enrichedTextStyleToCSSProperties } from './styleConversion/enrichedTextStyleToCSSProperties';
import { mergeWithDefaultEnrichedTextHtmlStyle } from './styleConversion/htmlStyleToCSSVariables';
import { enrichedTextHtmlStyleToCSSVariables } from './styleConversion/htmlStyleToCSSVariables';
import {
  ENRICHED_TEXT_CLASSNAME,
  LINK_PRESSABLE_CLASSNAME,
} from './constants/classNames';
import { enrichedTextThemingToCSSProperties } from './styleConversion/enrichedThemingToCSSProperties';
import { buildMentionRulesCSS } from './styleConversion/buildMentionRulesCSS';
import { sanitizeHtml } from './sanitization/htmlSanitizer';
import { prepareHtmlForWeb } from './normalization/prepareHtmlForWeb';
import { INLINE_IMAGE_CSS_VARIABLES } from './styleConversion/inlineImageCSSVariables';
import { useImageErrorFallback } from './htmlExtensions/useImageErrorFallback';
import { usePressInteractions } from './htmlExtensions/usePressInteractions';
import { useEllipsizeMode } from './ellipsizeMode/useEllipsizeMode';
import { adaptWebToNativeEvent } from './nativeMappers/adaptWebToNativeEvent';
import { useStableRef } from './utils/useStableRef';
import { assertBrowserEnvironment } from './utils/assertBrowserEnvironment';
import { useOrderedListMarkerWidth } from './htmlExtensions/useOrderedListMarkerWidth';

export const EnrichedText = memo(
  ({
    ref,
    children,
    htmlStyle,
    style,
    selectionColor,
    ellipsizeMode = 'tail',
    numberOfLines = 0,
    selectable = false,
    useHtmlNormalizer = true,
    sanitizationConfig,
    onFocus,
    onBlur,
    onLinkPress,
    onMentionPress,
  }: EnrichedTextProps) => {
    assertBrowserEnvironment('EnrichedText');

    const containerRef = useRef<HTMLDivElement>(null);

    useImperativeHandle(ref, () => ({
      measureInWindow: () => {},
      measure: () => {},
      measureLayout: () => {},
      setNativeProps: () => {},
      focus: () => {
        containerRef.current?.focus();
      },
      blur: () => {
        containerRef.current?.blur();
      },
    }));

    const sanitizedHtml = useMemo(
      () => sanitizeHtml(children, sanitizationConfig),
      [children, sanitizationConfig]
    );

    const finalHtml = useMemo(
      () => prepareHtmlForWeb(sanitizedHtml, useHtmlNormalizer),
      [sanitizedHtml, useHtmlNormalizer]
    );

    const [clampedHtml, setClampedHtml] = useState<string | null>(
      numberOfLines <= 0 ? finalHtml : null
    );

    const resolvedHtmlStyle = useMemo(
      () => mergeWithDefaultEnrichedTextHtmlStyle(htmlStyle),
      [htmlStyle]
    );

    const textStyle: CSSProperties = useMemo(
      () => enrichedTextStyleToCSSProperties(style ?? {}),
      [style]
    );

    const cssVars = useMemo(
      () => ({
        ...enrichedTextHtmlStyleToCSSVariables(resolvedHtmlStyle),
        ...INLINE_IMAGE_CSS_VARIABLES,
      }),
      [resolvedHtmlStyle]
    );

    const themingStyle = useMemo(
      () => enrichedTextThemingToCSSProperties({ selectionColor, selectable }),
      [selectionColor, selectable]
    );

    const mentionRulesCSS = useMemo(
      () => buildMentionRulesCSS(resolvedHtmlStyle, !!onMentionPress),
      [resolvedHtmlStyle, onMentionPress]
    );

    const finalStyle = useMemo(
      () =>
        ({
          ...textStyle,
          ...themingStyle,
          ...cssVars,
        }) as CSSProperties,
      [textStyle, themingStyle, cssVars]
    );

    useEllipsizeMode({
      containerRef,
      finalHtml,
      ellipsizeMode,
      numberOfLines,
      setClampedHtml,
      style,
      htmlStyle,
    });

    const onLinkPressRef = useStableRef(onLinkPress);
    const onMentionPressRef = useStableRef(onMentionPress);

    useOrderedListMarkerWidth(containerRef, finalHtml);

    useImageErrorFallback(containerRef);
    usePressInteractions(containerRef, onLinkPressRef, onMentionPressRef);

    return (
      <>
        {mentionRulesCSS ? <style>{mentionRulesCSS}</style> : null}
        <div
          ref={containerRef}
          tabIndex={-1}
          style={finalStyle}
          className={
            onLinkPress
              ? `${ENRICHED_TEXT_CLASSNAME} ${LINK_PRESSABLE_CLASSNAME}`
              : ENRICHED_TEXT_CLASSNAME
          }
          onFocus={(event) =>
            onFocus?.(adaptWebToNativeEvent(event, { target: -1 }))
          }
          onBlur={(event) =>
            onBlur?.(adaptWebToNativeEvent(event, { target: -1 }))
          }
          dangerouslySetInnerHTML={{ __html: clampedHtml ?? '' }}
        />
      </>
    );
  }
);
