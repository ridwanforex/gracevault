;; Constants for error handling
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-VAULT-NOT-FOUND (err u101))
(define-constant ERR-VAULT-LOCKED (err u102))
(define-constant ERR-VAULT-EXPIRED (err u103))
(define-constant ERR-NOT-BENEFICIARY (err u104))
(define-constant ERR-NOT-OWNER (err u105))
(define-constant ERR-PING-TOO-EARLY (err u106))

(define-data-var admin principal tx-sender)
(define-data-var next-vault-id uint u1)

;; Vault structure
(define-map vaults
  {vault-id: uint}
  {
    owner: principal,
    beneficiary: principal,
    amount: uint,            ;; amount locked (in micro STX or sBTC units)
    unlock-time: uint,       ;; block height after which claim allowed
    last-ping: uint,         ;; block height of last ping
    claimed: bool
  }
)

;; ========== ADMIN FUNCTIONS ==========

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-UNAUTHORIZED)
    (asserts! (is-some (some new-admin)) ERR-UNAUTHORIZED)
    (var-set admin new-admin)
    (ok new-admin)))

;; ========== VAULT FUNCTIONS ==========

(define-public (create-vault (beneficiary principal) (amount uint) (unlock-time uint))
  (let
    ((vault-id (var-get next-vault-id)))
    (begin
      ;; Validate inputs
      (asserts! (> unlock-time u0) ERR-VAULT-LOCKED)
      (asserts! (> amount u0) ERR-UNAUTHORIZED)
      (asserts! (is-some (some beneficiary)) ERR-UNAUTHORIZED)

      ;; Store vault
      (map-set vaults
        {vault-id: vault-id}
        {
          owner: tx-sender,
          beneficiary: beneficiary,
          amount: amount,
          unlock-time: unlock-time,
          last-ping: u0,
          claimed: false
        })

      ;; Increment vault ID counter
      (var-set next-vault-id (+ vault-id u1))

      (ok vault-id))))

(define-public (ping (vault-id uint))
  (begin
    (asserts! (> vault-id u0) ERR-VAULT-NOT-FOUND)
    (let ((vault (map-get? vaults {vault-id: vault-id})))
      (match vault
        vault-data
          (begin
            (asserts! (is-eq (get owner vault-data) tx-sender) ERR-NOT-OWNER)
            ;; Require some minimal block difference to prevent spam pings (optional)
            (asserts! (> u0 (+ (get last-ping vault-data) u100)) ERR-PING-TOO-EARLY)
            ;; Update last ping
            (map-set vaults {vault-id: vault-id}
              (merge vault-data { last-ping: u0 }))
            (ok true))
        ERR-VAULT-NOT-FOUND))))

(define-public (claim (vault-id uint))
  (begin
    (asserts! (> vault-id u0) ERR-VAULT-NOT-FOUND)
    (let ((vault (map-get? vaults {vault-id: vault-id})))
      (match vault
        vault-data
          (begin
            (asserts! (is-eq (get beneficiary vault-data) tx-sender) ERR-NOT-BENEFICIARY)
            (asserts! (not (get claimed vault-data)) ERR-VAULT-EXPIRED)
            ;; Must be past unlock time AND last ping + timeout
            (asserts! (>= u0 (get unlock-time vault-data)) ERR-VAULT-LOCKED)
            (asserts! (>= u0 (+ (get last-ping vault-data) u100)) ERR-VAULT-LOCKED)

            ;; Mark claimed true
            (map-set vaults {vault-id: vault-id}
              (merge vault-data { claimed: true }))

            ;; TODO: Transfer locked amount to beneficiary (off-chain or integrate token transfer here)

            (ok true))
        ERR-VAULT-NOT-FOUND))))

(define-public (cancel-vault (vault-id uint))
  (begin
    (asserts! (> vault-id u0) ERR-VAULT-NOT-FOUND)
    (let ((vault (map-get? vaults {vault-id: vault-id})))
      (match vault
        vault-data
          (begin
            (asserts! (is-eq (get owner vault-data) tx-sender) ERR-NOT-OWNER)
            (asserts! (not (get claimed vault-data)) ERR-VAULT-EXPIRED)
            ;; Delete vault, return funds to owner (off-chain)
            (map-delete vaults {vault-id: vault-id})
            (ok true))
        ERR-VAULT-NOT-FOUND))))

;; ========== VIEW FUNCTION ==========

(define-read-only (get-vault (vault-id uint))
  (map-get? vaults {vault-id: vault-id})
)
