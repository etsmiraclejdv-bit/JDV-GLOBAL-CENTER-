/**
 * JDV CRM — Design System Tokens
 * Single source of truth for all colors and gradients.
 * Consume these constants in all new components — never hardcode hex values.
 */

export const COLORS = {
  // Backgrounds
  navy: '#0B1B3D',
  navyDeep: '#08152f',
  navyMid: '#0F2347',
  navyLight: '#132a56',
  navyCard: '#0A1628',

  // Accent
  gold: '#D4AF37',
  goldLight: '#F5E17A',
  goldDark: '#A8860C',

  // Text
  foreground: '#F7F9FC',
  muted: '#A0AEC0',
  mutedDark: '#718096',

  // Semantic states
  success: '#68D391',
  danger: '#FC8181',
  warning: '#F6E05E',
  info: '#63B3ED',

  // Borders
  borderGold: 'rgba(212,175,55,0.2)',
  borderGoldStrong: 'rgba(212,175,55,0.4)',
  borderGoldSubtle: 'rgba(212,175,55,0.1)',
} as const;

export const GRADIENTS = {
  gold: 'linear-gradient(135deg, #D4AF37 0%, #F5E17A 40%, #D4AF37 60%, #A8860C 100%)',
  goldText: 'linear-gradient(135deg, #D4AF37 0%, #F5E17A 50%, #A8860C 100%)',
  navyCard: 'linear-gradient(145deg, #132a56 0%, #0F2347 100%)',
} as const;

export const BADGE_COLORS: Record<string, { bg: string; text: string; border: string }> = {
  hot:     { bg: 'rgba(252,129,129,0.15)', text: '#FC8181', border: 'rgba(252,129,129,0.3)' },
  warm:    { bg: 'rgba(246,224,94,0.15)',  text: '#F6E05E', border: 'rgba(246,224,94,0.3)' },
  cold:    { bg: 'rgba(99,179,237,0.15)',  text: '#63B3ED', border: 'rgba(99,179,237,0.3)' },
  success: { bg: 'rgba(104,211,145,0.15)', text: '#68D391', border: 'rgba(104,211,145,0.3)' },
  danger:  { bg: 'rgba(252,129,129,0.15)', text: '#FC8181', border: 'rgba(252,129,129,0.3)' },
  warning: { bg: 'rgba(246,224,94,0.15)',  text: '#F6E05E', border: 'rgba(246,224,94,0.3)' },
  info:    { bg: 'rgba(99,179,237,0.15)',  text: '#63B3ED', border: 'rgba(99,179,237,0.3)' },
  gold:    { bg: 'rgba(212,175,55,0.2)',   text: '#D4AF37', border: 'rgba(212,175,55,0.4)' },
  neutral: { bg: 'rgba(160,174,192,0.1)',  text: '#A0AEC0', border: 'rgba(160,174,192,0.2)' },
  pending: { bg: 'rgba(160,174,192,0.1)',  text: '#A0AEC0', border: 'rgba(160,174,192,0.2)' },
  active:  { bg: 'rgba(104,211,145,0.15)', text: '#68D391', border: 'rgba(104,211,145,0.3)' },
  paid:    { bg: 'rgba(104,211,145,0.15)', text: '#68D391', border: 'rgba(104,211,145,0.3)' },
  late:    { bg: 'rgba(252,129,129,0.15)', text: '#FC8181', border: 'rgba(252,129,129,0.3)' },
  partial: { bg: 'rgba(246,224,94,0.15)',  text: '#F6E05E', border: 'rgba(246,224,94,0.3)' },
  draft:   { bg: 'rgba(160,174,192,0.1)',  text: '#A0AEC0', border: 'rgba(160,174,192,0.2)' },
  sent:    { bg: 'rgba(99,179,237,0.15)',  text: '#63B3ED', border: 'rgba(99,179,237,0.3)' },
  confirmed: { bg: 'rgba(212,175,55,0.2)', text: '#D4AF37', border: 'rgba(212,175,55,0.4)' },
  received:  { bg: 'rgba(104,211,145,0.15)', text: '#68D391', border: 'rgba(104,211,145,0.3)' },
  cancelled: { bg: 'rgba(252,129,129,0.15)', text: '#FC8181', border: 'rgba(252,129,129,0.3)' },
  in_transit: { bg: 'rgba(99,179,237,0.15)', text: '#63B3ED', border: 'rgba(99,179,237,0.3)' },
  completed:  { bg: 'rgba(104,211,145,0.15)', text: '#68D391', border: 'rgba(104,211,145,0.3)' },
  suspended:  { bg: 'rgba(246,224,94,0.15)', text: '#F6E05E', border: 'rgba(246,224,94,0.3)' },
  blocked:    { bg: 'rgba(252,129,129,0.15)', text: '#FC8181', border: 'rgba(252,129,129,0.3)' },
  inactive:   { bg: 'rgba(160,174,192,0.1)',  text: '#A0AEC0', border: 'rgba(160,174,192,0.2)' },
  trial:      { bg: 'rgba(99,179,237,0.15)',  text: '#63B3ED', border: 'rgba(99,179,237,0.3)' },
  converted:  { bg: 'rgba(104,211,145,0.15)', text: '#68D391', border: 'rgba(104,211,145,0.3)' },
  lost:       { bg: 'rgba(252,129,129,0.15)', text: '#FC8181', border: 'rgba(252,129,129,0.3)' },
  cash:       { bg: 'rgba(104,211,145,0.15)', text: '#68D391', border: 'rgba(104,211,145,0.3)' },
  credit:     { bg: 'rgba(99,179,237,0.15)',  text: '#63B3ED', border: 'rgba(99,179,237,0.3)' },
} as const;
