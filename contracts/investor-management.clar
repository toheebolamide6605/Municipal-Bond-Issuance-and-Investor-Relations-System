;; Investor Management Contract
;; Handles investor verification, KYC, and portfolio management

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INVESTOR (err u102))
(define-constant ERR-ALREADY-EXISTS (err u106))
(define-constant ERR-INVALID-AMOUNT (err u104))

;; Data Variables
(define-data-var contract-admin principal CONTRACT-OWNER)
(define-data-var total-investors uint u0)

;; Data Maps
(define-map investors principal {
  investor: principal,
  verified: bool,
  kyc-level: uint,
  registration-date: uint,
  total-invested: uint,
  active-bonds: (list 50 uint),
  risk-profile: (string-ascii 20),
  last-activity: uint
})

(define-map investor-subscriptions principal (list 100 uint))
(define-map kyc-documents principal (list 10 (string-ascii 100)))
(define-map investor-communications principal (list 20 {
  message-id: uint,
  timestamp: uint,
  message-type: (string-ascii 20),
  content: (string-ascii 500)
}))

;; Public Functions

;; Register new investor
(define-public (register-investor (investor principal) (kyc-level uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? investors investor)) ERR-ALREADY-EXISTS)
    (asserts! (<= kyc-level u3) ERR-INVALID-AMOUNT)

    (map-set investors investor {
      investor: investor,
      verified: (>= kyc-level u1),
      kyc-level: kyc-level,
      registration-date: current-time,
      total-invested: u0,
      active-bonds: (list),
      risk-profile: "MODERATE",
      last-activity: current-time
    })

    (var-set total-investors (+ (var-get total-investors) u1))
    (ok true)))

;; Update investor verification status
(define-public (update-verification (investor principal) (verified bool) (kyc-level uint))
  (let ((investor-data (unwrap! (map-get? investors investor) ERR-INVALID-INVESTOR)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (<= kyc-level u3) ERR-INVALID-AMOUNT)

    (map-set investors investor (merge investor-data {
      verified: verified,
      kyc-level: kyc-level,
      last-activity: (unwrap-panic (get-block-info? time (- block-height u1)))
    }))
    (ok true)))

;; Update investor investment amount
(define-public (update-investment (investor principal) (bond-id uint) (amount uint))
  (let ((investor-data (unwrap! (map-get? investors investor) ERR-INVALID-INVESTOR)))
    (asserts! (is-authorized-caller) ERR-NOT-AUTHORIZED)

    (map-set investors investor (merge investor-data {
      total-invested: (+ (get total-invested investor-data) amount),
      active-bonds: (unwrap-panic (as-max-len?
        (append (get active-bonds investor-data) bond-id)
        u50)),
      last-activity: (unwrap-panic (get-block-info? time (- block-height u1)))
    }))

    (map-set investor-subscriptions investor
      (unwrap-panic (as-max-len?
        (append (default-to (list) (map-get? investor-subscriptions investor)) bond-id)
        u100)))

    (ok true)))

;; Update risk profile
(define-public (update-risk-profile (investor principal) (risk-profile (string-ascii 20)))
  (let ((investor-data (unwrap! (map-get? investors investor) ERR-INVALID-INVESTOR)))
    (asserts! (or (is-eq tx-sender (var-get contract-admin))
                  (is-eq tx-sender investor)) ERR-NOT-AUTHORIZED)

    (map-set investors investor (merge investor-data {
      risk-profile: risk-profile,
      last-activity: (unwrap-panic (get-block-info? time (- block-height u1)))
    }))
    (ok true)))

;; Add KYC document
(define-public (add-kyc-document (investor principal) (document (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    (map-set kyc-documents investor
      (unwrap-panic (as-max-len?
        (append (default-to (list) (map-get? kyc-documents investor)) document)
        u10)))
    (ok true)))

;; Send communication to investor
(define-public (send-communication
  (investor principal)
  (message-id uint)
  (message-type (string-ascii 20))
  (content (string-ascii 500)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-authorized-caller) ERR-NOT-AUTHORIZED)

    (map-set investor-communications investor
      (unwrap-panic (as-max-len?
        (append (default-to (list) (map-get? investor-communications investor)) {
          message-id: message-id,
          timestamp: current-time,
          message-type: message-type,
          content: content
        })
        u20)))
    (ok true)))

;; Read-only Functions

;; Get investor details
(define-read-only (get-investor (investor principal))
  (map-get? investors investor))

;; Check if investor is verified
(define-read-only (is-verified-investor (investor principal))
  (match (map-get? investors investor)
    investor-data (get verified investor-data)
    false))

;; Get investor KYC level
(define-read-only (get-kyc-level (investor principal))
  (match (map-get? investors investor)
    investor-data (get kyc-level investor-data)
    u0))

;; Get investor subscriptions
(define-read-only (get-investor-subscriptions (investor principal))
  (map-get? investor-subscriptions investor))

;; Get investor communications
(define-read-only (get-investor-communications (investor principal))
  (map-get? investor-communications investor))

;; Get total investors count
(define-read-only (get-total-investors)
  (var-get total-investors))

;; Get KYC documents
(define-read-only (get-kyc-documents (investor principal))
  (map-get? kyc-documents investor))

;; Private Functions

;; Check if caller is authorized
(define-private (is-authorized-caller)
  (or (is-eq tx-sender (var-get contract-admin))
      (is-eq contract-caller .bond-subscription)
      (is-eq contract-caller .payment-distribution)
      (is-eq contract-caller .reporting-compliance)))
