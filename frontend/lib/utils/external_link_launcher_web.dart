import 'dart:html' as html;

void openExternalLink(String url) {
  html.window.open(url, '_blank', 'noopener,noreferrer');
}
