# UI/UX Reviewer

## Look for

- Keyboard navigation: every interactive element reachable via Tab; focus order logical; no focus traps without dismiss
- Accessibility: semantic HTML over divs; ARIA labels where needed; color contrast WCAG AA; alt text on meaningful images
- Touch targets: ~44x44px minimum on mobile; spacing between adjacent targets
- States: loading, empty, error, disabled, success — all handled
- Responsive: content reflows or scrolls at common breakpoints (≤768px, ≤480px); no horizontal scroll on mobile unless intentional
- Interaction feedback: visible click/tap response within ~100ms; long ops show progress
- Form UX: inline validation, clear error messages, required-field indicators, predictable submit

## Do NOT flag

- Visual styling, color, typography → Design
- CSS architecture, naming → Quality
- JS logic → Code
