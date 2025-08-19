;; DecenStay: Decentralized Accommodation Marketplace Smart Contract
;; A comprehensive peer-to-peer accommodation booking platform that enables
;; secure property listings, automated booking management, escrow payments,
;; reputation systems, and dispute resolution without intermediaries

;; CONSTANTS & CONFIGURATION

(define-constant contract-owner tx-sender)
(define-constant platform-fee-percentage u5) ;; 5% platform commission
(define-constant booking-cancellation-deadline u86400) ;; 24 hours in seconds
(define-constant dispute-resolution-deadline u604800) ;; 7 days in seconds
(define-constant minimum-host-stake u1000000) ;; 1 STX minimum stake requirement
(define-constant maximum-booking-duration u7) ;; Maximum 7 days per booking
(define-constant maximum-property-guests u20) ;; Reasonable guest limit
(define-constant neutral-reputation-score u100) ;; Starting reputation score
(define-constant seconds-per-day u86400)

;; ERROR CODES

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-PROPERTY-NOT-FOUND (err u101))
(define-constant ERR-BOOKING-NOT-FOUND (err u102))
(define-constant ERR-INVALID-DATE-RANGE (err u103))
(define-constant ERR-PROPERTY-UNAVAILABLE (err u104))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u105))
(define-constant ERR-BOOKING-ALREADY-EXISTS (err u106))
(define-constant ERR-CANCELLATION-DEADLINE-EXPIRED (err u107))
(define-constant ERR-REVIEW-ALREADY-SUBMITTED (err u108))
(define-constant ERR-INVALID-RATING-VALUE (err u109))
(define-constant ERR-DISPUTE-DEADLINE-EXPIRED (err u110))
(define-constant ERR-INSUFFICIENT-HOST-STAKE (err u111))
(define-constant ERR-PROPERTY-ALREADY-REGISTERED (err u112))
(define-constant ERR-INVALID-INPUT-DATA (err u113))
(define-constant ERR-INVALID-AMOUNT-VALUE (err u114))

;; STATE VARIABLES

(define-data-var property-counter uint u1)
(define-data-var booking-counter uint u1)
(define-data-var accumulated-platform-fees uint u0)

;; DATA STRUCTURES

;; Property listings with comprehensive details
(define-map accommodation-properties 
  { property-identifier: uint }
  {
    property-owner: principal,
    listing-title: (string-ascii 100),
    property-description: (string-ascii 500),
    property-location: (string-ascii 100),
    nightly-rate: uint,
    guest-capacity: uint,
    available-amenities: (list 10 (string-ascii 50)),
    listing-active-status: bool,
    completed-booking-count: uint,
    cumulative-rating-points: uint,
    total-review-count: uint,
    property-creation-time: uint
  }
)

;; Booking transactions and details
(define-map accommodation-bookings
  { booking-identifier: uint }
  {
    booked-property-id: uint,
    booking-guest: principal,
    property-host: principal,
    arrival-date: uint,
    departure-date: uint,
    guest-count: uint,
    booking-total-amount: uint,
    platform-commission: uint,
    booking-status: (string-ascii 20), ;; "pending", "confirmed", "cancelled", "completed", "disputed"
    booking-creation-time: uint,
    host-confirmation-time: (optional uint),
    booking-cancellation-time: (optional uint)
  }
)

;; Date-based availability tracking
(define-map property-date-availability
  { property-identifier: uint, availability-date: uint }
  { date-available: bool }
)

;; Host stake requirements and tracking
(define-map host-stake-registry
  { host-address: principal }
  { staked-amount: uint, stake-timestamp: uint }
)

;; Review and rating system
(define-map booking-reviews
  { booking-identifier: uint }
  {
    review-author: principal,
    star-rating: uint,
    review-text: (string-ascii 500),
    review-submission-time: uint
  }
)

;; Dispute management system
(define-map booking-disputes
  { booking-identifier: uint }
  {
    dispute-initiator: principal,
    dispute-reason: (string-ascii 500),
    dispute-status: (string-ascii 20), ;; "pending", "resolved", "escalated"
    dispute-creation-time: uint,
    dispute-resolution-time: (optional uint)
  }
)

