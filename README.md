
---

````markdown
# PdforgeClient

Rails-friendly Ruby client for the [Pdforg PDF microservice](https://github.com/yourorg/pdforge).  
Signs requests with HMAC, posts HTML or URL payloads, and returns generated PDF bytes.

---

## Installation

Add this line to your application's Gemfile:

```ruby
gem "pdforge_client", github: "yourorg/pdforge_client"
````

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install pdforge_client
```

---

## Configuration

In your Rails app, add an initializer:

```ruby
# config/initializers/pdforge_client.rb
PdforgeClient.configure do |c|
  c.endpoint = ENV.fetch("PDF_SERVICE_URL") # e.g. https://your-pdf-service.herokuapp.com/pdf
  c.hmac_key = ENV.fetch("PDF_HMAC_KEY")
  c.open_timeout = 5    # seconds (default)
  c.read_timeout = 30   # seconds (default)
  c.default_options = { printBackground: true, format: "Letter" }
end
```

Environment variables to set in your Rails app (match your PDF service’s config):

```bash
PDF_SERVICE_URL=https://your-pdf-service.herokuapp.com/pdf
PDF_HMAC_KEY=supersecret-long-random
```

---

## Usage

### From HTML

```ruby
html = render_to_string(template: "invoices/show", layout: "pdf", locals: { invoice: @invoice })

pdf_bytes = PdforgeClient.from_html(html, {
  printBackground: true,
  format: "Letter",
  margin: { top: "0.5in", right: "0.5in", bottom: "0.5in", left: "0.5in" },
  displayHeaderFooter: true,
  footerTemplate: '<div style="font-size:10px;width:100%;text-align:center;"><span class="pageNumber"></span>/<span class="totalPages"></span></div>'
})

send_data pdf_bytes, type: "application/pdf", disposition: "inline", filename: "invoice.pdf"
```


### From HTML with field positions (`/pdfmeta`)

Use this when the PDF service should return signature/field coordinates
alongside the PDF (e.g. for PandaDoc placement):

```ruby
result = PdforgeClient.from_html_meta(html, {
  printBackground: true,
  format: "Letter",
  landscape: true
})

pdf_bytes = result[:pdf_data]
positions = result[:positions]
```

The client posts to `/pdfmeta` with `pipeline: "generate_pdf"` and
`timeoutMs` (default `Config#render_timeout_ms`). `endpoint` may be the
service root or end in `/pdf`; `/pdfmeta` is derived either way.

### From URL

```ruby
pdf_bytes = PdforgeClient.from_url("https://example.com/print/123", {
  baseUrl: "https://example.com",
  printBackground: true,
  format: "A4"
})

File.binwrite("report.pdf", pdf_bytes)
```

### From DOCX

```ruby
docx_bytes = File.binread("invoice.docx")
pdf_bytes  = PdforgeClient.from_docx(docx_bytes)

File.binwrite("invoice.pdf", pdf_bytes)
```

The DOCX is base64-encoded and posted to the service's `/pdf/docx` route,
which converts it via headless LibreOffice. The `options` hash is accepted
for forward compatibility but is currently ignored server-side — Puppeteer
options like `format` or `margin` do not apply to the LibreOffice pipeline.

You do **not** need to change your `endpoint` config — if it already ends in
`/pdf`, the client appends `/docx` automatically.

---

## Options

The `options` hash maps to [Puppeteer’s `page.pdf()` options](https://pptr.dev/api/puppeteer.page.pdf), with a couple extras:

| Option                | Type          | Default    | Notes                                                                                                   |
| --------------------- | ------------- | ---------- | ------------------------------------------------------------------------------------------------------- |
| `format`              | string        | `"Letter"` | Common: `"Letter"`, `"A4"`, `"Legal"`, `"Tabloid"`, `"A3"`, `"A5"`, etc.                                |
| `width` / `height`    | string/number | —          | Explicit dimensions instead of `format` (e.g. `"8.5in"`, `"210mm"`).                                    |
| `margin`              | object        | `0`        | `{ top, right, bottom, left }` (string/number, e.g. `"1in"`, `"20mm"`).                                 |
| `scale`               | number        | `1.0`      | Zoom level between 0.1 and 2.                                                                           |
| `printBackground`     | boolean       | `false`    | Include CSS backgrounds/images.                                                                         |
| `displayHeaderFooter` | boolean       | `false`    | Enable `headerTemplate` / `footerTemplate`.                                                             |
| `headerTemplate`      | string (HTML) | `""`       | HTML snippet for header. Use `<span class="pageNumber"></span>` and `<span class="totalPages"></span>`. |
| `footerTemplate`      | string (HTML) | `""`       | Same for footer.                                                                                        |
| `preferCSSPageSize`   | boolean       | `false`    | Use CSS `@page size` if present.                                                                        |
| `landscape`           | boolean       | `false`    | Print in landscape orientation.                                                                         |
| **Extras we added:**  |               |            |                                                                                                         |
| `baseUrl`             | string        | —          | Injects a `<base>` tag so relative assets (CSS/images) resolve.                                         |
| `html`                | string        | —          | Inline HTML content to render.                                                                          |
| `url`                 | string        | —          | Remote URL to load and render.                                                                          |

---

## Example Initializer + Controller

```ruby
# config/initializers/pdforge_client.rb
PdforgeClient.configure do |c|
  c.endpoint = ENV.fetch("PDF_SERVICE_URL")
  c.hmac_key = ENV.fetch("PDF_HMAC_KEY")
  c.default_options = { printBackground: true, format: "Letter" }
end
```

```ruby
class InvoicesController < ApplicationController
  def show_pdf
    @invoice = Invoice.find(params[:id])
    html = render_to_string(template: "invoices/show", layout: "pdf", locals: { invoice: @invoice })
    pdf = PdforgeClient.from_html(html, printBackground: true, format: "Letter")
    send_data pdf, type: "application/pdf", disposition: "inline", filename: "invoice-#{@invoice.id}.pdf"
  end
end
```

---

## Development

Run tests and open console:

```bash
bundle install
rake test
bin/console
```

Inside the console:

```ruby
require "pdforge_client"

PdforgeClient.configure do |c|
  c.endpoint = ENV["PDF_SERVICE_URL"]
  c.hmac_key = ENV["PDF_HMAC_KEY"]
end

pdf = PdforgeClient.from_html("<h1>Test PDF</h1>")
File.binwrite("test.pdf", pdf)
```

---

## License
