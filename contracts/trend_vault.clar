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
    created-at: uint,
    is-auction: bool
  }
)

(define-map Auctions uint
  {
    end-block: uint,
    min-price: uint,
    highest-bid: uint,
    highest-bidder: (optional principal),
    is-active: bool
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
          created-at: block-height,
          is-auction: false
        })))
      (err err-invalid-price)
    )
  )
)

;; Create auction for a product
(define-public (create-auction
    (name (string-ascii 100))
    (description (string-ascii 500))
    (min-price uint)
    (duration uint)
  )
  (let
    ((brand (unwrap! (map-get? Brands tx-sender) (err err-not-brand-owner)))
     (product-id (+ (var-get product-counter) u1))
     (end-block (+ block-height duration)))
    
    (if (> min-price u0)
      (begin
        (var-set product-counter product-id)
        (try! (map-set Products product-id {
          brand: tx-sender,
          name: name,
          description: description,
          price: min-price,
          available: true,
          created-at: block-height,
          is-auction: true
        }))
        (ok (map-set Auctions product-id {
          end-block: end-block,
          min-price: min-price,
          highest-bid: u0,
          highest-bidder: none,
          is-active: true
        })))
      (err err-invalid-price)
    )
  )
)

;; Place bid on auction
(define-public (place-bid (product-id uint) (bid-amount uint))
  (let
    ((product (unwrap! (map-get? Products product-id) (err err-listing-not-found)))
     (auction (unwrap! (map-get? Auctions product-id) (err err-no-active-auction))))
    
    (asserts! (get is-active auction) (err err-auction-ended))
    (asserts! (<= block-height (get end-block auction)) (err err-auction-ended))
    (asserts! (>= bid-amount (get min-price auction)) (err err-bid-too-low))
    (asserts! (> bid-amount (get highest-bid auction)) (err err-bid-too-low))
    
    (if (>= (stx-get-balance tx-sender) bid-amount)
      (begin
        ;; Return funds to previous bidder if exists
        (match (get highest-bidder auction)
          prev-bidder (try! (stx-transfer? (get highest-bid auction) contract-owner prev-bidder))
          true)
        ;; Accept new bid
        (try! (stx-transfer? bid-amount tx-sender contract-owner))
        (ok (map-set Auctions product-id
          (merge auction {
            highest-bid: bid-amount,
            highest-bidder: (some tx-sender)
          }))))
      (err err-insufficient-funds))
  )
)

;; End auction
(define-public (end-auction (product-id uint))
  (let
    ((product (unwrap! (map-get? Products product-id) (err err-listing-not-found)))
     (auction (unwrap! (map-get? Auctions product-id) (err err-no-active-auction)))
     (brand (get brand product)))
    
    (asserts! (get is-active auction) (err err-auction-ended))
    (asserts! (>= block-height (get end-block auction)) (err err-auction-ended))
    
    (match (get highest-bidder auction)
      winner (begin
        (let ((bid-amount (get highest-bid auction))
              (fee (/ (* bid-amount (var-get platform-fee)) u1000)))
          ;; Transfer funds
          (try! (stx-transfer? fee contract-owner contract-owner))
          (try! (stx-transfer? (- bid-amount fee) contract-owner brand))
          ;; Update product status
          (try! (map-set Products product-id 
            (merge product {available: false})))
          ;; Close auction
          (ok (map-set Auctions product-id
            (merge auction {is-active: false})))))
      (err err-no-active-auction))
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
          (not (get is-auction product))
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

(define-read-only (get-auction (product-id uint))
  (ok (map-get? Auctions product-id))
)
