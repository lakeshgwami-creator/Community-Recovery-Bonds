(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-BOND-NOT-FOUND (err u101))
(define-constant ERR-BOND-EXPIRED (err u102))
(define-constant ERR-BOND-ALREADY-CLAIMED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-BOND-NOT-ACTIVE (err u105))
(define-constant ERR-ALREADY-BACKED (err u106))
(define-constant ERR-INVALID-AMOUNT (err u107))
(define-constant ERR-CANNOT-BACK-OWN-BOND (err u108))
(define-constant ERR-BOND-FULLY-FUNDED (err u109))
(define-constant ERR-NO-BACKING-FOUND (err u110))

(define-constant CONTRACT-OWNER tx-sender)
(define-constant BOND-DURATION u1000)
(define-constant MIN-BOND-AMOUNT u100)
(define-constant MAX-BOND-AMOUNT u100000)
(define-constant PLATFORM-FEE-RATE u25)

(define-data-var bond-counter uint u0)
(define-data-var total-bonds-created uint u0)
(define-data-var total-amount-bonded uint u0)
(define-data-var platform-treasury uint u0)

(define-map bonds
  uint
  {
    creator: principal,
    beneficiary: principal,
    target-amount: uint,
    current-amount: uint,
    expiry-block: uint,
    description: (string-ascii 256),
    is-active: bool,
    is-claimed: bool,
    created-at: uint
  }
)

(define-map bond-backers
  {bond-id: uint, backer: principal}
  {amount: uint, backed-at: uint}
)

(define-map user-bonds
  principal
  {
    created: (list 50 uint),
    backed: (list 100 uint)
  }
)

(define-map bond-backing-list
  uint
  (list 100 principal)
)

(define-read-only (get-bond (bond-id uint))
  (map-get? bonds bond-id)
)

(define-read-only (get-bond-backing (bond-id uint) (backer principal))
  (map-get? bond-backers {bond-id: bond-id, backer: backer})
)

(define-read-only (get-user-bonds (user principal))
  (default-to {created: (list), backed: (list)} (map-get? user-bonds user))
)

(define-read-only (get-bond-backers (bond-id uint))
  (default-to (list) (map-get? bond-backing-list bond-id))
)

(define-read-only (get-platform-stats)
  {
    total-bonds: (var-get total-bonds-created),
    total-bonded: (var-get total-amount-bonded),
    treasury: (var-get platform-treasury)
  }
)

(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount PLATFORM-FEE-RATE) u1000)
)

(define-read-only (is-bond-expired (bond-id uint))
  (match (get-bond bond-id)
    bond-data (> stacks-block-height (get expiry-block bond-data))
    true
  )
)

(define-read-only (get-bond-progress (bond-id uint))
  (match (get-bond bond-id)
    bond-data 
    (ok {
      target: (get target-amount bond-data),
      current: (get current-amount bond-data),
      percentage: (if (> (get target-amount bond-data) u0)
                   (/ (* (get current-amount bond-data) u100) (get target-amount bond-data))
                   u0)
    })
    ERR-BOND-NOT-FOUND
  )
)

(define-private (add-to-user-created-bonds (user principal) (bond-id uint))
  (let (
    (current-data (get-user-bonds user))
    (current-created (get created current-data))
  )
    (map-set user-bonds user
      (merge current-data {created: (unwrap-panic (as-max-len? (append current-created bond-id) u50))})
    )
  )
)

(define-private (add-to-user-backed-bonds (user principal) (bond-id uint))
  (let (
    (current-data (get-user-bonds user))
    (current-backed (get backed current-data))
  )
    (map-set user-bonds user
      (merge current-data {backed: (unwrap-panic (as-max-len? (append current-backed bond-id) u100))})
    )
  )
)

(define-private (add-backer-to-bond (bond-id uint) (backer principal))
  (let (
    (current-backers (get-bond-backers bond-id))
  )
    (map-set bond-backing-list bond-id
      (unwrap-panic (as-max-len? (append current-backers backer) u100))
    )
  )
)

(define-public (create-recovery-bond 
  (beneficiary principal) 
  (target-amount uint) 
  (description (string-ascii 256)))
  (let (
    (bond-id (+ (var-get bond-counter) u1))
    (current-block stacks-block-height)
  )
    (asserts! (and (>= target-amount MIN-BOND-AMOUNT) (<= target-amount MAX-BOND-AMOUNT)) ERR-INVALID-AMOUNT)
    (map-set bonds bond-id
      {
        creator: tx-sender,
        beneficiary: beneficiary,
        target-amount: target-amount,
        current-amount: u0,
        expiry-block: (+ current-block BOND-DURATION),
        description: description,
        is-active: true,
        is-claimed: false,
        created-at: current-block
      }
    )
    (var-set bond-counter bond-id)
    (var-set total-bonds-created (+ (var-get total-bonds-created) u1))
    (add-to-user-created-bonds tx-sender bond-id)
    (ok bond-id)
  )
)

