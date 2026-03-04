# Provides same-origin verification for sync endpoints that skip CSRF token
# verification. When a valid X-CSRF-Token header is present (and verifies
# against the session) the request is allowed through. Otherwise we fall
# back to checking the Origin / Referer header to confirm the request came
# from the same host — browsers always include Origin on cross-origin POSTs,
# so a CSRF attack from another site will be blocked.
module SyncCsrfProtection
  extend ActiveSupport::Concern

  private

  def verify_sync_origin
    # Allow if a valid CSRF token is present and verifies against the session
    token = request.headers["X-CSRF-Token"]
    return if token.present? && valid_authenticity_token?(session, token)

    # Fallback: verify the request originated from the same host
    origin = request.headers["Origin"]
    return if origin.present? && (URI.parse(origin).host == request.host rescue false)

    referer = request.headers["Referer"]
    return if referer.present? && (URI.parse(referer).host == request.host rescue false)

    head :forbidden
  end
end
