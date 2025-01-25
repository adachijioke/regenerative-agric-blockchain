;; Farm Verification and Tracking Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))

;; Define data variables
(define-data-var next-farm-id uint u0)

;; Define maps
(define-map farms uint {owner: principal, name: (string-ascii 50), location: (string-ascii 100), verified: bool})
(define-map farm-metrics uint {carbon-sequestration: uint, biodiversity-index: uint, water-conservation: uint})
(define-map reputation-scores principal uint)

;; Farm registration
(define-public (register-farm (name (string-ascii 50)) (location (string-ascii 100)))
    (let ((farm-id (var-get next-farm-id)))
        (map-set farms farm-id {owner: tx-sender, name: name, location: location, verified: false})
        (map-set farm-metrics farm-id {carbon-sequestration: u0, biodiversity-index: u0, water-conservation: u0})
        (var-set next-farm-id (+ farm-id u1))
        (ok farm-id)))

;; Update farm metrics
(define-public (update-farm-metrics (farm-id uint) (carbon uint) (biodiversity uint) (water uint))
    (let ((farm (unwrap! (map-get? farms farm-id) err-not-found)))
        (asserts! (is-eq (get owner farm) tx-sender) err-owner-only)
        (ok (map-set farm-metrics farm-id 
            {carbon-sequestration: carbon, biodiversity-index: biodiversity, water-conservation: water}))))

;; Verify farm (only contract owner can verify)
(define-public (verify-farm (farm-id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (match (map-get? farms farm-id)
            farm (ok (map-set farms farm-id (merge farm {verified: true})))
            err-not-found)))

;; Get farm details
(define-read-only (get-farm-details (farm-id uint))
    (map-get? farms farm-id))

;; Get farm metrics
(define-read-only (get-farm-metrics (farm-id uint))
    (map-get? farm-metrics farm-id))

;; Update reputation score
(define-public (update-reputation-score (farmer principal) (score uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set reputation-scores farmer score))))

;; Get reputation score
(define-read-only (get-reputation-score (farmer principal))
    (default-to u0 (map-get? reputation-scores farmer)))

