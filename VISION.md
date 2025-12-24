   # Parakeet - Vision Document
## "Airbnb for Pet Rentals"

### 🎯 Core Concept

**Parakeet** is a marketplace platform that connects pet owners (Hosts) with people seeking temporary pet companionship (Renters). Similar to how Airbnb connects property owners with travelers, Parakeet enables:

- **Pet Owners (Hosts)**: List their pets for short-term rental/companionship services
- **Pet Renters (Guests)**: Browse, search, and book pets for temporary companionship experiences

### 🏗️ Business Model

#### Two-Sided Marketplace
1. **Hosts** earn money by renting out their pets
2. **Renters** pay for temporary pet companionship experiences
3. **Platform** takes a commission (similar to Airbnb's model)

#### Use Cases
- **Therapy & Emotional Support**: Rent a pet for companionship during difficult times
- **Trial Before Adoption**: Experience living with a pet before committing to adoption
- **Travel Companions**: Rent a pet-friendly companion for a trip
- **Pet Sitting Alternative**: Hosts can monetize their pets while providing companionship
- **Special Events**: Rent pets for events, photoshoots, or experiences
- **Pet Therapy**: Access to therapy animals for specific needs

---

### 👥 User Types

#### 1. **Pet Hosts** (Pet Owners)
- List their pets with detailed profiles
- Set availability calendars
- Set rental rates (daily/weekly)
- Manage bookings and requests
- Communicate with renters
- Receive payments

#### 2. **Pet Renters** (Guests)
- Browse available pets
- Search and filter by preferences
- View detailed pet profiles
- Book rental periods
- Message hosts
- Leave reviews and ratings
- Make payments

---

### 🚀 Core Features Required

#### Phase 1: MVP (Minimum Viable Product)
- [x] User authentication (Login/Register)
- [x] Pet listing creation (detailed forms)
- [ ] **Pet browsing & search** (with filters)
- [ ] **Pet detail pages** (full profile view)
- [ ] **Booking system** (calendar, dates, requests)
- [ ] **Messaging system** (host-renter communication)
- [ ] **Payment integration** (Stripe/PayPal)
- [ ] **Reviews & ratings** (post-rental feedback)
- [ ] **User profiles** (host/renter profiles)

#### Phase 2: Enhanced Features
- [ ] Availability calendar management
- [ ] Booking management dashboard
- [ ] Price calculator (daily/weekly rates)
- [ ] Advanced search filters
- [ ] Saved favorites/wishlist
- [ ] Email/SMS notifications
- [ ] In-app messaging
- [ ] Photo galleries
- [ ] Location-based search (map view)

#### Phase 3: Advanced Features
- [ ] Insurance integration
- [ ] Background checks for renters
- [ ] Pet health verification
- [ ] Emergency contact system
- [ ] Dispute resolution
- [ ] Analytics dashboard for hosts
- [ ] Mobile app (iOS/Android)
- [ ] Social sharing

---

### 📊 Data Model

#### Pet Listing Schema (Current + Additions Needed)
```dart
{
  // Current fields (already in create_companion.dart)
  'animalType': String,
  'name': String,
  'breed': String,
  'age': String,
  'gender': String,
  'color': String,
  'weight': String,
  'images': List<String>,
  'healthInfo': {...},
  'behavioralInfo': {...},
  'groomingInfo': {...},
  'dietInfo': {...},
  
  // NEW fields needed for rental marketplace
  'hostId': String,              // Firebase Auth UID
  'hostName': String,
  'hostProfileImage': String,
  'location': {
    'address': String,
    'city': String,
    'province': String,
    'postalCode': String,
    'coordinates': GeoPoint
  },
  'pricing': {
    'dailyRate': double,
    'weeklyRate': double,
    'currency': String
  },
  'availability': {
    'startDate': Timestamp,
    'endDate': Timestamp,
    'blockedDates': List<Timestamp>
  },
  'rentalTerms': {
    'minimumDays': int,
    'maximumDays': int,
    'cancellationPolicy': String,
    'requirements': List<String>  // e.g., "Must have pet experience"
  },
  'status': String,              // 'available', 'booked', 'unavailable'
  'rating': double,              // Average rating
  'reviewCount': int,
  'createdAt': Timestamp,
  'updatedAt': Timestamp
}
```

#### Booking Schema
```dart
{
  'bookingId': String,
  'petListingId': String,
  'hostId': String,
  'renterId': String,
  'startDate': Timestamp,
  'endDate': Timestamp,
  'totalDays': int,
  'totalPrice': double,
  'status': String,              // 'pending', 'confirmed', 'completed', 'cancelled'
  'paymentStatus': String,       // 'pending', 'paid', 'refunded'
  'paymentIntentId': String,     // Stripe payment intent
  'createdAt': Timestamp,
  'cancelledAt': Timestamp,
  'cancellationReason': String
}
```

#### Review Schema
```dart
{
  'reviewId': String,
  'bookingId': String,
  'petListingId': String,
  'hostId': String,
  'renterId': String,
  'renterName': String,
  'renterProfileImage': String,
  'rating': int,                 // 1-5 stars
  'comment': String,
  'createdAt': Timestamp
}
```

#### User Profile Schema
```dart
{
  'userId': String,              // Firebase Auth UID
  'email': String,
  'displayName': String,
  'profileImage': String,
  'phoneNumber': String,
  'userType': String,            // 'host', 'renter', 'both'
  'location': {
    'city': String,
    'province': String
  },
  'bio': String,
  'verificationStatus': String,  // 'verified', 'pending', 'unverified'
  'hostStats': {
    'totalListings': int,
    'totalBookings': int,
    'averageRating': double
  },
  'renterStats': {
    'totalBookings': int,
    'averageRating': double
  },
  'createdAt': Timestamp
}
```

---

### 🎨 User Flows

#### Host Flow (Listing a Pet)
1. Register/Login
2. Navigate to "List Your Pet"
3. Fill out comprehensive pet profile form
4. Add photos (5 images)
5. Set location
6. Set pricing (daily/weekly rates)
7. Set availability calendar
8. Set rental terms and requirements
9. Publish listing
10. Manage bookings and messages

#### Renter Flow (Booking a Pet)
1. Register/Login
2. Browse/search pets on dashboard
3. Filter by type, location, price, availability
4. View pet detail page
5. Check availability calendar
6. Select rental dates
7. Send booking request
8. Message host (if needed)
9. Confirm booking
10. Make payment
11. Complete rental experience
12. Leave review and rating

---

### 💰 Monetization Strategy

#### Commission Model (Like Airbnb)
- **Platform Fee**: 10-15% of booking total (charged to host)
- **Service Fee**: 5-10% of booking total (charged to renter)
- **Payment Processing**: Additional 2.9% + $0.30 per transaction

#### Alternative Models
- **Subscription**: Hosts pay monthly fee for unlimited listings
- **Premium Listings**: Featured placement for additional fee
- **Insurance**: Optional pet insurance add-on

---

### 🔒 Safety & Trust Features

#### Verification
- Email verification (required)
- Phone number verification
- Government ID verification (for hosts)
- Background checks (optional premium feature)

#### Safety Measures
- Secure payment processing (no direct host-renter payments)
- Dispute resolution system
- Emergency contact system
- Pet health verification
- Insurance requirements
- Clear terms of service and rental agreements

---

### 🛠️ Technical Stack (Current)

#### Frontend
- **Framework**: Flutter (Dart)
- **Platforms**: Web, iOS, Android, Desktop

#### Backend
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Hosting**: Firebase Hosting (for web)

#### Additional Services Needed
- **Payments**: Stripe or PayPal integration
- **Maps**: Google Maps API (for location features)
- **Notifications**: Firebase Cloud Messaging
- **Email**: SendGrid or Firebase Extensions
- **Analytics**: Firebase Analytics

---

### 📱 Key Screens/Features to Build

#### 1. **Dashboard/Home Screen** (Partially Complete)
- ✅ Search bar
- ✅ Category filters
- ❌ Pet listing cards/grid
- ❌ Map view toggle
- ❌ Filter sidebar

#### 2. **Pet Detail Screen** (Not Started)
- Pet photo gallery
- Pet information sections
- Host profile card
- Availability calendar
- Pricing display
- Booking button
- Reviews section
- Location map

#### 3. **Booking Flow** (Not Started)
- Date picker
- Price calculator
- Rental terms display
- Payment form
- Booking confirmation

#### 4. **Messaging Screen** (Not Started)
- Conversation list
- Chat interface
- File/image sharing

#### 5. **User Profile** (Not Started)
- Profile information
- Listings (for hosts)
- Booking history
- Reviews received/given
- Settings

#### 6. **Host Dashboard** (Not Started)
- Active listings
- Booking requests
- Calendar view
- Earnings summary
- Analytics

---

### 🎯 Success Metrics

#### Key Performance Indicators (KPIs)
- Number of active pet listings
- Number of completed bookings
- Average booking value
- Host retention rate
- Renter repeat booking rate
- Average rating
- Platform revenue
- User growth rate

---

### 🚦 Development Roadmap

#### **Sprint 1: Foundation** (Current State)
- ✅ User authentication
- ✅ Pet listing creation
- 🔄 **Next**: Display listings on dashboard

#### **Sprint 2: Discovery**
- Build pet listing cards/grid
- Implement search functionality
- Add filter system
- Create pet detail page

#### **Sprint 3: Booking System**
- Date picker component
- Booking request system
- Booking management
- Status tracking

#### **Sprint 4: Communication**
- In-app messaging
- Notification system
- Email notifications

#### **Sprint 5: Payments**
- Stripe integration
- Payment processing
- Transaction history
- Payout system for hosts

#### **Sprint 6: Reviews & Trust**
- Review system
- Rating display
- User profiles
- Verification badges

#### **Sprint 7: Polish & Scale**
- Performance optimization
- Advanced features
- Mobile app optimization
- Marketing features

---

### ❓ Questions to Clarify

1. **Rental Duration**: What are typical rental periods? (hours, days, weeks?)
2. **Pet Care Responsibility**: Who is responsible during rental? (renter or host?)
3. **Insurance**: Is pet insurance required? Who provides it?
4. **Legal**: What are the legal requirements for pet rental in Canada?
5. **Vet Access**: What happens if pet needs medical attention during rental?
6. **Pet Transportation**: How do pets get to renters? (pickup, delivery?)
7. **Screening**: How do we verify renters are capable of caring for pets?
8. **Cancellation**: What are cancellation policies and refunds?

---

### 📝 Next Steps

1. **Clarify vision** with stakeholders (this document)
2. **Prioritize features** for MVP
3. **Design database schema** in Firestore
4. **Build listing display** on dashboard
5. **Implement search and filters**
6. **Create pet detail page**
7. **Build booking system**
8. **Integrate payment processing**

---

*Last Updated: [Current Date]*
*Version: 1.0*

