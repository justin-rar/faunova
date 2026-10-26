# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Mixed audience of biology/conservation students and hobbyist wildlife observers (ages 18–35) in Indonesia. They use Faunova in two contexts: (1) in the field — photographing, identifying, and logging wildlife sightings with GPS, compass heading, and AI species recognition; (2) at home — browsing a social timeline of verified fauna observations from others, engaging via likes, follows, comments, and sharing their own verified sightings. Credibility matters: users want their observations to be tamper-evident and verifiable, distinguishing Faunova from casual photo-sharing.

## Product Purpose

Faunova is a social field journal for wildlife observation. It combines verified wildlife documentation (cryptographic SHA-256 hash-chain, AI species identification, GPS/compass metadata) with social engagement (timeline feed, likes, follows, sharing). The product makes it possible to build a trustworthy, tamper-evident record of wildlife sightings while participating in a community of observers. Success means users regularly log sightings, verify their authenticity, and discover other observers' documented wildlife.

## Positioning

The verifiable field journal that doubles as a social network. Each observation is locked into a canonical SHA-256 hash-chain that makes falsification detectable — a mechanism no casual wildlife app provides. Combined with AI-powered species identification, gamification (quizzes, streaks, badges), and a Midtrans-powered verified account system, Faunova occupies the intersection of scientific rigor and social engagement that neither iNaturalist (science-first, no social) nor Instagram (social-first, no verification) covers.

## Operating Context

- Field capture: camera viewfinder with GPS lock, compass heading, AI scan → observation saved to local encrypted Hive cache and synced to Supabase
- Social feed: "Untuk Kamu" (For You) and "Mengikuti" (Following) tabs with post cards showing species, conservation status, location grid, and chain block number
- Profile: portfolio of observations, collection grid, chain verification audit, badge shelf, follower/following lists
- Game: streak tracker, daily challenge quizzes, shake-to-quiz with server-scored answers
- Search: taxonomic category filters, verified account discovery
- Settings: biometric lock, notification preferences, privacy controls, trash management

## Capabilities and Constraints

- Stack: Flutter (Dart) with Supabase (Auth, Postgres with RLS, Storage, Edge Functions), Gemini/DeepSeek AI for species identification, Midtrans Sandbox for verified account payments
- All UI text is in Indonesian (Bahasa Indonesia)
- Cryptographic hash-chain integrity must be preserved — visual changes must not alter any business logic
- RLS enforced on all tables; secrets never in client code
- Precise coordinates never exposed publicly (grid-snapped only)
- Four mandatory UI states on every screen: loading, empty, error, offline
- Bottom navigation bar uses glassmorphism blur effect with sliding pill indicator

## Brand Commitments

- Name: Faunova
- Logo: `assets/images/faunova_logo.png`
- Voice: scientific credibility blended with accessible, community-oriented Indonesian language
- Visual Direction: Category Standard (Canon). Clean, modern social nature app conventions executed at full fidelity with immaculate craft, high readability, and zero AI slop.
- Benchmark Products: iNaturalist + Seek (gold standard for biodiversity documentation, field observation, taxon identification, and citizen science credibility).
- Palette fidelity: Anchored in AGENTS.md design tokens — sage tua `#5C7457`, sage `#8FA28A`, sage muda `#C7D3C0`, gading `#F7F4ED`, emas `#C8A96B`, emas tua `#7F6326`, teks gelap `#1F2A1E`, status merah `#B3261E`.



## Evidence on Hand

- Working Android app with 190+ passing tests
- Demo mode with synthetic data for all screens
- No real user testimonials or press to reference
- No commercial launch yet

## Product Principles

1. **Verification is the foundation.** Every observation's integrity is provable. The chain never lies.
2. **Field-first, social-second.** The capture experience must work reliably in outdoor conditions before the social layer adds value.
3. **Indonesian context, global standard.** UI speaks Indonesian; the technical substrate (cryptography, AI, cloud) meets international engineering standards.
4. **Earned credibility.** Badges, verified accounts, and streak records are earned through real participation, never purchased or fabricated.
5. **Privacy by architecture.** Exact coordinates stay private; public data is always grid-snapped. Biometric lock, encrypted storage, and EXIF stripping are defaults, not options.
