import { useEffect, useState } from 'react';
import { TargetLabel } from './components/TargetLabel';
import { Receipt } from './components/Receipt';
import { HintBar } from './components/HintBar';
import { isBrowser, post } from './nui';
import { play } from './sounds';
import { defaultStrings } from './types';
import type { HintData, Point, ReceiptData, Strings, TargetData } from './types';
import { useDemo } from './demo';

type Message =
  | { action: 'target'; data: TargetData | false }
  | { action: 'targetPos'; data: Point | false }
  | { action: 'receipt'; data: ReceiptData | false }
  | { action: 'receiptPos'; data: Point | false }
  | { action: 'hint'; data: HintData | false }
  | { action: 'locale'; data: Strings }
  | { action: 'sound'; data: string };

export function App() {
  const [strings, setStrings] = useState<Strings>(defaultStrings);
  const [target, setTarget] = useState<TargetData | null>(null);
  const [targetPos, setTargetPos] = useState<Point | null>(null);
  const [receipt, setReceipt] = useState<ReceiptData | null>(null);
  const [receiptPos, setReceiptPos] = useState<Point | null>(null);
  const [hint, setHint] = useState<HintData | null>(null);

  useEffect(() => {
    const onMessage = (event: MessageEvent<Message>) => {
      const msg = event.data;
      if (!msg || typeof msg !== 'object' || !('action' in msg)) return;
      switch (msg.action) {
        case 'target':
          setTarget(msg.data || null);
          break;
        case 'targetPos':
          setTargetPos(msg.data || null);
          break;
        case 'receipt':
          setReceipt(msg.data || null);
          break;
        case 'receiptPos':
          setReceiptPos(msg.data || null);
          break;
        case 'hint':
          setHint(msg.data || null);
          break;
        case 'locale':
          setStrings({ ...defaultStrings, ...msg.data });
          break;
        case 'sound':
          play(msg.data);
          break;
      }
    };
    window.addEventListener('message', onMessage);
    void post('ready');
    return () => window.removeEventListener('message', onMessage);
  }, []);

  useDemo(isBrowser);

  return (
    <>
      {target && targetPos && <TargetLabel data={target} pos={targetPos} />}
      {receipt && receiptPos && <Receipt data={receipt} pos={receiptPos} t={strings} />}
      {hint && <HintBar data={hint} />}
    </>
  );
}
