import type { Point, ReceiptData, Strings } from '../types';
import { CheckIcon, RegisterIcon, ScanIcon } from '../icons';

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));

export function Receipt({ data, pos, t }: { data: ReceiptData; pos: Point; t: Strings }) {
  const { stage } = data;
  const chip =
    stage === 'paid' ? (
      <span className="chip chip--paid"><CheckIcon /> {t.ui_paid}</span>
    ) : stage === 'scanning' ? (
      <span className="chip chip--scan"><ScanIcon /> {t.ui_scanning}</span>
    ) : (
      <span className="chip"><RegisterIcon size={12} /> {t.ui_to_pay}</span>
    );

  return (
    <div
      className={`receipt receipt--${stage}`}
      style={{ left: `${clamp(pos.x, 0.12, 0.88) * 100}%`, top: `${clamp(pos.y, 0.32, 0.98) * 100}%` }}
    >
      <div className="receipt__head">
        {chip}
        <span className="receipt__count">
          {data.count} {data.count === 1 ? t.ui_item : t.ui_items}
        </span>
      </div>
      <div className="receipt__lines">
        {data.items.length === 0 && stage === 'scanning' && <div className="receipt__empty">{t.ui_scanning_desc}</div>}
        {data.items.map((line) => (
          <div key={line.label} className="line">
            <span className="line__label">{line.label}</span>
            <span className="line__qty">×{line.qty}</span>
            <span className="line__price">{line.priceText}</span>
          </div>
        ))}
        {stage === 'scanning' && data.items.length > 0 && data.scanned < data.count && <div className="scanbar" />}
        {stage === 'paid' && <div className="stamp">{t.ui_paid}</div>}
      </div>
      <div className="receipt__total">
        <span>{t.ui_total}</span>
        <strong key={data.total}>{data.total}</strong>
      </div>
    </div>
  );
}
