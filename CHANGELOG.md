## [Unreleased]

## [0.1.1] - 2026-05-12

- Add `PdforgeClient.from_docx(docx_bytes, options)` for DOCX → PDF conversion
  via the pdforge service's new `/pdf/docx` endpoint.
- `Config#endpoint` is unchanged for existing callers; the DOCX route is
  derived (`<endpoint>/docx` when endpoint ends in `/pdf`, else
  `<endpoint>/pdf/docx`).

## [0.1.0] - 2025-09-17

- Initial release
