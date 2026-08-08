import 'package:flutter/material.dart';

import '../../utils/external_link_launcher.dart';

class DeveloperArchitectureScreen extends StatefulWidget {
  const DeveloperArchitectureScreen({super.key});

  static const _bg = Color(0xFF090B12);
  static const _panel = Color(0xFF101522);
  static const _panelSoft = Color(0xFF151B2B);
  static const _border = Color(0xFF273247);
  static const _text = Color(0xFFE8EDF7);
  static const _muted = Color(0xFFAAB4C3);
  static const _accent = Color(0xFF8B5CF6);
  static const _accent2 = Color(0xFF22D3EE);

  @override
  State<DeveloperArchitectureScreen> createState() =>
      _DeveloperArchitectureScreenState();
}

class _DeveloperArchitectureScreenState
    extends State<DeveloperArchitectureScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeveloperArchitectureScreen._bg,
      appBar: AppBar(
        backgroundColor: DeveloperArchitectureScreen._bg,
        foregroundColor: DeveloperArchitectureScreen._text,
        elevation: 0,
        title: const Text('Flinder Technical Architecture'),
        centerTitle: false,
        actions: const [_GithubRepoButton(), SizedBox(width: 12)],
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 12,
        radius: const Radius.circular(999),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DocHeader(),
                  SizedBox(height: 22),
                  _ArchitectureImage(),
                  SizedBox(height: 26),
                  _StackGrid(),
                  SizedBox(height: 28),
                  _DocSection(
                    title: 'Executive Summary',
                    paragraphs: [
                      'Flinder is a production-oriented roommate and flatmate discovery platform built with Flutter, FastAPI, Neon Postgres, Google OAuth, OCI infrastructure, Vercel hosting, Firebase notifications, OCI Object Storage, and a separate ML worker for semantic matching.',
                      'The product uses a Tinder-like interaction model, but its core technical differentiator is the recommender. Instead of only matching exact enums such as night owl, music, vegetarian, or quiet home, Flinder builds semantic embeddings for roommate compatibility categories and ranks users by meaning, practical fit, safety rules, and learned swipe behavior.',
                    ],
                  ),
                  _DocSection(
                    title: 'Why The Matching Is Different',
                    bullets: [
                      'Natural language compatibility: free-text lifestyle descriptions affect recommendations.',
                      'Category-specific embeddings: hobbies, interests, traits, personality, likes, and dislikes are modeled separately.',
                      'Conflict-aware scoring: if one user likes something another user dislikes, a semantic penalty is applied.',
                      'Swipe learning: likes and passes gradually tune future recommendations.',
                      'LLM enrichment without LLM ranking: the LLM extracts traits once per profile change; ranking remains deterministic and cheap.',
                      'Graceful fallback: if embeddings are missing, discovery still works with practical scoring.',
                    ],
                  ),
                  _PipelineSection(),
                  _DataModelSection(),
                  _ScoringSection(),
                  _DeploymentSection(),
                  _ApiSection(),
                  _TradeoffsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GithubRepoButton extends StatelessWidget {
  const _GithubRepoButton();

  static const _repoUrl = 'https://github.com/sivajeetsabdakar/Flinder';

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open GitHub repository',
      child: TextButton(
        onPressed: () => openExternalLink(_repoUrl),
        style: TextButton.styleFrom(
          foregroundColor: DeveloperArchitectureScreen._text,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: DeveloperArchitectureScreen._border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.network(
                'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png',
                width: 22,
                height: 22,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.code_rounded,
                      color: DeveloperArchitectureScreen._text,
                      size: 20,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('GitHub', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _DocHeader extends StatelessWidget {
  const _DocHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _boxDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Kicker('FOR RECRUITERS AND DEVELOPERS'),
          SizedBox(height: 10),
          Text(
            'AI-Powered Roommate Matching System',
            style: TextStyle(
              color: DeveloperArchitectureScreen._text,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'A technical walkthrough of Flinder: architecture, data model, semantic vector matching, LLM trait extraction, swipe-learning personalization, deployment, and production tradeoffs.',
            style: TextStyle(
              color: DeveloperArchitectureScreen._muted,
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchitectureImage extends StatefulWidget {
  const _ArchitectureImage();

  @override
  State<_ArchitectureImage> createState() => _ArchitectureImageState();
}

class _ArchitectureImageState extends State<_ArchitectureImage> {
  final TransformationController _controller = TransformationController();
  double _scale = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setScale(double nextScale) {
    final clamped = nextScale.clamp(1.0, 3.2).toDouble();
    setState(() => _scale = clamped);
    _controller.value = Matrix4.identity()..scale(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'System Architecture',
                    style: TextStyle(
                      color: DeveloperArchitectureScreen._text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _ZoomButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom out',
                  onPressed: () => _setScale(_scale - 0.25),
                ),
                const SizedBox(width: 8),
                _ZoomButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Reset zoom',
                  onPressed: () => _setScale(1),
                ),
                const SizedBox(width: 8),
                _ZoomButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom in',
                  onPressed: () => _setScale(_scale + 0.25),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: const Color(0xFF07101D),
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 3.2,
                boundaryMargin: const EdgeInsets.all(80),
                trackpadScrollCausesScale: false,
                onInteractionUpdate: (details) {
                  final scale = _controller.value.getMaxScaleOnAxis();
                  if ((scale - _scale).abs() > 0.01) {
                    setState(() => _scale = scale);
                  }
                },
                child: Image.asset(
                  'assets/architecture/flinder-ai-powered-roommate-matching-system.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DeveloperArchitectureScreen._panelSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DeveloperArchitectureScreen._border),
          ),
          child: Icon(icon, color: DeveloperArchitectureScreen._text, size: 18),
        ),
      ),
    );
  }
}

class _StackGrid extends StatelessWidget {
  const _StackGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Frontend',
        'Flutter Web and Android, Provider state, Google Sign-In, swipe UI, map UI, FCM client hooks.',
      ),
      (
        'Backend',
        'FastAPI, SQLAlchemy, JWT auth, REST APIs, WebSockets, admin routes, notification services.',
      ),
      (
        'Database',
        'Neon PostgreSQL with users, profiles, preferences, swipes, matches, chats, photos, reports, and user_embeds.',
      ),
      (
        'AI / ML',
        'Sentence Transformers, all-MiniLM-L6-v2, cosine similarity, LLM trait extraction, swipe-learning vectors.',
      ),
      (
        'Storage',
        'OCI Object Storage for profile photo uploads, validation, primary photo selection, and cleanup.',
      ),
      (
        'Deployment',
        'Vercel hosts Flutter Web and rewrites /api to the OCI FastAPI backend over current HTTP.',
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final item in items)
          _InfoCard(title: item.$1, body: item.$2, width: 350),
      ],
    );
  }
}

class _PipelineSection extends StatelessWidget {
  const _PipelineSection();

  @override
  Widget build(BuildContext context) {
    return const _DocSection(
      title: 'Semantic Matching Pipeline',
      ordered: [
        'Flutter onboarding captures mixed-format signals: single-choice options, sliders, range sliders, multi-select chips, budget, location, preferences, and free-text bio.',
        'FastAPI builds canonical text for hobbies, interests, traits, personality, likes, and dislikes. It merges profile bio, selected interests, lifestyle fields, generated descriptions, preferences, and LLM-extracted traits.',
        'The optional LLM pass extracts normalized roommate traits as JSON. It is not used for pairwise ranking, which keeps discovery cheaper, reproducible, and easier to debug.',
        'The ML worker generates 384-dimensional embeddings using all-MiniLM-L6-v2 and stores category vectors in user_embeds.',
        'Discovery loads stored embeddings, applies hard safety/practical filters, computes semantic similarity, subtracts conflict penalties, and blends practical plus behavioral scores.',
      ],
    );
  }
}

class _DataModelSection extends StatelessWidget {
  const _DataModelSection();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        'users',
        'Identity, Google subject, role, account status, profile completion, onboarding skip state.',
      ),
      (
        'profiles',
        'Roommate profile, location, budget, lifestyle, languages, completion score.',
      ),
      ('preferences', 'Critical and non-critical matching preferences.'),
      (
        'user_embeds',
        'Category embeddings, model_name, source_hash, llm_traits, canonical_text, status, error, timestamps.',
      ),
      ('swipes / matches', 'Like/pass history and mutual-like match records.'),
      (
        'chats / messages',
        'Conversation state, chat members, realtime message history, read state.',
      ),
      (
        'reports / blocks',
        'Safety, moderation, account review, and visibility enforcement.',
      ),
      (
        'notifications / device_info',
        'Push notification creation, delivery status, and registered devices.',
      ),
      (
        'geocode_cache',
        'Cached city/location lookups to reduce external map/geocoder calls.',
      ),
    ];

    return _DocBlock(
      title: 'Data Model Highlights',
      child: Column(
        children: [
          for (final row in rows) _TableRowLike(label: row.$1, value: row.$2),
        ],
      ),
    );
  }
}

