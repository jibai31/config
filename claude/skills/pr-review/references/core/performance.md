# Review checklist: Performance

Part of the pr-review core checklist. It lists *where problems hide*, not rules to enforce everywhere. Only
comment when you can point at a line and name the consequence. Stack packs and the project guide override this file.

Only flag what will matter at the project's realistic scale; name the number (rows, items, calls, ms).

- **N+1 / calls in loops.** A query, request or expensive call per item. Trace to where the collection is loaded
  before flagging.
- **Unbounded work.** Loading all rows/items without pagination or batching; lists rendered without virtualization;
  unbounded caches or arrays that grow forever.
- **Wrong place.** Filtering/sorting in app code what the database could do; heavy work on a request/UI thread that
  belongs in a background job or worker.
- **Repeated work.** Recomputing on every call/render what could be computed once; re-fetching data already loaded.
- **Indexes** for new query patterns (where/order/join columns). Confirm against the schema first.
- **Startup and hot paths.** New work added to app start, every request, or every render.
- **Payload size.** Over-fetching fields or nested data; large assets shipped where smaller would do.
