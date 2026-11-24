import type { Point, TargetData } from '../types';
import { KeyCap } from './KeyCap';
import { CardIcon, RegisterIcon } from '../icons';

export function TargetLabel({ data, pos }: { data: TargetData; pos: Point }) {
  const actions = data.actions ?? [];
  return (
    <div className="target" style={{ left: `${pos.x * 100}%`, top: `${pos.y * 100}%` }}>
      <span className="target__dot" />
      <div className="target__body">
        <div className={`pill ${data.muted ? 'pill--muted' : ''} ${data.price ? '' : 'pill--noprice'}`}>
          {data.icon && (
            <span className="pill__icon">{data.icon === 'card' ? <CardIcon /> : <RegisterIcon />}</span>
          )}
          <span className="pill__label">{data.label}</span>
          {data.qty !== undefined && data.qty !== null && <span className="pill__qty">×{data.qty}</span>}
          {data.price && <span className="pill__price">{data.price}</span>}
        </div>
        {actions.length > 0 && (
          <div className="actions">
            {actions.map((a) => (
              <div key={a.id} className={`action ${a.subtle ? 'action--subtle' : ''}`}>
                <KeyCap k={a.key} />
                <span>{a.label}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
