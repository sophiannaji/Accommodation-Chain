# DecenStay: Decentralized Accommodation Marketplace

DecenStay is a comprehensive peer-to-peer accommodation booking platform built on the Stacks blockchain. It enables secure property listings, automated booking management, escrow payments, reputation systems, and dispute resolution without traditional intermediaries.

## Overview

This smart contract provides a complete decentralized alternative to centralized accommodation platforms, featuring:

- Property listing and management
- Automated booking and payment processing
- Host stake requirements for quality assurance
- Comprehensive review and rating system
- Built-in dispute resolution mechanism
- User profile management
- Platform fee collection

## Key Features

### Property Management
- Hosts can register accommodation properties with detailed information
- Properties include title, description, location, pricing, and amenities
- Availability management with date-based blocking
- Property activation/deactivation controls

### Booking System
- Guests can create bookings with automatic payment escrow
- Maximum booking duration of 7 days
- Automatic availability blocking for booked dates
- Host confirmation requirements
- Cancellation policies with 24-hour deadline

### Financial Security
- Host stake requirements (minimum 1 STX)
- Automated escrow payment system
- Platform commission (5% of booking total)
- Secure fund transfers between parties

### Quality Assurance
- Star rating system (1-5 stars)
- Written reviews for completed bookings
- Property rating aggregation
- User reputation scoring

### Dispute Resolution
- Built-in dispute initiation system
- 7-day dispute deadline after checkout
- Administrative resolution mechanism

## Contract Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `platform-fee-percentage` | 5% | Platform commission rate |
| `booking-cancellation-deadline` | 24 hours | Guest cancellation window |
| `dispute-resolution-deadline` | 7 days | Dispute filing deadline |
| `minimum-host-stake` | 1 STX | Required host stake amount |
| `maximum-booking-duration` | 7 days | Maximum stay length |
| `maximum-property-guests` | 20 | Maximum guest capacity |

## Core Functions

### Host Functions

#### `deposit-host-stake(stake-amount: uint)`
Allows users to deposit STX tokens as stake to become eligible hosts.

**Parameters:**
- `stake-amount`: Amount of STX to stake (minimum 1 STX)

**Returns:** Amount successfully staked

#### `register-accommodation-property(...)`
Registers a new property listing on the platform.

**Parameters:**
- `listing-title`: Property title (max 100 characters)
- `property-description`: Detailed description (max 500 characters)
- `property-location`: Property location (max 100 characters)
- `nightly-rate`: Price per night in STX
- `guest-capacity`: Maximum number of guests
- `available-amenities`: List of up to 10 amenities

**Returns:** New property ID

#### `modify-property-availability-status(property-id: uint, active-status: bool)`
Activates or deactivates a property listing.

**Parameters:**
- `property-id`: Target property identifier
- `active-status`: New availability status

#### `confirm-guest-booking(booking-id: uint)`
Confirms a pending booking and releases payment to host.

**Parameters:**
- `booking-id`: Target booking identifier

### Guest Functions

#### `create-accommodation-booking(...)`
Creates a new booking request with automatic payment.

**Parameters:**
- `property-id`: Target property identifier
- `arrival-date`: Check-in timestamp
- `departure-date`: Check-out timestamp
- `guest-count`: Number of guests

**Returns:** New booking ID

#### `cancel-accommodation-booking(booking-id: uint)`
Cancels a pending booking within the cancellation window.

**Parameters:**
- `booking-id`: Target booking identifier

### Review System

#### `submit-booking-review(booking-id: uint, star-rating: uint, review-text: string)`
Submits a review for a completed booking.

**Parameters:**
- `booking-id`: Target booking identifier
- `star-rating`: Rating from 1-5 stars
- `review-text`: Written review (max 500 characters)

### User Management

#### `create-user-profile(display-username: string, contact-email: string)`
Creates a user profile on the platform.

**Parameters:**
- `display-username`: Display name (3-50 characters)
- `contact-email`: Contact email (5-100 characters)

### Dispute Resolution

#### `initiate-booking-dispute(booking-id: uint, dispute-reason: string)`
Initiates a dispute for a booking within the deadline.

**Parameters:**
- `booking-id`: Target booking identifier
- `dispute-reason`: Detailed dispute explanation

## Read-Only Functions

### Property Queries
- `get-property-details(property-id: uint)`: Get complete property information
- `check-property-date-availability(property-id: uint, target-date: uint)`: Check date availability
- `calculate-property-average-rating(property-id: uint)`: Get property's average rating

