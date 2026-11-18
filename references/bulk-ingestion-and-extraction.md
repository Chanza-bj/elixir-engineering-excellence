# Bulk uploads, data extraction, and ingestion pipelines

## Begin with the contract
Before coding, establish:
- Supported formats and versions (CSV, XLSX, fixed-width, XML, JSON, PDF, images, archives, etc.).
- Maximum file size, rows/records, columns, archive depth, and decompressed size.
- Character encoding, delimiter, quoting, date/number formats, locale, and timezone.
- Required/optional fields, mapping rules, reference data, and validation severity.
- Duplicate identity and idempotency scope.
- Whether processing is all-or-nothing, per-row partial success, or staged approval.
- Expected throughput, processing window, user feedback, retention, and audit requirements.

Do not infer a file schema from a sample alone. Confirm the contract and version.

## Upload boundary
- Authenticate and authorize before accepting upload.
- Enforce request and file size limits at proxy, Plug, and storage layers.
- Validate actual content/format; file extension and browser MIME are untrusted.
- Generate server-side object names. Never use client filenames as filesystem paths.
- Store outside the public web root with least-privilege access.
- Use temporary storage with cleanup and retention policies.
- Consider malware scanning and sandboxed parsing for untrusted documents.
- Protect archive extraction against path traversal, symlinks, decompression bombs, and excessive nesting.
- Do not log file contents or sensitive filenames unnecessarily.

## Pipeline architecture
Separate stages:
1. Receive upload and create an import/batch record.
2. Store immutable source file and compute checksum.
3. Validate file envelope and format.
4. Parse incrementally.
5. Normalize into canonical row representation.
6. Validate row fields and cross-row constraints.
7. Stage valid and invalid rows with line/record numbers.
8. Apply records in bounded chunks/transactions.
9. Produce result summary and downloadable error report.
10. Mark final state and preserve audit trail.

For large jobs, use background workers and persistent progress. The HTTP request should not remain open for the entire import.

## Streaming and memory
- Use streaming parsers/readers where available.
- Process fixed-size chunks and release references to completed chunks.
- Bound worker concurrency by CPU, memory, DB pool, and downstream rate limits.
- Avoid `File.read!` for large uploads and `Enum.to_list` over unbounded streams.
- Beware that some spreadsheet/PDF libraries load full documents into memory; test their actual behaviour.
- Do not create one Task per row.
- Use back-pressure or a bounded queue between parsing, validation, and persistence.
- Make batch size configurable and benchmark with realistic data.

## Validation and errors
- Distinguish file-level fatal errors from row-level errors.
- Return record/line number, field, error code, and safe human-readable message.
- Avoid returning full sensitive values in error reports.
- Normalize carefully and preserve original value for audit where permitted.
- Validate references and duplicate constraints both in application logic and database.
- Decide whether valid rows can commit when other rows fail.
- Do not silently coerce malformed values or truncate fields without an explicit rule.
- Protect spreadsheet exports against formula injection by escaping cells beginning with formula-triggering characters according to the output format.

## Idempotency and resumability
- Use checksum plus tenant/source/business key as appropriate; checksum alone may incorrectly reject legitimate identical content.
- Record batch identity and processing version.
- Use unique constraints for row/business identities.
- Make chunk writes repeatable; record committed chunk/row state.
- On retry, resume safely or re-run idempotently.
- Ensure concurrent workers cannot claim the same chunk.
- Make cancellation semantics explicit, including whether already committed chunks remain.

## Data extraction and exports
- Define source query, consistency/snapshot expectation, filters, authorization, and field-level redaction.
- Use keyset pagination or streaming database access for large extracts.
- Do not hold a database transaction open for hours without evaluating vacuum/locking consequences.
- Consider snapshot/export staging when a consistent point-in-time dataset is required.
- Generate large files asynchronously and expose status/download expiry.
- Use signed, short-lived download links where appropriate.
- Audit who requested and downloaded sensitive exports.
- Set output encoding, locale, timezone, decimal formatting, and column ordering explicitly.

## Operational metrics
Track files accepted/rejected, rows parsed/valid/invalid/committed, throughput, chunk duration, queue latency, retries, memory, and failure stage. Avoid high-cardinality metric labels with file names, customer IDs, or transaction IDs.
