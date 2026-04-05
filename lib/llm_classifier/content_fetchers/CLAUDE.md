# Content Fetchers

Utilities for fetching external content to use as classification input. Not wired into `Classifier` automatically -- callers fetch content and pass it in.

## Inventory

- `Base` - Abstract interface. Subclasses implement `#fetch(source)`
- `Web` - HTTP fetcher with SSRF protection, redirect following, and HTML text extraction
- `Null` - No-op fetcher, always returns `nil`

## SSRF Protection (`Web`)

- Validates resolved IPs against private/loopback CIDR ranges before connecting
- Follows up to 3 redirects, re-validating each redirect target
- `normalize_redirect_url` handles relative and absolute redirect URLs
- Uses `nil? || empty?` guards (not ActiveSupport `.blank?`) to avoid the dependency

## HTML Processing (`Web`)

- Nokogiri is lazily loaded (`require "nokogiri"` inside the method) since it's an optional dependency
- Strips `<script>`, `<style>`, `<nav>`, `<footer>`, `<header>` elements
- Truncates extracted text to 2000 characters

## Related

- [../adapters/CLAUDE.md](../adapters/CLAUDE.md) - LLM adapters
- [../../spec/CLAUDE.md](../../spec/CLAUDE.md) - Testing conventions
