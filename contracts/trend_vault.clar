;; TrendVault Marketplace Contract

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-brand-owner (err u101))
(define-constant err-invalid-price (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-insufficient-funds (err u104))

;; Data Variables
(define-data-var platform-fee uint u25) ;; 2.5% fee

;; Data Maps
(define-map Brands principal 
  {
    name: (string-ascii 50),
    verified: bool,
    created-at: uint
  }
)

(define-map Products uint 
  {
    brand: principal,
    name: (string-ascii 100),
    description: (string-ascii 500),
    price: uint,
    available: bool,
    created-at: uint
  }
)

(define-map Reviews {product-id: uint, reviewer: principal}
  {
    rating: uint,
    comment: (string-ascii 200),
    timestamp: uint
  }
)

;; Product ID counter
(define-data-var product-counter uint u0)

;; Public Functions

;; Register a new brand
(define-public (register-brand (name (string-ascii 50)))
  (let
    ((brand-data {
      name: name,
      verified: false,
      created-at: block-height
    }))
    (ok (map-set Brands tx-sender brand-data))
  )
)

;; List a new product
(define-public (list-product 
    (name (string-ascii 100))
    (description (string-ascii 500))
    (price uint)
  )
  (let
    ((brand (unwrap! (map-get? Brands tx-sender) (err err-not-brand-owner)))
     (product-id (+ (var-get product-counter) u1)))
    
    (if (> price u0)
      (begin
        (var-set product-counter product-id)
        (ok (map-set Products product-id {
          brand: tx-sender,
          name: name,
          description: description,
          price: price,
          available: true,
          created-at: block-height
        })))
      (err err-invalid-price)
    )
  )
)

;; Purchase a product
(define-public (purchase-product (product-id uint))
  (let
    ((product (unwrap! (map-get? Products product-id) (err err-listing-not-found)))
     (price (get price product))
     (brand (get brand product))
     (fee (/ (* price (var-get platform-fee)) u1000)))
    
    (if (and
          (get available product)
          (>= (stx-get-balance tx-sender) price))
      (begin
        (try! (stx-transfer? fee tx-sender contract-owner))
        (try! (stx-transfer? (- price fee) tx-sender brand))
        (map-set Products product-id 
          (merge product {available: false}))
        (ok true))
      (err err-insufficient-funds))
  )
)

;; Add a review
(define-public (add-review 
    (product-id uint)
    (rating uint)
    (comment (string-ascii 200)))
  (let
    ((product (unwrap! (map-get? Products product-id) 
              (err err-listing-not-found))))
    (ok (map-set Reviews 
      {product-id: product-id, reviewer: tx-sender}
      {
        rating: rating,
        comment: comment,
        timestamp: block-height
      }))
  )
)

;; Verify a brand (owner only)
(define-public (verify-brand (brand principal))
  (if (is-eq tx-sender contract-owner)
    (let
      ((brand-data (unwrap! (map-get? Brands brand) 
                   (err err-not-brand-owner))))
      (ok (map-set Brands brand 
        (merge brand-data {verified: true}))))
    (err err-owner-only))
)

;; Read-only functions

(define-read-only (get-product (product-id uint))
  (ok (map-get? Products product-id))
)

(define-read-only (get-brand (brand principal))
  (ok (map-get? Brands brand))
)

(define-read-only (get-review (product-id uint) (reviewer principal))
  (ok (map-get? Reviews {product-id: product-id, reviewer: reviewer}))
)