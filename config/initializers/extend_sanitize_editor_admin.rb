# frozen_string_literal: true

# Decidim 0.30.9 (PR #16716) で導入された admin 入力 HTML サニタイズの
# 設定を、CfJ 運用都合に合わせて拡張する。
#
# 何をするか:
#   Decidim::SanitizeHelper#decidim_sanitize_editor_admin が内部で使う
#   スクラバーを Decidim::AdminInputScrubber から
#   Decidim::SvgAllowedAdminScrubber に切り替える。
#
# なぜ必要か:
#   HTML content block（参加プロセスのホームページの「自由HTML枠」）等で
#   `<svg><use href="...">` 形式の SVG sprite アイコンを使った既存運用
#   （Decidim 0.29 以前から品川区が用いている運用）を維持するため。
#   Decidim 標準の AdminInputScrubber は SVG タグを許可しないため、
#   0.30.9 にアップグレード後に既存の SVG アイコンが消えてしまう。
#
# セキュリティトレードオフ:
#   PR #16716 の本来の目的 = admin 乗っ取り経由の Stored XSS 防止 は
#   引き続き有効。<script>, <style>, <iframe>, <object>, <embed> 等の
#   危険タグは引き続き削除される。
#   許可するのは表現用の SVG タグ（svg, use, g, path, circle, rect 等）と
#   その属性（viewBox, href, xlink:href 等）のみ。SVG タグ内の <script>
#   サブ要素も whitelist に無いので除去される。
#
# 影響範囲:
#   decidim_sanitize_editor_admin を経由する全 admin 入力 HTML 出力箇所。
#   - HtmlCell (HTML content block)
#   - SummaryCell / SectionCell / TwoPaneSectionCell (Static page)
#
# 関連:
#   - app/scrubbers/decidim/svg_allowed_admin_scrubber.rb
#   - https://github.com/decidim/decidim/pull/16451 (元の PR)
#   - https://github.com/decidim/decidim/pull/16716 (0.30 へのバックポート)

Rails.application.config.to_prepare do
  Decidim::SanitizeHelper.module_eval do
    def decidim_sanitize_editor_admin(html, options = {})
      html = Decidim::IframeDisabler.new(html, options).perform
      decidim_sanitize_editor(
        decidim_rich_text(html),
        { scrubber: Decidim::SvgAllowedAdminScrubber.new }.merge(options)
      )
    end
  end
end