(define-public (back-recovery-bond (bond-id uint) (amount uint))
  (let (
    (bond-data (unwrap! (get-bond bond-id) ERR-BOND-NOT-FOUND))
    (current-backing (map-get? bond-backers {bond-id: bond-id, backer: tx-sender}))
  )
    (asserts! (get is-active bond-data) ERR-BOND-NOT-ACTIVE)
    (asserts! (not (is-bond-expired bond-id)) ERR-BOND-EXPIRED)
    (asserts! (not (is-eq tx-sender (get creator bond-data))) ERR-CANNOT-BACK-OWN-BOND)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none current-backing) ERR-ALREADY-BACKED)
    (asserts! (<= (+ (get current-amount bond-data) amount) (get target-amount bond-data)) ERR-BOND-FULLY-FUNDED)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set bond-backers {bond-id: bond-id, backer: tx-sender}
      {amount: amount, backed-at: stacks-block-height}
    )
    
    (map-set bonds bond-id
      (merge bond-data {current-amount: (+ (get current-amount bond-data) amount)})
    )
    
    (add-backer-to-bond bond-id tx-sender)
    (add-to-user-backed-bonds tx-sender bond-id)
    (var-set total-amount-bonded (+ (var-get total-amount-bonded) amount))
    
    (ok true)
  )
)

(define-public (claim-bond (bond-id uint))
  (let (
    (bond-data (unwrap! (get-bond bond-id) ERR-BOND-NOT-FOUND))
    (platform-fee (calculate-platform-fee (get current-amount bond-data)))
    (claimable-amount (- (get current-amount bond-data) platform-fee))
  )
    (asserts! (is-eq tx-sender (get beneficiary bond-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active bond-data) ERR-BOND-NOT-ACTIVE)
    (asserts! (not (get is-claimed bond-data)) ERR-BOND-ALREADY-CLAIMED)
    (asserts! (> (get current-amount bond-data) u0) ERR-INSUFFICIENT-FUNDS)
    
    (try! (as-contract (stx-transfer? claimable-amount tx-sender (get beneficiary bond-data))))
    
    (map-set bonds bond-id
      (merge bond-data {is-claimed: true, is-active: false})
    )
    
    (var-set platform-treasury (+ (var-get platform-treasury) platform-fee))
    
    (ok claimable-amount)
  )
)

(define-public (withdraw-backing (bond-id uint))
  (let (
    (bond-data (unwrap! (get-bond bond-id) ERR-BOND-NOT-FOUND))
    (backing-data (unwrap! (get-bond-backing bond-id tx-sender) ERR-NO-BACKING-FOUND))
    (backing-amount (get amount backing-data))
  )
    (asserts! (is-bond-expired bond-id) ERR-BOND-NOT-ACTIVE)
    (asserts! (not (get is-claimed bond-data)) ERR-BOND-ALREADY-CLAIMED)
    
    (try! (as-contract (stx-transfer? backing-amount tx-sender tx-sender)))
    
    (map-delete bond-backers {bond-id: bond-id, backer: tx-sender})
    
    (map-set bonds bond-id
      (merge bond-data {current-amount: (- (get current-amount bond-data) backing-amount)})
    )
    
    (ok backing-amount)
  )
)

(define-public (deactivate-bond (bond-id uint))
  (let (
    (bond-data (unwrap! (get-bond bond-id) ERR-BOND-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get creator bond-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active bond-data) ERR-BOND-NOT-ACTIVE)
    (asserts! (not (get is-claimed bond-data)) ERR-BOND-ALREADY-CLAIMED)
    
    (map-set bonds bond-id
      (merge bond-data {is-active: false})
    )
    
    (ok true)
  )
)

(define-public (emergency-withdraw (bond-id uint))
  (let (
    (bond-data (unwrap! (get-bond bond-id) ERR-BOND-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (get current-amount bond-data) u0) ERR-INSUFFICIENT-FUNDS)
    
    (try! (as-contract (stx-transfer? (get current-amount bond-data) tx-sender CONTRACT-OWNER)))
    
    (map-set bonds bond-id
      (merge bond-data {current-amount: u0, is-active: false})
    )
    
    (ok true)
  )
)

(define-read-only (get-active-bonds)
  (filter is-active-bond (list 
    u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 
    u11 u12 u13 u14 u15 u16 u17 u18 u19 u20
    u21 u22 u23 u24 u25 u26 u27 u28 u29 u30
    u31 u32 u33 u34 u35 u36 u37 u38 u39 u40
    u41 u42 u43 u44 u45 u46 u47 u48 u49 u50
  ))
)

(define-private (is-active-bond (bond-id uint))
  (match (get-bond bond-id)
    bond-data (and (get is-active bond-data) (not (is-bond-expired bond-id)))
    false
  )
)
