;; TrendVault Marketplace Contract

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-brand-owner (err u101))
(define-constant err-invalid-price (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-auction-ended (err u105))
(define-constant err-bid-too-low (err u106))
(define-constant err-no-active-auction (err u107))
(define-constant err-invalid-duration (err u108))
(define-constant err-invalid-rating (err u109))
(define-constant err-invalid-category (err u110))
(define-constant err-empty-batch (err u111))
(define-constant err-batch-too-large (err u112))
(define-constant err-mismatched-lists (err u113))

;; Configuration
(define-constant MAX-BATCH-SIZE u10)

;; [Previous data variables and maps remain unchanged]

;; Enhanced batch listing function with proper validation
(define-public (batch-list-products
    (names (list 10 (string-ascii 100)))
    (descriptions (list 10 (string-ascii 500)))
    (prices (list 10 uint))
    (category-ids (list 10 uint))
  )
  (let
    ((brand (unwrap! (map-get? Brands tx-sender) (err err-not-brand-owner)))
     (count (len names)))
    
    ;; Basic validation
    (asserts! (> count u0) (err err-empty-batch))
    (asserts! (<= count MAX-BATCH-SIZE) (err err-batch-too-large))
    (asserts! (and 
      (is-eq count (len descriptions))
      (is-eq count (len prices))
      (is-eq count (len category-ids))) 
      (err err-mismatched-lists))
    
    ;; Validate each item in batch
    (asserts! (fold check-batch-items prices (ok true)) (err err-invalid-price))
    (asserts! (fold check-categories category-ids (ok true)) (err err-invalid-category))
    
    (ok (map list-product names descriptions prices category-ids))
  )
)

;; Helper functions for batch validation
(define-private (check-batch-items (price uint) (prev (response bool uint)))
  (match prev
    prev-ok (if (> price u0) 
      (ok true)
      (err err-invalid-price))
    prev-err prev-err
  )
)

(define-private (check-categories (category-id uint) (prev (response bool uint)))
  (match prev
    prev-ok (match (map-get? Categories category-id)
      category (if (get active category)
        (ok true)
        (err err-invalid-category))
      (err err-invalid-category))
    prev-err prev-err
  )
)

;; [Rest of the original contract remains unchanged]
