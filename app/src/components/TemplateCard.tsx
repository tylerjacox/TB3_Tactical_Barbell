import type { TemplateDef } from '../templates/definitions';

export function TemplateCard({
  template,
  selected,
  onSelect,
}: {
  template: TemplateDef;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <div
      class="template-card"
      role="radio"
      aria-checked={selected}
      tabIndex={0}
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onSelect();
        }
      }}
    >
      <div class="template-card-name">{template.name}</div>
      <div class="template-card-desc">{template.description}</div>
    </div>
  );
}