class _ScoringSection extends StatelessWidget {
  const _ScoringSection();

  @override
  Widget build(BuildContext context) {
    return const _DocBlock(
      title: 'Matching Math And Ranking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Paragraph(
            'The recommender combines semantic compatibility, practical fit, swipe-learning personalization, boosts, and safety filters. Raw embeddings are never exposed to normal users.',
          ),
          SizedBox(height: 14),
          _CodePanel(
            lines: [
              'source_hash = SHA256(json(profile, preferences, sorted_keys=true))',
              '',
              'dot(a, b) = sum(a_i * b_i)',
              '||a|| = sqrt(sum(a_i^2))',
              'cosine(a, b) = dot(a, b) / (||a|| * ||b||)',
              'normalized_similarity = (cosine(a, b) + 1) / 2',
              '',
              'semantic_weighted = sum(w_c * s_c for c in categories)',
              'conflict_penalty = min(1.0, raw_conflict * 0.18)',
              'semantic_points = round(clamp(semantic_weighted - conflict_penalty, 0, 1) * 60)',
              '',
              'confidence = min(1.0, signal_count / 30)',
              'learned_points = round(learned_average * 15 * confidence)',
              '',
              'final_score = semantic_points + learned_points + practical_points + boost_points',
            ],
          ),
          SizedBox(height: 14),
          _Paragraph(
            'Current semantic weights are hobbies 0.10, interests 0.20, traits 0.20, personality 0.20, likes 0.15, and dislikes 0.15. Practical points include same city, overlapping budget range, room preference, shared languages, move-in timing, and recent activity.',
          ),
        ],
      ),
    );
  }
}

