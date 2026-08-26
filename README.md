# 🖨️ Production-Ready Printing & Signage Management System

An end-to-end enterprise mobile application and backend for managing printing & signage operations across the complete business lifecycle:

$$\text{Customer} \longrightarrow \text{Site Visit} \longrightarrow \text{Measurement} \longrightarrow \text{Design Final} \longrightarrow \text{Printing} \longrightarrow \text{Fabrication} \longrightarrow \text{Installation} \longrightarrow \text{Delivery} \longrightarrow \text{Billing} \longrightarrow \text{Payment} \longrightarrow \text{Customer Feedback}$$

---

## 🌟 Key System Capabilities

- **Cross-Platform Mobile Application (Android & iOS)**: Built with Flutter (Material 3) featuring Clean Architecture and dynamic role-based navigation.
- **Backend Service**: Built with NestJS, TypeScript, PostgreSQL, and Prisma ORM.
- **Role-Based Access Control (4 Roles)**:
  1. **Super Admin**: Executive P&L dashboard, inventory threshold alerts, staff payroll slips, quotations, invoices, and payment tracking.
  2. **Field Boy**: Assigned site visits, live auto-calculated smart measurements ($\text{Sq.Ft} = L \times H$, $\text{Sq.M} = \text{Sq.Ft} \times 0.092903$), touch photo annotations, 10s video recording, technical checklist, and offline draft sync.
  3. **Designer & Operator**: Design proof queue, instant **1-second QR scanner** for live stage advancements, DPR logging for Eco-Solvent, UV, Solvent, and CNC machines.
  4. **Installation Team**: On-site navigation, before/after photos, petty cash site expenses (screws, adhesive, tempo, tea), customer digital signature pad, and 1–5 star reviews.
- **Smart Attendance**: Geofencing GPS check-in (200m factory radius validation via Haversine formula), QR code scanning, and selfie photo verification.
- **Gamification & Rewards**: Points engine (+50 pts / 100 Sq.Ft, +100 pts zero waste, +150 pts 5-star rating) with monthly leaderboard and **Employee of the Month** cash bonus integrated into monthly salary slips.
- **Billing & Accounting**: Automatic Rate Calculator `(Sq.Ft × Rate) + Framing + Installation + GST`, branded PDF generation, and direct WhatsApp sharing.
- **Customer Live Tracking Web Portal**: Token-protected live progress page accessible by customers via browser with zero login required.

---

## 📁 Repository Structure

```
mob app/
├── backend/                  # NestJS TypeScript REST API & Prisma Service
│   ├── prisma/
│   │   ├── schema.prisma     # 26 Database Models & Enums
│   │   └── seed.ts           # Development seed data for all 4 roles & catalog
│   ├── src/
│   │   ├── auth/             # JWT auth, refresh tokens, role guards
│   │   ├── users/            # Staff directory and user management
│   │   ├── customers/        # Customer CRM
│   │   ├── site-visits/      # Site task dispatch & technical checklist
│   │   ├── measurements/     # Smart area calculation engine
│   │   ├── jobs/             # Digital job cards & QR generator
│   │   ├── job-stages/       # 1-Second QR stage updater
│   │   ├── dpr/ & machines/  # Daily production reports (Eco-Solvent, UV, Solvent, CNC)
│   │   ├── inventory/        # Material stock (rolls, acrylic, LEDs, SMPS, pipes) & low-stock alerts
│   │   ├── attendance/       # 200m Geofencing GPS, QR attendance & selfie verification
│   │   ├── salary/           # Monthly payroll calculation & PDF salary slips
│   │   ├── rewards/          # Gamification points & monthly leaderboard
│   │   ├── quotations/       # Rate calculator & branded PDF quotations
│   │   ├── invoices/         # GST / Non-GST invoices & WhatsApp sharing
│   │   ├── payments/         # Payment ledger & balance tracking
│   │   ├── petty-cash/       # Daily site expense logging & admin approvals
│   │   ├── tracking/         # Public customer tracking portal endpoint
│   │   ├── storage/          # Media upload & file serving
│   │   └── reports/          # Executive business analytics & P&L
│   ├── uploads/              # Uploaded photos, videos, signatures, and PDFs
│   └── test/                 # Test suites (Calculation engine unit tests)
│
├── mobile_app/               # Cross-Platform Flutter Mobile Application
│   ├── android/              # AndroidManifest with Camera, 200m GPS Location permissions
│   ├── ios/                  # iOS Info.plist with Camera, Photo Library & Location descriptions
│   └── lib/
│       ├── core/             # Design tokens, theme, ApiClient, LocalStorage, calculators
│       └── features/
│           ├── auth/         # Login & quick role selector
│           ├── dashboard/    # Super Admin, Field Boy, Designer & Installer dynamic dashboards
│           ├── site_visit/   # Measurements, photo annotation canvas, 10s video, checklist
│           ├── jobs/         # Visual stage progress timeline & 1-second QR scanner
│           ├── production/   # Daily Production Report entry form
│           ├── inventory/    # Stock levels & low-stock alerts
│           ├── attendance/   # 200m Geofence GPS check-in & salary slip viewer
│           ├── rewards/      # Leaderboard & Employee of the Month podium
│           ├── quotations/   # Rate builder & invoice ledger
│           ├── petty_cash/   # Daily site expenses & receipt attachments
│           └── feedback/     # Customer digital signature pad & 5-star rating
│
└── docs/                     # Architecture, API specifications, and deployment guides
```

---

## 🚀 Quick Start Guide

### 1. Backend Setup & Running

```bash
cd backend

# 1. Install dependencies
npm install

# 2. Setup environment configuration
cp .env.example .env

# 3. Generate Prisma client & Push database schema
npx prisma generate
npx prisma db push

# 4. Seed development database (4 user roles, catalog, machines, jobs)
npm run prisma:seed

# 5. Run unit tests
npm test

# 6. Start development API server
npm run start:dev
```

- **REST API URL**: `http://localhost:5000/api/v1`
- **Swagger OpenAPI Documentation**: `http://localhost:5000/api/docs`
- **Customer Live Tracking Demo**: `http://localhost:5000/uploads/tracking.html`

---

### 2. Demo User Credentials

| Role | Email | Password | Access / Primary Responsibilities |
| :--- | :--- | :--- | :--- |
| **Super Admin** | `admin@signage.com` | `admin123` | Full business dashboard, P&L, staff salary, accounts, inventory |
| **Field Boy** | `fieldboy@signage.com` | `field123` | Site visits, measurements, photo annotations, 10s video, checklist |
| **Designer & Operator** | `designer@signage.com` | `design123` | Vector proofs, 1-sec QR scan stage updater, machine DPR |
| **Installation Team** | `installer@signage.com` | `install123` | On-site navigation, before/after photos, client signature, petty cash |

---

### 3. Flutter Mobile App Running

```bash
cd mobile_app

# 1. Get Flutter dependencies
flutter pub get

# 2. Run on connected Android / iOS device or emulator
flutter run
```

---

## 🧪 Verified Test Suite

The centralized calculation engine is tested and verified:
- `Sq.Ft = Length × Height`
- `Sq.M = Sq.Ft × 0.092903`
- `Quotation Total = (Sq.Ft × Rate) + Framing + Installation - Discount + GST (18%)`
- `Pending Balance = Total Invoice Amount - Paid Payments`
- `200m Geofencing GPS Verification via Haversine Geodesic Distance`
- `Monthly Salary Calculation with Late Mark Penalties, Overtime & Reward Bonuses`