;; User profile management
(define-map platform-user-profiles
  { user-address: principal }
  {
    display-username: (string-ascii 50),
    contact-email: (string-ascii 100),
    completed-transaction-count: uint,
    total-earnings-amount: uint,
    user-reputation-score: uint,
    verification-status: bool,
    profile-creation-time: uint
  }
)

;; UTILITY & VALIDATION FUNCTIONS

(define-private (is-authorized-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (calculate-platform-commission (transaction-amount uint))
  (/ (* transaction-amount platform-fee-percentage) u100)
)

(define-private (check-date-availability (property-id uint) (target-date uint))
  (default-to true 
    (get date-available 
      (map-get? property-date-availability 
        { property-identifier: property-id, availability-date: target-date }
      )
    )
  )
)

(define-private (calculate-stay-duration (checkin-date uint) (checkout-date uint))
  (if (> checkout-date checkin-date)
    (/ (- checkout-date checkin-date) seconds-per-day)
    u0
  )
)

(define-private (update-date-availability-status (property-id uint) (target-date uint) (available-status bool))
  (map-set property-date-availability 
    { property-identifier: property-id, availability-date: target-date }
    { date-available: available-status }
  )
)

(define-private (verify-booking-date-availability (property-id uint) (start-date uint) (end-date uint))
  (let ((booking-duration (calculate-stay-duration start-date end-date)))
    (if (<= booking-duration maximum-booking-duration)
      (and 
        (check-date-availability property-id start-date)
        (if (> booking-duration u1) (check-date-availability property-id (+ start-date seconds-per-day)) true)
        (if (> booking-duration u2) (check-date-availability property-id (+ start-date (* u2 seconds-per-day))) true)
        (if (> booking-duration u3) (check-date-availability property-id (+ start-date (* u3 seconds-per-day))) true)
        (if (> booking-duration u4) (check-date-availability property-id (+ start-date (* u4 seconds-per-day))) true)
        (if (> booking-duration u5) (check-date-availability property-id (+ start-date (* u5 seconds-per-day))) true)
        (if (> booking-duration u6) (check-date-availability property-id (+ start-date (* u6 seconds-per-day))) true)
      )
      false
    )
  )
)

;; INPUT VALIDATION FUNCTIONS

(define-private (validate-string-content (input-text (string-ascii 500)))
  (> (len input-text) u0)
)

(define-private (validate-short-string-content (input-text (string-ascii 100)))
  (> (len input-text) u0)
)

(define-private (validate-username-format (username (string-ascii 50)))
  (and (> (len username) u2) (<= (len username) u50))
)

(define-private (validate-email-format (email-address (string-ascii 100)))
  (and (> (len email-address) u5) (<= (len email-address) u100))
)

(define-private (validate-positive-integer (numeric-value uint))
  (> numeric-value u0)
)

(define-private (validate-property-identifier (property-id uint))
  (and (> property-id u0) (< property-id (var-get property-counter)))
)

(define-private (validate-booking-identifier (booking-id uint))
  (and (> booking-id u0) (< booking-id (var-get booking-counter)))
)

(define-private (validate-amenity-description (amenity-text (string-ascii 50)))
  (and (> (len amenity-text) u0) (<= (len amenity-text) u50))
)

(define-private (validate-amenity-list (amenity-collection (list 10 (string-ascii 50))))
  (let ((validated-amenities (filter validate-amenity-description amenity-collection)))
    (is-eq (len validated-amenities) (len amenity-collection))
  )
)

;; HOST MANAGEMENT FUNCTIONS

(define-public (deposit-host-stake (stake-amount uint))
  (let ((existing-stake (default-to u0 
          (get staked-amount (map-get? host-stake-registry { host-address: tx-sender })))))
    (asserts! (validate-positive-integer stake-amount) ERR-INVALID-INPUT-DATA)
    (asserts! (>= stake-amount minimum-host-stake) ERR-INSUFFICIENT-HOST-STAKE)
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    (map-set host-stake-registry
      { host-address: tx-sender }
      { staked-amount: (+ existing-stake stake-amount), stake-timestamp: block-height }
    )
    (ok stake-amount)
  )
)

(define-public (register-accommodation-property 
  (listing-title (string-ascii 100))
  (property-description (string-ascii 500))
  (property-location (string-ascii 100))
  (nightly-rate uint)
  (guest-capacity uint)
  (available-amenities (list 10 (string-ascii 50)))
)
  (let ((new-property-id (var-get property-counter))
        (host-current-stake (get staked-amount 
          (map-get? host-stake-registry { host-address: tx-sender }))))
    ;; Comprehensive input validation
    (asserts! (validate-short-string-content listing-title) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-string-content property-description) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-short-string-content property-location) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-positive-integer nightly-rate) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-positive-integer guest-capacity) ERR-INVALID-INPUT-DATA)
    (asserts! (<= guest-capacity maximum-property-guests) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-amenity-list available-amenities) ERR-INVALID-INPUT-DATA)
    
    (asserts! (>= (default-to u0 host-current-stake) minimum-host-stake) ERR-INSUFFICIENT-HOST-STAKE)
    (asserts! (is-none (map-get? accommodation-properties { property-identifier: new-property-id })) 
              ERR-PROPERTY-ALREADY-REGISTERED)
    
    (map-set accommodation-properties
      { property-identifier: new-property-id }
      {
        property-owner: tx-sender,
        listing-title: listing-title,
        property-description: property-description,
        property-location: property-location,
        nightly-rate: nightly-rate,
        guest-capacity: guest-capacity,
        available-amenities: available-amenities,
        listing-active-status: true,
        completed-booking-count: u0,
        cumulative-rating-points: u0,
        total-review-count: u0,
        property-creation-time: block-height
      }
    )
    
    (var-set property-counter (+ new-property-id u1))
    (ok new-property-id)
  )
)

