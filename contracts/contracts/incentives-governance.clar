;; Incentives and Governance Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Define fungible token for rewards
(define-fungible-token eco-token)

;; Define data variables
(define-data-var next-proposal-id uint u0)

;; Define maps
(define-map proposals uint {creator: principal, title: (string-ascii 50), description: (string-utf8 500), votes-for: uint, votes-against: uint, status: (string-ascii 20)})
(define-map user-votes {user: principal, proposal: uint} bool)

;; Mint eco-tokens (only contract owner)
(define-public (mint-eco-tokens (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ft-mint? eco-token amount recipient)))

;; Transfer eco-tokens
(define-public (transfer-eco-tokens (amount uint) (sender principal) (recipient principal))
    (ft-transfer? eco-token amount sender recipient))

;; Create proposal
(define-public (create-proposal (title (string-ascii 50)) (description (string-utf8 500)))
    (let ((id (var-get next-proposal-id)))
        (map-set proposals id 
            {creator: tx-sender, 
             title: title, 
             description: description, 
             votes-for: u0, 
             votes-against: u0, 
             status: "active"})
        (var-set next-proposal-id (+ id u1))
        (ok id)))

;; Vote on proposal
(define-public (vote-on-proposal (proposal-id-input uint) (vote bool))
    (let ((proposal (unwrap! (map-get? proposals proposal-id-input) err-not-found)))
        (asserts! (is-eq (get status proposal) "active") err-unauthorized)
        (asserts! (not (default-to false (map-get? user-votes {user: tx-sender, proposal: proposal-id-input}))) err-unauthorized)
        (map-set user-votes {user: tx-sender, proposal: proposal-id-input} true)
        (if vote
            (map-set proposals proposal-id-input (merge proposal {votes-for: (+ (get votes-for proposal) u1)}))
            (map-set proposals proposal-id-input (merge proposal {votes-against: (+ (get votes-against proposal) u1)})))
        (ok true)))

;; Close proposal (only contract owner)
(define-public (close-proposal (proposal-id-input uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (match (map-get? proposals proposal-id-input)
            proposal (ok (map-set proposals proposal-id-input (merge proposal {status: "closed"})))
            err-not-found)))

;; Get proposal details
(define-read-only (get-proposal-details (proposal-id-input uint))
    (map-get? proposals proposal-id-input))

;; Get user's eco-token balance
(define-read-only (get-balance (user principal))
    (ft-get-balance eco-token user))

