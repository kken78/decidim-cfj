import "leaflet";
import maplibregl from "maplibre-gl";
import "@maplibre/maplibre-gl-leaflet";
import "maplibre-gl/dist/maplibre-gl.css";

// maplibre-gl-leaflet は window.maplibregl を参照する
window.maplibregl = maplibregl;

// Decidim の configure.decidim ハンドラを document に委譲登録する。
// 登録タイミングは Decidim core の DOMContentLoaded より前なので、
// その後 core が trigger("configure.decidim") した時点で確実に発火する。
//
// 設定:
//   MAPS_DYNAMIC_URL = Geolonia の style.json (例: https://geoloniamaps.github.io/basic/style.json)
//   MAPS_API_KEY     = Geolonia の公開API キー
//   MAPS_DYNAMIC_API_KEY=true で options.api_key にキーが伝搬する
//
// style.json 内の `YOUR-API-KEY` プレースホルダは MapLibre の transformRequest で
// リクエスト発生時に実キーに置換する。
$(document).on("configure.decidim", "[data-decidim-map]", (_ev, map, mapConfig) => {
  const tilesConfig = (mapConfig && mapConfig.tileLayer) || {};
  const styleUrl = tilesConfig.url;
  const opts = tilesConfig.options || {};
  // Decidim の to_json は キーを camelCase に変換するため両形をサポート
  const apiKey = opts.api_key || opts.apiKey;

  if (!styleUrl) {
    console.error("[geolonia] MAPS_DYNAMIC_URL (style.json) が未設定です");
    return;
  }
  if (!apiKey) {
    console.warn("[geolonia] MAPS_API_KEY が未設定です。タイル取得が失敗する可能性があります");
  }

  try {
    // L.maplibreGL は L.Layer の汎用拡張で L.GridLayer (tile layer) ではないため、
    // Leaflet の自動 maxZoom 伝搬機構に乗らない。そのままだと map.options.maxZoom が
    // 未設定のままになり、leaflet.markercluster の onAdd が
    //   "Map has no maxZoom specified"
    // で例外を投げて止まり、マーカークラスタの初期化が完了せず、
    // 結果として後段の addMarkers() が "_addChild of undefined" で失敗する。
    // 明示的に map.options へ流し込むことで標準フローを通す。
    if (typeof map.options.maxZoom !== "number") map.options.maxZoom = 22;
    if (typeof map.options.minZoom !== "number") map.options.minZoom = 0;

    // ビュー (center/zoom) が未設定だと map.getCenter() が NaN を返し、
    // MapLibre 内部で "Invalid LatLng (NaN, NaN)" エラーが連発する。
    // Awesome map のように後からマーカー追加で fitBounds する流れでも、
    // 初期描画時には view が必要なので、暫定値 (東京駅) を入れておく。
    // 後段でマーカーが追加されれば fitBounds で上書きされる。
    if (!map._loaded) {
      try {
        map.getCenter();
      } catch (_e) {
        map.setView([35.6812, 139.7671], 10);
      }
    }

    const glLayer = L.maplibreGL({
      style: styleUrl,
      attribution: opts.attribution,
      // Leaflet の tilePane に配置: マーカー類より下に z-index 固定 (200)
      pane: "tilePane",
      // 世界の繰り返し描画を無効化（低ズーム時に地図が複数並ぶのを防ぐ）
      renderWorldCopies: false,
      // YOUR-API-KEY プレースホルダを実キーに動的置換
      transformRequest: (url, _resourceType) => {
        if (apiKey && url.includes("YOUR-API-KEY")) {
          return { url: url.replace(/YOUR-API-KEY/g, apiKey) };
        }
        return { url };
      }
    });
    glLayer.addTo(map);

    // コンテナが遅延表示される場合 (Awesome map の menu, 折りたたみ等)、
    // MapLibre 内部 canvas のサイズが 0 のまま固定されないよう ResizeObserver で追随。
    const container = map.getContainer();
    if (container && typeof ResizeObserver !== "undefined") {
      const ro = new ResizeObserver(() => {
        const inner = glLayer.getMaplibreMap && glLayer.getMaplibreMap();
        if (inner && typeof inner.resize === "function") inner.resize();
        if (typeof map.invalidateSize === "function") map.invalidateSize(false);
      });
      ro.observe(container);
    }
  } catch (err) {
    console.error("[geolonia] tile layer 追加に失敗:", err);
  }
});

// Decidim core の map 初期化処理 ([data-decidim-map] のループ・configure.decidim 発火)
// を読み込む。これがないと configure.decidim が一切発火しない。
import "src/decidim/map";