(define-public (modify-property-availability-status (property-id uint) (active-status bool))
  (let ((target-property (unwrap! (map-get? accommodation-properties { property-identifier: property-id }) 
                                  ERR-PROPERTY-NOT-FOUND)))
    (asserts! (validate-property-identifier property-id) ERR-INVALID-INPUT-DATA)
    (asserts! (is-eq (get property-owner target-property) tx-sender) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set accommodation-properties
      { property-identifier: property-id }
      (merge target-property { listing-active-status: active-status })
    )
    (ok true)
  )
)

;; GUEST BOOKING FUNCTIONS

(define-public (create-accommodation-booking
  (property-id uint)
  (arrival-date uint)
  (departure-date uint)
  (guest-count uint)
)
  (let (
    (target-property (unwrap! (map-get? accommodation-properties { property-identifier: property-id }) 
                              ERR-PROPERTY-NOT-FOUND))
    (new-booking-id (var-get booking-counter))
    (stay-duration (calculate-stay-duration arrival-date departure-date))
    (total-booking-cost (* (get nightly-rate target-property) stay-duration))
    (platform-commission (calculate-platform-commission total-booking-cost))
    (host-earnings (- total-booking-cost platform-commission))
  )
    ;; Comprehensive input validation
    (asserts! (validate-property-identifier property-id) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-positive-integer arrival-date) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-positive-integer departure-date) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-positive-integer guest-count) ERR-INVALID-INPUT-DATA)
    
    (asserts! (get listing-active-status target-property) ERR-PROPERTY-UNAVAILABLE)
    (asserts! (> departure-date arrival-date) ERR-INVALID-DATE-RANGE)
    (asserts! (<= guest-count (get guest-capacity target-property)) ERR-INVALID-DATE-RANGE)
    (asserts! (<= stay-duration maximum-booking-duration) ERR-INVALID-DATE-RANGE)
    
    ;; Verify complete date range availability
    (asserts! (verify-booking-date-availability property-id arrival-date departure-date) 
              ERR-PROPERTY-UNAVAILABLE)
    
    ;; Process payment transfer
    (try! (stx-transfer? total-booking-cost tx-sender (as-contract tx-sender)))
    
    ;; Create comprehensive booking record
    (map-set accommodation-bookings
      { booking-identifier: new-booking-id }
      {
        booked-property-id: property-id,
        booking-guest: tx-sender,
        property-host: (get property-owner target-property),
        arrival-date: arrival-date,
        departure-date: departure-date,
        guest-count: guest-count,
        booking-total-amount: total-booking-cost,
        platform-commission: platform-commission,
        booking-status: "pending",
        booking-creation-time: block-height,
        host-confirmation-time: none,
        booking-cancellation-time: none
      }
    )
    
    ;; Block availability for booked dates
    (let ((booking-days (calculate-stay-duration arrival-date departure-date)))
      (update-date-availability-status property-id arrival-date false)
      (if (> booking-days u1) (update-date-availability-status property-id (+ arrival-date seconds-per-day) false) true)
      (if (> booking-days u2) (update-date-availability-status property-id (+ arrival-date (* u2 seconds-per-day)) false) true)
      (if (> booking-days u3) (update-date-availability-status property-id (+ arrival-date (* u3 seconds-per-day)) false) true)
      (if (> booking-days u4) (update-date-availability-status property-id (+ arrival-date (* u4 seconds-per-day)) false) true)
      (if (> booking-days u5) (update-date-availability-status property-id (+ arrival-date (* u5 seconds-per-day)) false) true)
      (if (> booking-days u6) (update-date-availability-status property-id (+ arrival-date (* u6 seconds-per-day)) false) true)
    )
    
    (var-set booking-counter (+ new-booking-id u1))
    (ok new-booking-id)
  )
)

