# frozen_string_literal: true

module Decidim
  # Decidim::AdminInputScrubber を継承し、SVG sprite アイコン用のタグ・属性を
  # 追加で許可するスクラバー。
  #
  # 背景:
  #   Decidim 0.30.9 (PR #16716) で HTML content block / static page の
  #   admin 入力 HTML が AdminInputScrubber でサニタイズされるようになり、
  #   `<svg><use href="...">` 形式のアイコンが削除されるようになった。
  #   Loofah の HTML5 SafeList::ACCEPTABLE_ELEMENTS に svg/use が含まれない
  #   ためで、AdminInputScrubber は SafeList を直接継承している。
  #
  # 方針:
  #   `<script>` `<style>` `<iframe>` `<object>` 等の真の XSS リスクは
  #   引き続き削除（PR #16716 の防御を維持）。一方で `<svg><use>` 等
  #   表現用の SVG タグだけ追加で許可する。
  #
  # 適用箇所:
  #   config/initializers/extend_sanitize_editor_admin.rb で
  #   Decidim::SanitizeHelper#decidim_sanitize_editor_admin を上書きし、
  #   このスクラバーを使うようにする。HTML content block / Static page /
  #   Static page section など decidim_sanitize_editor_admin を経由する
  #   全箇所で SVG sprite アイコンが書けるようになる。
  class SvgAllowedAdminScrubber < AdminInputScrubber
    # SVG sprite アイコンを書くのに最低限必要なタグ
    SVG_ALLOWED_TAGS = %w(svg use g path circle rect line polyline polygon
                          text title desc defs symbol).freeze

    # SVG sprite 参照と装飾のための属性
    SVG_ALLOWED_ATTRIBUTES = %w(xmlns xmlns:xlink viewBox preserveAspectRatio
                                width height fill stroke stroke-width
                                d cx cy r x y x1 y1 x2 y2 points transform
                                href xlink:href role aria-hidden focusable).freeze

    private

    def custom_allowed_tags
      super + SVG_ALLOWED_TAGS
    end

    def custom_allowed_attributes
      super + SVG_ALLOWED_ATTRIBUTES
    end
  end
end
