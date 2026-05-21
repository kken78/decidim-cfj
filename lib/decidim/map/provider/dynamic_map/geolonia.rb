# frozen_string_literal: true

module Decidim
  module Map
    module Provider
      module DynamicMap
        # Geolonia(MapLibre GL JS)向け Dynamic Map プロバイダ。
        #
        # 親クラスの tile_layer_configuration は
        #   { url: MAPS_DYNAMIC_URL, options: { attribution: ... } }
        # を返す。Geolonia は style.json 内の YOUR-API-KEY プレースホルダを
        # MapLibre 側 transformRequest で実キーに置換するため、options.api_key を
        # ここで明示的に注入する。
        class Geolonia < ::Decidim::Map::DynamicMap
          class Builder < Decidim::Map::DynamicMap::Builder
            def append_assets
              template.append_stylesheet_pack_tag("decidim_map")
              template.append_javascript_pack_tag("decidim_map_provider_geolonia")
            end
          end

          protected

          def tile_layer_configuration
            base = super
            api_key = configuration[:api_key]
            # Decidim secrets で MAPS_DYNAMIC_API_KEY=true (文字列) のときも
            # 実キー (MAPS_API_KEY) を採用する。
            if api_key.nil? || api_key == true || api_key == "true"
              api_key = Decidim.maps.is_a?(Hash) ? Decidim.maps[:api_key] : nil
            end
            base[:options] ||= {}
            base[:options][:api_key] = api_key if api_key.present?
            base
          end
        end
      end
    end
  end
end
