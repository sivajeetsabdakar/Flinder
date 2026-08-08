import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';

class DeveloperArchitectureScreen extends StatelessWidget {
  const DeveloperArchitectureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      useAppBar: true,
      showBackButton: true,
      title: 'How Flinder Works',
      maxContentWidth: 1160,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 88, 0, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroIntro(),
            const SizedBox(height: 24),
            _ArchitectureImage(),
            const SizedBox(height: 28),
            const Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MetricPill(label: 'Frontend', value: 'Flutter Web + Android'),
                _MetricPill(label: 'Backend', value: 'FastAPI on OCI'),
                _MetricPill(label: 'Database', value: 'Neon PostgreSQL'),
                _MetricPill(label: 'AI/ML', value: 'Embeddings + LLM traits'),
              ],
            ),
            const SizedBox(height: 28),
            _Section(
              title: 'What Makes It Unique',
              body:
                  'Flinder is not a normal enum-based roommate matcher. The app captures structured preferences, free-text personality signals, likes, dislikes, habits, budget, location, and swipe behavior. The backend then blends practical constraints with semantic vector similarity, so profiles can match by meaning even when users write different words.',
            ),
            _Section(
              title: 'AI Matching Pipeline',
              body:
                  'When a user updates their profile, FastAPI builds category-specific canonical text for hobbies, interests, traits, personality, likes, and dislikes. An optional LLM pass extracts normalized roommate traits as JSON. A separate ML worker generates sentence-transformer embeddings and stores them in Neon inside the user_embeds table.',
            ),
            _Section(
              title: 'Recommendation Engine',
              body:
                  'Discovery first applies hard filters: profile completion, blocks, already-swiped users, location, and availability. Candidates are then ranked with semantic compatibility, budget and room fit, city match, language overlap, move-in timing, recent activity, boost status, and learned swipe preferences.',
            ),
            const _FormulaPanel(),
            _Section(
              title: 'Swipe Learning',
              body:
                  'Flinder learns from behavior after enough swipes exist. Liked profiles push the user preference vector positively, while passed profiles pull it away with a smaller negative weight. This makes recommendations more personal over time without retraining a large model.',
            ),
            _Section(
              title: 'Production Architecture',
              body:
                  'Flutter Web is hosted on Vercel and proxies /api requests to the OCI FastAPI backend. Neon stores relational product data and vectors. OCI Object Storage handles profile photos. Firebase Cloud Messaging supports Android push. The ML worker runs separately so the main API stays lightweight and responsive.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For Recruiters and Developers',
          style: AppTheme.headingStyle.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Text(
            'A technical walkthrough of Flinder: a production-oriented roommate matching app with Flutter, FastAPI, Neon, OCI, realtime chat, and AI-powered semantic recommendations.',
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.lightGrey,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArchitectureImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.34),
          border: Border.all(color: AppTheme.lightPurple.withOpacity(0.35)),
        ),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.asset(
            'assets/architecture/flinder-ai-powered-roommate-matching-system.png',
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.lightPurple,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.subheadingStyle.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.subheadingStyle.copyWith(fontSize: 21)),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTheme.bodyStyle.copyWith(color: AppTheme.lightGrey),
          ),
        ],
      ),
    );
  }
}

class _FormulaPanel extends StatelessWidget {
  const _FormulaPanel();

  @override
  Widget build(BuildContext context) {
    const formulas = [
      'cosine(a, b) = dot(a, b) / (||a|| * ||b||)',
      'normalized_similarity = (cosine(a, b) + 1) / 2',
      'semantic_weighted = sum(w_c * s_c for c in categories)',
      'conflict_penalty = min(1.0, raw_conflict * 0.18)',
      'semantic_points = round(semantic_final * 60)',
      'confidence = min(1.0, signal_count / 30)',
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentPink.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Core Scoring Formulas',
            style: AppTheme.subheadingStyle.copyWith(fontSize: 21),
          ),
          const SizedBox(height: 12),
          for (final formula in formulas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                formula,
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
