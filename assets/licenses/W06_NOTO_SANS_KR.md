# W06 deterministic Korean UI font provenance

- Asset family: Noto Sans KR variable font (`NotoSansKR[wght].ttf`)
- Runtime materialized path: `assets/runtime/fonts/NotoSansKR-wght.ttf`
- Upstream: Google Fonts (`google/fonts`)
- Pinned upstream commit: `4efc2774c63917927efe769ca845def6bd6debae`
- Pinned source path: `ofl/notosanskr/NotoSansKR[wght].ttf`
- Build source URL: `https://raw.githubusercontent.com/google/fonts/4efc2774c63917927efe769ca845def6bd6debae/ofl/notosanskr/NotoSansKR%5Bwght%5D.ttf`
- SHA-256: `194018e6b2b293a7964f037b25c0249ce1418bc9ab3c971060a03aa57861e252`
- License: SIL Open Font License 1.1
- Local license copy: `assets/licenses/NotoSansKR-OFL.txt`
- Materialization: `tools/fetch_noto_sans_kr.sh` downloads only the pinned upstream object and rejects a SHA-256 mismatch before the font can be imported or exported.
- Product usage: `game/ui/main_shell_medieval_rebuild.gd` replaces the environment-dependent system fallback with this materialized `FontFile` whenever the verified runtime asset is present. W06 and W25 materialize it before Godot import; the production-signing workflow materializes the same pinned font before Android export, so final APK rendering and visual evidence use the same font bytes.
- Placeholder: no
- Review status: approved for redistribution under OFL 1.1, subject to retaining the license copy.