class _DeploymentSection extends StatelessWidget {
  const _DeploymentSection();

  @override
  Widget build(BuildContext context) {
    return const _DocSection(
      title: 'Production Deployment Model',
      bullets: [
        'Flutter Web is deployed from the frontend root to Vercel and builds to build/web.',
        'Vercel rewrites /api/* to the OCI FastAPI backend, avoiding browser CORS pain while the backend is still on HTTP.',
        'FastAPI runs in a Docker container on an OCI Compute VM and loads production secrets from .env only.',
        'Neon Postgres stores relational product data and embeddings as arrays for v1.',
        'OCI Object Storage stores uploaded profile photos.',
        'The ML worker runs separately on Hugging Face Space or future OCI A1, keeping PyTorch/SentenceTransformer dependencies out of the main API container.',
        'Firebase Cloud Messaging handles Android push notifications, with delivery status persisted for auditability.',
      ],
    );
  }
}

class _ApiSection extends StatelessWidget {
  const _ApiSection();

  @override
  Widget build(BuildContext context) {
    const endpoints = [
      'POST /api/auth/google',
      'GET /api/users/me',
      'POST /api/users/me/onboarding/skip',
      'GET /api/profile/me',
      'PUT /api/profile/me',
      'POST /api/profile/photos/upload',
      'GET /api/discover',
      'POST /api/discover/swipe',
      'POST /api/discover/swipe/rewind',
      'GET /api/discover/likes',
      'GET /api/conversations',
      'WS /api/conversations/{id}/ws',
      'POST /api/reports',
      'POST /api/blocks',
      'POST /internal/ml/profiles/{user_id}/rebuild',
    ];

    return _DocBlock(
      title: 'API Surface Highlights',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final endpoint in endpoints) _EndpointChip(endpoint)],
      ),
    );
  }
}

