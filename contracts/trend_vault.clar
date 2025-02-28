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

;; Data Variables
(define-data-var platform-fee uint u25) ;; 2.5% fee
(define-data-var product-counter uint u0)

;; Events
(define-data-var last-event-id uint u0)

(define-map Categories uint 
  {
    name: (string-ascii 50),
    active: bool
  }
)

;; Original maps with added category support
(define-map Products uint 
  {
    brand: principal,
    name: (string-ascii 100),
    description: (string-ascii 500),
    price: uint,
    available: bool,
    created-at: uint,
    is-auction: bool,
    category-id: uint
  }
)

;; [Previous maps remain unchanged]

;; Enhanced product listing with category
(define-public (list-product 
    (name (string-ascii 100))
    (description (string-ascii 500))
    (price uint)
    (category-id uint)
  )
  (let
    ((brand (unwrap! (map-get? Brands tx-sender) (err err-not-brand-owner)))
     (category (unwrap! (map-get? Categories category-id) (err err-invalid-category)))
     (product-id (+ (var-get product-counter) u1)))
    
    (asserts! (get active category) (err err-invalid-category))
    (asserts! (> price u0) (err err-invalid-price))
    
    (begin
      (var-set product-counter product-id)
      (print {event: "product-listed", product-id: product-id, brand: tx-sender})
      (ok (map-set Products product-id {
        brand: tx-sender,
        name: name,
        description: description,
        price: price,
        available: true,
        created-at: block-height,
        is-auction: false,
        category-id: category-id
      })))
  )
)

;; New batch listing function
(define-public (batch-list-products
    (names (list 10 (string-ascii 100)))
    (descriptions (list 10 (string-ascii 500)))
    (prices (list 10 uint))
    (category-ids (list 10 uint))
  )
  (let
    ((brand (unwrap! (map-get? Brands tx-sender) (err err-not-brand-owner)))
     (count (len names)))
    
    (asserts! (> count u0) (err err-empty-batch))
    (asserts! (is-eq count (len descriptions)) (err err-invalid-price))
    (asserts! (is-eq count (len prices)) (err err-invalid-price))
    (asserts! (is-eq count (len category-ids)) (err err-invalid-category))
    
    (ok (map list-product names descriptions prices category-ids))
  )
)

;; Category management (owner only)
(define-public (add-category (name (string-ascii 50)))
  (let ((category-id (+ (var-get last-event-id) u1)))
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (var-set last-event-id category-id)
    (ok (map-set Categories category-id {
      name: name,
      active: true
    }))
  )
)

;; [Rest of the original contract remains unchanged]