(define-public (cancel-accommodation-booking (booking-id uint))
  (let ((target-booking (unwrap! (map-get? accommodation-bookings { booking-identifier: booking-id }) 
                                 ERR-BOOKING-NOT-FOUND)))
    (asserts! (validate-booking-identifier booking-id) ERR-INVALID-INPUT-DATA)
    (asserts! (is-eq (get booking-guest target-booking) tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get booking-status target-booking) "pending") ERR-UNAUTHORIZED-ACCESS)
    (asserts! (< block-height (+ (get booking-creation-time target-booking) booking-cancellation-deadline)) 
              ERR-CANCELLATION-DEADLINE-EXPIRED)
    
    ;; Process refund to guest
    (try! (as-contract (stx-transfer? (get booking-total-amount target-booking) tx-sender 
                                      (get booking-guest target-booking))))
    
    ;; Restore date availability
    (let ((booking-days (calculate-stay-duration (get arrival-date target-booking) (get departure-date target-booking))))
      (update-date-availability-status (get booked-property-id target-booking) (get arrival-date target-booking) true)
      (if (> booking-days u1) (update-date-availability-status (get booked-property-id target-booking) (+ (get arrival-date target-booking) seconds-per-day) true) true)
      (if (> booking-days u2) (update-date-availability-status (get booked-property-id target-booking) (+ (get arrival-date target-booking) (* u2 seconds-per-day)) true) true)
      (if (> booking-days u3) (update-date-availability-status (get booked-property-id target-booking) (+ (get arrival-date target-booking) (* u3 seconds-per-day)) true) true)
      (if (> booking-days u4) (update-date-availability-status (get booked-property-id target-booking) (+ (get arrival-date target-booking) (* u4 seconds-per-day)) true) true)
      (if (> booking-days u5) (update-date-availability-status (get booked-property-id target-booking) (+ (get arrival-date target-booking) (* u5 seconds-per-day)) true) true)
      (if (> booking-days u6) (update-date-availability-status (get booked-property-id target-booking) (+ (get arrival-date target-booking) (* u6 seconds-per-day)) true) true)
    )
    
    ;; Update booking record with cancellation
    (map-set accommodation-bookings
      { booking-identifier: booking-id }
      (merge target-booking { 
        booking-status: "cancelled",
        booking-cancellation-time: (some block-height)
      })
    )
    
    (ok true)
  )
)

;; HOST CONFIRMATION SYSTEM