class _TradeoffsSection extends StatelessWidget {
  const _TradeoffsSection();

  @override
  Widget build(BuildContext context) {
    return const _DocSection(
      title: 'Engineering Tradeoffs And Next Steps',
      bullets: [
        'Embeddings are stored as Postgres arrays instead of pgvector. This keeps v1 simple and cheap; pgvector or ANN search can be added as scale grows.',
        'LLM extraction is optional. If the AI API fails, matching falls back to raw profile and preference text.',
        'The main API avoids ML dependencies to protect memory, startup time, and request latency on the small OCI VM.',
        'The backend currently uses HTTP behind the Vercel frontend proxy. A real API domain and HTTPS termination should be added before a serious public launch.',
        'Future improvements: scheduled stale embedding rebuilds, admin explainability views, structured logging, richer E2E tests, photo moderation, and production error tracking.',
      ],
    );
  }
}

class _DocSection extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<String> ordered;

  const _DocSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.ordered = const [],
  });

  @override
  Widget build(BuildContext context) {
    return _DocBlock(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final paragraph in paragraphs) _Paragraph(paragraph),
          if (bullets.isNotEmpty)
            for (final bullet in bullets) _Bullet(bullet),
          if (ordered.isNotEmpty)
            for (var i = 0; i < ordered.length; i++)
              _NumberedBullet(number: i + 1, text: ordered[i]),
        ],
      ),
    );
  }
}

class _DocBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _DocBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(22),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DeveloperArchitectureScreen._text,
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final double width;

  const _InfoCard({
    required this.title,
    required this.body,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DeveloperArchitectureScreen._panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DeveloperArchitectureScreen._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DeveloperArchitectureScreen._accent2,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: DeveloperArchitectureScreen._muted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: DeveloperArchitectureScreen._muted,
          fontSize: 15,
          height: 1.62,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DeveloperArchitectureScreen._accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _Paragraph(text)),
        ],
      ),
    );
  }
}

class _NumberedBullet extends StatelessWidget {
  final int number;
  final String text;

  const _NumberedBullet({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DeveloperArchitectureScreen._panelSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DeveloperArchitectureScreen._border),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: DeveloperArchitectureScreen._accent2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _Paragraph(text)),
        ],
      ),
    );
  }
}

class _TableRowLike extends StatelessWidget {
  final String label;
  final String value;

  const _TableRowLike({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DeveloperArchitectureScreen._border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: DeveloperArchitectureScreen._accent2,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: DeveloperArchitectureScreen._muted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  final List<String> lines;

  const _CodePanel({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF070A10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DeveloperArchitectureScreen._border),
      ),
      child: Text(
        lines.join('\n'),
        style: const TextStyle(
          color: DeveloperArchitectureScreen._text,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.55,
        ),
      ),
    );
  }
}

class _EndpointChip extends StatelessWidget {
  final String endpoint;

  const _EndpointChip(this.endpoint);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: DeveloperArchitectureScreen._panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DeveloperArchitectureScreen._border),
      ),
      child: Text(
        endpoint,
        style: const TextStyle(
          color: DeveloperArchitectureScreen._text,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  final String text;

  const _Kicker(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: DeveloperArchitectureScreen._accent2,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

BoxDecoration _boxDecoration() {
  return BoxDecoration(
    color: DeveloperArchitectureScreen._panel,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: DeveloperArchitectureScreen._border),
  );
}
