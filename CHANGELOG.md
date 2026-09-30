## [Unreleased]

## [0.1.2] - 2026-09-30

- Add `PdforgeClient.from_html_meta(html, options, timeout_ms:)` for the
  `/pdfmeta` pipeline. Returns `{ pdf_data:, positions: }` (decoded PDF bytes
  plus field positions) instead of a raw PDF body.
- Derive the meta endpoint from `Config#endpoint` the same way DOCX does
  (`…/pdf` → `…/pdfmeta`).
- Default `read_timeout` to 20s and add `render_timeout_ms` (18000) so request
  budgets stay under Heroku's 30s router limit.


## [0.1.1] - 2026-05-12

- Add `PdforgeClient.from_docx(docx_bytes, options)` for DOCX → PDF conversion
  via the pdforge service's new `/pdf/docx` endpoint.
- `Config#endpoint` is unchanged for existing callers; the DOCX route is
  derived (`<endpoint>/docx` when endpoint ends in `/pdf`, else
  `<endpoint>/pdf/docx`).

## [0.1.0] - 2025-09-17

- Initial release
