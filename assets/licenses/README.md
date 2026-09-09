# Runtime asset provenance policy

Every runtime art, font, sound, music, shader, and third-party content file must have a reviewable source and redistribution/use record before it can be included in a release candidate.

Minimum record per asset family:

- canonical asset/family identifier;
- source or author;
- license/permission and any attribution obligations;
- source-file path and runtime-file path;
- modification/generation history when applicable;
- placeholder flag;
- final review status.

Unverified downloads, scraped assets, watermarked content, and assets with unclear commercial redistribution rights must not enter `assets/runtime`. Placeholder assets may exist during development only when explicitly marked; a release candidate requires placeholder count 0.
