;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-key-not-found (err u102))
(define-constant err-expired (err u103))
(define-constant err-invalid-expiration (err u104))
(define-constant err-already-revoked (err u105))

;; Data structures
(define-map keys
  { key-id: uint }
  {
    owner: principal,
    encrypted-data: (string-ascii 256),
    expiration: uint,
    revoked: bool,
    created-at: uint,
    last-modified: uint,
    metadata: (string-ascii 256)
  }
)

(define-map access-rights
  { key-id: uint, user: principal }
  { 
    can-access: bool,
    granted-at: uint,
    last-accessed: uint
  }
)

;; Data vars
(define-data-var key-counter uint u0)

;; Store new key
(define-public (store-key (encrypted-data (string-ascii 256)) (expiration uint) (metadata (string-ascii 256)))
  (let 
    ((new-key-id (var-get key-counter)))
    (asserts! (> expiration block-height) (err err-invalid-expiration))
    (map-set keys
      { key-id: new-key-id }
      {
        owner: tx-sender,
        encrypted-data: encrypted-data,
        expiration: expiration,
        revoked: false,
        created-at: block-height,
        last-modified: block-height,
        metadata: metadata
      }
    )
    (var-set key-counter (+ new-key-id u1))
    (ok new-key-id)
  )
)

;; Transfer key ownership
(define-public (transfer-ownership (key-id uint) (new-owner principal))
  (let
    ((key-data (unwrap! (map-get? keys {key-id: key-id}) (err err-key-not-found))))
    (asserts! (is-eq (get owner key-data) tx-sender) (err err-not-authorized))
    (map-set keys
      { key-id: key-id }
      (merge key-data { 
        owner: new-owner,
        last-modified: block-height
      })
    )
    (ok true)
  )
)

;; Grant access
(define-public (grant-access (key-id uint) (user principal))
  (let
    ((key-data (unwrap! (map-get? keys {key-id: key-id}) (err err-key-not-found))))
    (asserts! (is-eq (get owner key-data) tx-sender) (err err-not-authorized))
    (asserts! (not (get revoked key-data)) (err err-already-revoked))
    (map-set access-rights
      { key-id: key-id, user: user }
      {
        can-access: true,
        granted-at: block-height,
        last-accessed: u0
      }
    )
    (ok true)
  )
)

;; Revoke access
(define-public (revoke-access (key-id uint) (user principal))
  (let
    ((key-data (unwrap! (map-get? keys {key-id: key-id}) (err err-key-not-found))))
    (asserts! (is-eq (get owner key-data) tx-sender) (err err-not-authorized))
    (map-delete access-rights { key-id: key-id, user: user })
    (ok true)
  )
)

;; Get key data
(define-public (get-key-data (key-id uint))
  (let
    ((key-data (unwrap! (map-get? keys {key-id: key-id}) (err err-key-not-found)))
     (access-data (unwrap! (map-get? access-rights {key-id: key-id, user: tx-sender}) (err err-not-authorized))))
    (asserts! (get can-access access-data) (err err-not-authorized))
    (asserts! (not (get revoked key-data)) (err err-not-authorized))
    (asserts! (> (get expiration key-data) block-height) (err err-expired))
    (map-set access-rights
      { key-id: key-id, user: tx-sender }
      (merge access-data { last-accessed: block-height })
    )
    (ok (get encrypted-data key-data))
  )
)

;; Read-only functions
(define-read-only (get-key-info (key-id uint))
  (map-get? keys {key-id: key-id})
)

(define-read-only (get-access-info (key-id uint) (user principal))
  (map-get? access-rights {key-id: key-id, user: user})
)
