# Single source of truth for the service worker cache version.
# Referenced by:
#   - app/views/pwa/service-worker.js.erb  (CACHE_VERSION constant)
#   - app/views/layouts/application.html.erb (meta tag for JS access)
#   - app/javascript/controllers/prefetch_controller.js (fallback cache name)
Rails.application.config.sw_cache_version = "lighthouse-v11"
