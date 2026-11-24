import type { HintData } from '../types';
import { KeyCap } from './KeyCap';
import { WrenchIcon } from '../icons';

export function HintBar({ data }: { data: HintData }) {
  return (
    <div className="hint">
      <span className="hint__icon"><WrenchIcon /></span>
      <div className="hint__title">
        <strong>{data.title}</strong>
        {data.subtitle && <span>{data.subtitle}</span>}
      </div>
      {data.counter !== undefined && <span className="hint__counter">{data.counter}</span>}
      <div className="hint__keys">
        {data.keys.map((k) => (
          <div key={k.label} className="hint__key">
            <KeyCap k={k.key} />
            <span>{k.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
