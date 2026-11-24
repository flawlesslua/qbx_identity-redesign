import { useEffect } from 'react';

// Browser-only preview (npm run dev, open /?demo). Replays the messages the game would send.
const send = (action: string, data: unknown) => window.postMessage({ action, data }, '*');

export function useDemo(enabled: boolean) {
  useEffect(() => {
    if (!enabled || !new URLSearchParams(window.location.search).has('demo')) return;
    document.body.classList.add('demo');
    const mode = new URLSearchParams(window.location.search).get('demo');

    send('target', {
      label: 'Noodle cup', qty: 1, price: '$3',
      actions: [{ id: 'take', key: 'E', label: 'TAKE' }, { id: 'drop', key: 'G', label: 'DROP' }],
    });
    send('targetPos', { x: 0.3, y: 0.42 });
    send('hint', {
      title: 'Place furniture', subtitle: 'Double shelf',
      keys: [
        { key: 'E', label: 'PLACE' }, { key: 'Wheel', label: 'ROTATE' },
        { key: 'Shift', label: 'FINE' }, { key: 'Backspace', label: 'CANCEL' },
      ],
    });

    const items = [
      { label: 'Kids cereal', qty: 1, priceText: '$5' },
      { label: 'Snack mix', qty: 2, priceText: '$6' },
    ];
    const stages: Record<string, unknown> = {
      scanning: { stage: 'scanning', items: items.slice(0, 1), count: 3, scanned: 1, total: '$5' },
      pay: { stage: 'pay', items, count: 3, scanned: 3, total: '$11' },
      paid: { stage: 'paid', items, count: 3, scanned: 3, total: '$11' },
    };
    send('receipt', stages[mode ?? ''] ?? stages.pay);
    send('receiptPos', { x: 0.72, y: 0.62 });
  }, [enabled]);
}
