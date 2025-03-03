;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-key-not-found (err u102))
(define-constant err-expired (err u103))
(define-constant err-invalid-expiration (err u104))
(define-constant err-already-revoked (err u105))
(define-constant err-invalid-data (err u106))

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

;; Events
(define-data-var last-event-id uint u0)

(define-private (emit-event (event-type (string-ascii 12)) (key-id uint))
  (let
    ((event-id (var-get last-event-id)))
    (print { event-id: event-id, type: event-type, key-id: key-id, block: block-height })
    (var-set last-event-id (+ event-id u1))
    true
  )
)

;; Store new key
(define-public (store-key (encrypted-data (string-ascii 256)) (expiration uint) (metadata (string-ascii 256)))
  (let 
    ((new-key-id (var-get key-counter)))
    (asserts! (> expiration block-height) (err err-invalid-expiration))
    (asserts! (not (is-eq encrypted-data "")) (err err-invalid-data))
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
    (emit-event "store" new-key-id)
    (ok new-key-id)
  )
)

;; Update key metadata
(define-public (update-metadata (key-id uint) (new-metadata (string-ascii 256)))
  (let
    ((key-data (unwrap! (map-get? keys {key-id: key-id}) (err err-key-not-found))))
    (asserts! (is-eq (get owner key-data) tx-sender) (err err-not-authorized))
    (map-set keys
      { key-id: key-id }
      (merge key-data { 
        metadata: new-metadata,
        last-modified: block-height
      })
    )
    (emit-event "update" key-id)
    (ok true)
  )
)

;; Permanently revoke key
(define-public (revoke-key (key-id uint))
  (let
    ((key-data (unwrap! (map-get? keys {key-id: key-id}) (err err-key-not-found))))
    (asserts! (is-eq (get owner key-data) tx-sender) (err err-not-authorized))
    (map-set keys
      { key-id: key-id }
      (merge key-data { 
        revoked: true,
        last-modified: block-height
      })
    )
    (emit-event "revoke" key-id)
    (ok true)
  )
)

[Previous functions remain unchanged...]