(define-public (confirm-guest-booking (booking-id uint))
  (let ((target-booking (unwrap! (map-get? accommodation-bookings { booking-identifier: booking-id }) 
                                 ERR-BOOKING-NOT-FOUND)))
    (asserts! (validate-booking-identifier booking-id) ERR-INVALID-INPUT-DATA)
    (asserts! (is-eq (get property-host target-booking) tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get booking-status target-booking) "pending") ERR-UNAUTHORIZED-ACCESS)
    
    ;; Transfer earnings to host and collect platform fees
    (let ((host-payment (- (get booking-total-amount target-booking) (get platform-commission target-booking))))
      (try! (as-contract (stx-transfer? host-payment tx-sender (get property-host target-booking))))
      (var-set accumulated-platform-fees (+ (var-get accumulated-platform-fees) (get platform-commission target-booking)))
    )
    
    ;; Update booking status with confirmation
    (map-set accommodation-bookings
      { booking-identifier: booking-id }
      (merge target-booking { 
        booking-status: "confirmed",
        host-confirmation-time: (some block-height)
      })
    )
    
    ;; Update property statistics
    (let ((property-data (unwrap! (map-get? accommodation-properties { property-identifier: (get booked-property-id target-booking) }) 
                                  ERR-PROPERTY-NOT-FOUND)))
      (map-set accommodation-properties
        { property-identifier: (get booked-property-id target-booking) }
        (merge property-data { 
          completed-booking-count: (+ (get completed-booking-count property-data) u1)
        })
      )
    )
    
    (ok true)
  )
)

;; REVIEW & RATING SYSTEM

(define-public (submit-booking-review (booking-id uint) (star-rating uint) (review-text (string-ascii 500)))
  (let ((target-booking (unwrap! (map-get? accommodation-bookings { booking-identifier: booking-id }) 
                                 ERR-BOOKING-NOT-FOUND)))
    ;; Comprehensive input validation
    (asserts! (validate-booking-identifier booking-id) ERR-INVALID-INPUT-DATA)
    (asserts! (and (>= star-rating u1) (<= star-rating u5)) ERR-INVALID-RATING-VALUE)
    (asserts! (validate-string-content review-text) ERR-INVALID-INPUT-DATA)
    
    (asserts! (or (is-eq (get booking-guest target-booking) tx-sender) 
                  (is-eq (get property-host target-booking) tx-sender)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get booking-status target-booking) "completed") ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-none (map-get? booking-reviews { booking-identifier: booking-id })) 
              ERR-REVIEW-ALREADY-SUBMITTED)
    
    (map-set booking-reviews
      { booking-identifier: booking-id }
      {
        review-author: tx-sender,
        star-rating: star-rating,
        review-text: review-text,
        review-submission-time: block-height
      }
    )
    
    ;; Update property rating calculations
    (let ((property-data (unwrap! (map-get? accommodation-properties 
                                          { property-identifier: (get booked-property-id target-booking) }) 
                                  ERR-PROPERTY-NOT-FOUND)))
      (map-set accommodation-properties
        { property-identifier: (get booked-property-id target-booking) }
        (merge property-data {
          cumulative-rating-points: (+ (get cumulative-rating-points property-data) star-rating),
          total-review-count: (+ (get total-review-count property-data) u1)
        })
      )
    )
    
    (ok true)
  )
)

;; DISPUTE RESOLUTION SYSTEM

(define-public (initiate-booking-dispute (booking-id uint) (dispute-reason (string-ascii 500)))
  (let ((target-booking (unwrap! (map-get? accommodation-bookings { booking-identifier: booking-id }) 
                                 ERR-BOOKING-NOT-FOUND)))
    ;; Input validation
    (asserts! (validate-booking-identifier booking-id) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-string-content dispute-reason) ERR-INVALID-INPUT-DATA)
    
    (asserts! (or (is-eq (get booking-guest target-booking) tx-sender) 
                  (is-eq (get property-host target-booking) tx-sender)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (< block-height (+ (get departure-date target-booking) dispute-resolution-deadline)) 
              ERR-DISPUTE-DEADLINE-EXPIRED)
    
    (map-set booking-disputes
      { booking-identifier: booking-id }
      {
        dispute-initiator: tx-sender,
        dispute-reason: dispute-reason,
        dispute-status: "pending",
        dispute-creation-time: block-height,
        dispute-resolution-time: none
      }
    )
    
    ;; Update booking status to reflect dispute
    (map-set accommodation-bookings
      { booking-identifier: booking-id }
      (merge target-booking { booking-status: "disputed" })
    )
    
    (ok true)
  )
)

