---
version: 1
slug: "feed-presentation-widgets-post-card-dart-af0870eb"
primary_target: "lib/features/feed/presentation/widgets/post_card.dart"
related_targets: ["lib/features/feed/presentation/screens/feed_screen.dart"]
---

# Surface Brief: Faunova Feed & Post Card

- Scope: Social Feed (`feed_screen.dart`), timeline tabs ("Untuk Kamu", "Mengikuti"), and Observation Post Card (`post_card.dart`).
- Mode: Experience.
- Audience: Indonesian biology students and passionate wildlife observers.
- Job: Discover credible, tamper-evident wildlife sightings, inspect species verification & hash blocks, and engage with community observers.
- Primary Action: View sighting details, verify blockchain proof, like/share observation.
- Benchmark: iNaturalist + Seek (rigorous taxon documentation meets modern, refined mobile social feed).
- Constraints: Exact coordinates strictly hidden (grid-snapped only); Bahasa Indonesia UI text; 4 states handled (loading, empty, error, offline); AGENTS.md color tokens respected.
- Approved Comp: .impeccable/mocks/canon-taxon-specimen.png


## Direction contract

THESIS: A credible, verifiable wildlife field feed that treats observations as tamper-evident scientific records rather than disposable social media fodder, executed with the craft and polish of iNaturalist and modern mobile apps.
OWN-WORLD: Ivory background (#F7F4ED), solid sage muda observation cards (#C7D3C0), sage tua headers & active icons (#5C7457), deep forest text (#1F2A1E), and gold verification accents (#C8A96B, #7F6326). Solid surfaces, crisp borders, and zero muddy gradients or AI slop.
STORY: Observers browse a clean timeline of fauna sightings, instantly distinguish verified species from unverified ones via cryptographic block badges, inspect grid locations, and engage with peers.
FIRST VIEWPORT: Top header with Faunova wordmark and tab selector ("Untuk Kamu" / "Mengikuti"). Below, high-impact edge-to-edge observation card with photographer avatar, verified checkmark, high-definition species photo, IUCN conservation badge, taxon taxonomy chips, and block hash pill.
FORM: Canon (The Category Standard), executed with iNaturalist-level scientific craft; seed:8d07ab1fd0db07e1.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
