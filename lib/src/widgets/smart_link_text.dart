import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SmartLinkText extends StatelessWidget {
  final String link;
  final Color color;
  final String prefix;

  const SmartLinkText({
    super.key,
    required this.link,
    required this.color,
    this.prefix = 'Link: ',
  });

  Future<void> _openLink(BuildContext context) async {
    final clean = link.trim();

    if (clean.isEmpty) {
      return;
    }

    final normalized =
        clean.startsWith('http://') || clean.startsWith('https://')
            ? clean
            : 'https://$clean';

    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link açılamadı.'),
          ),
        );
      }

      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link açılamadı.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link açılamadı.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clean = link.trim();

    if (clean.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openLink(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.open_in_new_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$prefix$clean',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    height: 1.35,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}