;; USER PROFILE MANAGEMENT

(define-public (create-user-profile (display-username (string-ascii 50)) (contact-email (string-ascii 100)))
  (begin
    ;; Input validation
    (asserts! (validate-username-format display-username) ERR-INVALID-INPUT-DATA)
    (asserts! (validate-email-format contact-email) ERR-INVALID-INPUT-DATA)
    
    (map-set platform-user-profiles
      { user-address: tx-sender }
      {
        display-username: display-username,
        contact-email: contact-email,
        completed-transaction-count: u0,
        total-earnings-amount: u0,
        user-reputation-score: neutral-reputation-score,
        verification-status: false,
        profile-creation-time: block-height
      }
    )
    (ok true)
  )
)

;; ADMINISTRATIVE FUNCTIONS

(define-public (resolve-booking-dispute (booking-id uint) (resolution-status (string-ascii 20)))
  (begin
    (asserts! (is-authorized-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-booking-identifier booking-id) ERR-INVALID-INPUT-DATA)
    (asserts! (> (len resolution-status) u0) ERR-INVALID-INPUT-DATA)
    
    (let ((target-dispute (unwrap! (map-get? booking-disputes { booking-identifier: booking-id }) 
                                   ERR-BOOKING-NOT-FOUND)))
      (map-set booking-disputes
        { booking-identifier: booking-id }
        (merge target-dispute {
          dispute-status: resolution-status,
          dispute-resolution-time: (some block-height)
        })
      )
      (ok true)
    )
  )
)

(define-public (withdraw-accumulated-platform-fees (withdrawal-amount uint))
  (begin
    (asserts! (is-authorized-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-positive-integer withdrawal-amount) ERR-INVALID-AMOUNT-VALUE)
    (asserts! (<= withdrawal-amount (var-get accumulated-platform-fees)) ERR-INSUFFICIENT-PAYMENT)
    
    (try! (as-contract (stx-transfer? withdrawal-amount tx-sender contract-owner)))
    (var-set accumulated-platform-fees (- (var-get accumulated-platform-fees) withdrawal-amount))
    (ok withdrawal-amount)
  )
)

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-property-details (property-id uint))
  (map-get? accommodation-properties { property-identifier: property-id })
)

(define-read-only (get-booking-details (booking-id uint))
  (map-get? accommodation-bookings { booking-identifier: booking-id })
)

(define-read-only (check-property-date-availability (property-id uint) (target-date uint))
  (check-date-availability property-id target-date)
)

(define-read-only (get-host-stake-info (host-address principal))
  (map-get? host-stake-registry { host-address: host-address })
)

(define-read-only (get-booking-review (booking-id uint))
  (map-get? booking-reviews { booking-identifier: booking-id })
)

(define-read-only (get-booking-dispute (booking-id uint))
  (map-get? booking-disputes { booking-identifier: booking-id })
)

(define-read-only (get-user-profile-info (user-address principal))
  (map-get? platform-user-profiles { user-address: user-address })
)

(define-read-only (get-total-platform-fees)
  (var-get accumulated-platform-fees)
)

(define-read-only (calculate-property-average-rating (property-id uint))
  (let ((property-data (map-get? accommodation-properties { property-identifier: property-id })))
    (match property-data
      property-info (if (> (get total-review-count property-info) u0)
                      (some (/ (get cumulative-rating-points property-info) (get total-review-count property-info)))
                      none)
      none
    )
  )
)

(define-read-only (estimate-booking-costs (property-id uint) (arrival-date uint) (departure-date uint))
  (let ((property-data (map-get? accommodation-properties { property-identifier: property-id })))
    (match property-data
      property-info (let (
        (stay-nights (calculate-stay-duration arrival-date departure-date))
        (total-cost (* (get nightly-rate property-info) stay-nights))
        (platform-commission (calculate-platform-commission total-cost))
      )
        (some {
          stay-duration: stay-nights,
          total-booking-cost: total-cost,
          platform-commission: platform-commission,
          host-earnings: (- total-cost platform-commission)
        })
      )
      none
    )
  )
)