### Booking Queries
- `get-booking-details(booking-id: uint)`: Get complete booking information
- `estimate-booking-costs(property-id: uint, arrival-date: uint, departure-date: uint)`: Calculate booking costs

### User Queries
- `get-host-stake-info(host-address: principal)`: Get host stake information
- `get-user-profile-info(user-address: principal)`: Get user profile data
- `get-booking-review(booking-id: uint)`: Get booking review
- `get-booking-dispute(booking-id: uint)`: Get dispute information

### Platform Queries
- `get-total-platform-fees()`: Get accumulated platform fees

## Data Structures

### Property Structure
```
{
  property-owner: principal,
  listing-title: string,
  property-description: string,
  property-location: string,
  nightly-rate: uint,
  guest-capacity: uint,
  available-amenities: list,
  listing-active-status: bool,
  completed-booking-count: uint,
  cumulative-rating-points: uint,
  total-review-count: uint,
  property-creation-time: uint
}
```

### Booking Structure
```
{
  booked-property-id: uint,
  booking-guest: principal,
  property-host: principal,
  arrival-date: uint,
  departure-date: uint,
  guest-count: uint,
  booking-total-amount: uint,
  platform-commission: uint,
  booking-status: string,
  booking-creation-time: uint,
  host-confirmation-time: optional uint,
  booking-cancellation-time: optional uint
}
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | ERR-UNAUTHORIZED-ACCESS | User lacks permission for action |
| 101 | ERR-PROPERTY-NOT-FOUND | Property ID does not exist |
| 102 | ERR-BOOKING-NOT-FOUND | Booking ID does not exist |
| 103 | ERR-INVALID-DATE-RANGE | Invalid or illogical date range |
| 104 | ERR-PROPERTY-UNAVAILABLE | Property not available for booking |
| 105 | ERR-INSUFFICIENT-PAYMENT | Insufficient funds for transaction |
| 106 | ERR-BOOKING-ALREADY-EXISTS | Duplicate booking attempt |
| 107 | ERR-CANCELLATION-DEADLINE-EXPIRED | Past cancellation window |
| 108 | ERR-REVIEW-ALREADY-SUBMITTED | Review already exists |
| 109 | ERR-INVALID-RATING-VALUE | Rating outside 1-5 range |
| 110 | ERR-DISPUTE-DEADLINE-EXPIRED | Past dispute filing window |
| 111 | ERR-INSUFFICIENT-HOST-STAKE | Host stake below minimum |
| 112 | ERR-PROPERTY-ALREADY-REGISTERED | Property already exists |
| 113 | ERR-INVALID-INPUT-DATA | Invalid input parameters |
| 114 | ERR-INVALID-AMOUNT-VALUE | Invalid amount specified |

## Booking Status Flow

1. **pending** - Initial booking state awaiting host confirmation
2. **confirmed** - Host approved booking, payment released
3. **completed** - Stay finished, available for review
4. **cancelled** - Booking cancelled within deadline
5. **disputed** - Dispute initiated, under resolution

## Platform Economics

### Revenue Model
- 5% commission on all confirmed bookings
- Platform fees accumulated in contract
- Admin withdrawal of collected fees

### Host Requirements
- Minimum 1 STX stake required
- Stake acts as quality assurance mechanism
- Stake can be increased but not withdrawn during active listings

### Payment Flow
1. Guest pays total amount on booking creation
2. Funds held in escrow until host confirmation
3. Upon confirmation: host receives 95%, platform retains 5%
4. Cancellations result in full refund to guest

## Security Features

- Comprehensive input validation on all functions
- Authorization checks for protected operations
- Automatic availability management
- Secure fund transfers with escrow protection
- Time-based operation windows for cancellations and disputes

## Usage Examples

### Becoming a Host
1. Call `deposit-host-stake(1000000)` to stake 1 STX
2. Call `create-user-profile("MyHostName", "host@example.com")`
3. Call `register-accommodation-property(...)` with property details

### Making a Booking
1. Call `create-user-profile("GuestName", "guest@example.com")`
2. Query property availability with `check-property-date-availability(...)`
3. Estimate costs with `estimate-booking-costs(...)`
4. Create booking with `create-accommodation-booking(...)`

### Completing a Stay
1. Host confirms booking with `confirm-guest-booking(...)`
2. After checkout, participants can submit reviews with `submit-booking-review(...)`
3. If issues arise, initiate disputes with `initiate-booking-dispute(...)`

## Development Notes

This contract is written in Clarity for the Stacks blockchain and implements comprehensive accommodation marketplace functionality with built-in economic incentives, quality controls, and dispute resolution mechanisms.