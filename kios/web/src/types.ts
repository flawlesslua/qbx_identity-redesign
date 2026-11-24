export type Point = { x: number; y: number };

export type Action = {
  id: string;
  key: string;
  label: string;
  subtle?: boolean;
};

export type TargetData = {
  label: string;
  qty?: number;
  price?: string;
  icon?: 'register' | 'card';
  muted?: boolean;
  actions?: Action[];
};

export type ReceiptLine = {
  label: string;
  qty: number;
  priceText: string;
};

export type ReceiptData = {
  stage: 'scanning' | 'pay' | 'paid';
  items: ReceiptLine[];
  count: number;
  scanned: number;
  total: string;
};

export type HintData = {
  title: string;
  subtitle?: string;
  counter?: number;
  keys: { key: string; label: string }[];
};

export type Strings = Record<string, string>;

export const defaultStrings: Strings = {
  currency: '$',
  ui_to_pay: 'TO PAY',
  ui_scanning: 'SCANNING',
  ui_scanning_desc: 'Scanning the purchase…',
  ui_paid: 'PAID',
  ui_total: 'TOTAL',
  ui_item: 'item',
  ui_items: 'items',
};
