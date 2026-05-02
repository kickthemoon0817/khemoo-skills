# Design Reviewer

## Look for

- Design tokens used over hardcoded values: `var(--color-primary)` not `#3366ff`; `var(--space-4)` not `16px`
- Spacing scale consistency: new values fall on the existing scale
- Color palette consistency: new colors derive from the palette; no near-duplicates
- Typography hierarchy: matches existing text styles; no new style without reason
- Component variant proliferation: check if an existing variant covers the case
- Dark mode parity (if the project supports themes)
- Z-index: fits the stacking layer scheme; no `z-index: 9999` magic numbers

## Do NOT flag

- Behavior, interaction, accessibility → UI/UX
- CSS code organization → Quality
- Bundle size impact → Performance
