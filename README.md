# PRESENT

Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

PRESENT is an admin-only web app for managing group attendance and finances — built to serve any group (church, social club, sports team, or community organisation) through a single admin interface. The admin records attendance for each event; the system automatically charges members for lateness or absence. Charges and payments feed a per-member balance, and the group treasury balance is derived from all payments received minus all expenses paid out. Members can also sign in to a self-service portal to view their own attendance, charges, and payments.

**Live demo:** [http://3.99.87.200](http://3.99.87.200)

| | |
|---|---|
| Email | `you@example.com` |
| Password | `StrongPassword123!` |

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Rails 8.1 (Hotwire / Turbo / Stimulus) |
| Database | PostgreSQL |
| Auth | Devise — separate `User` (admin) and `Member` (self-service portal) scopes |
| Frontend | Bootstrap 5.3, Stimulus, Importmap (no Node / npm build step) |
| Forms | simple_form |
| Assets | Propshaft + sprockets-rails, sassc-rails |
| Background jobs | Solid Queue |
| Cache / real-time | Solid Cache, Solid Cable (Action Cable over DB) — Turbo Stream broadcasts on attendance/charge/payment changes |
| Deployment | Kamal + Docker, fronted by Thruster, on AWS EC2 |

## Getting Started

### Prerequisites

- Ruby 3.3.5
- PostgreSQL

### Setup

```bash
git clone <repo-url>
cd PRESENT
bin/setup
rails s
```

Visit http://localhost:3000

`bin/setup` installs gems and prepares the database. Run `bin/rails db:seed` separately if you want demo members (development only — see Seed Data below).

### Environment Variables

Local secrets live in `.env` (development/test, via dotenv-rails, not committed).

| Variable | Purpose |
|---|---|
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` in production |
| `POSTGRES_PASSWORD` | Database password |
| `APP_HOST` | Production host — used for mailer links (e.g. Devise password resets) |

### Seed Data

`bin/rails db:seed` is a no-op outside `development`. In development it resets and recreates 9 demo members (no charges, payments, or attendance — those are created through the app).

## User Roles

| Role | Description |
|---|---|
| `User` (admin) | Manages members, records attendance, creates manual charges, records payments and expenses, views reports. All non-portal routes are admin-protected. |
| `Member` | Self-service portal login only — views own attendance history, charges, and payments at `/portal`. Cannot manage other members' data. |

## Features

### Members
- CRUD for member records (name, phone, email, active flag, joined date)
- Active/inactive scoping

### Attendance
- Per-event attendance recording, single or bulk (`/attendances/bulk_new`)
- Status enum: `present`, `late`, `no_show`, `excused`
- One attendance record per member per date (unique constraint)
- Automatic charge on save: `late` → late fee, `no_show` → no-show fee; correcting a status after save voids the stale charge and recreates the correct one, with no double-charging
- Live-updating attendance index via Turbo Stream broadcasts

### Charges & Payments
- Manual charge creation (uniform, activity, membership, equipment, dues, other) alongside automatic late/no-show fees
- Payment recording per member (cash, e-transfer, credit card, other)
- Per-member balance (`charges.sum − payments.sum`) recomputed live and broadcast to the dashboard and member views

### Expenses
- Group expense recording by category (uniforms, activities, equipment, food, transportation, facility rental, other)

### Dashboard & Reports
- Dashboard with financial and attendance summary stats, live via Turbo Stream
- Reports at `/reports/attendance`, `/reports/balances`, `/reports/treasury`

### Member Portal
- Separate Devise scope (`/member/sign_in`) — members never see admin routes
- `/portal` dashboard: own attendance history, charges, and payments, read-only

## Project Structure

```
app/
├── controllers/
│   ├── members/            # Member-scoped Devise controllers (sessions, passwords)
│   ├── portal/             # Member self-service dashboard
│   └── ...                 # Members, attendances, charges, payments, expenses, reports (admin)
├── models/
│   ├── attendance.rb        # Automatic charge callback, double-charge guard
│   ├── charge.rb / payment.rb / expense.rb
│   ├── member.rb            # balance_due, amount_owed
│   ├── user.rb              # Admin Devise model
│   └── concerns/
│       ├── refreshes_dashboard.rb       # Turbo broadcast on dashboard stats
│       └── refreshes_member_balance.rb  # Turbo broadcast on member balance
└── views/
    ├── attendances/ charges/ payments/ expenses/ members/   # Admin CRUD views
    ├── reports/                                             # Attendance, balances, treasury
    ├── portal/dashboard/                                    # Member self-service view
    └── devise/                                              # Admin auth views

app/javascript/controllers/
└── attendance_date_controller.js   # Stimulus controller for the attendance date picker

db/
├── schema.rb
└── seeds.rb   # Demo members only, development-only
```

## Key Models

| Model | Notes |
|---|---|
| `User` | Admin account. Devise: database_authenticatable, recoverable, rememberable, validatable. |
| `Member` | Group member. Devise (portal login): database_authenticatable, recoverable, rememberable. Has many attendances, charges, payments. `balance_due` and `amount_owed` computed on demand via SQL sums. |
| `Attendance` | One per member per date. Enum status (`present`/`late`/`no_show`/`excused`). `after_create` fires the automatic charge; `after_update` resyncs it if status changes. Broadcasts via Turbo Stream. |
| `Charge` | Belongs to member, optionally to the attendance that generated it (`automatic?`). Enum charge_type covers both automatic fees and manual charge types. |
| `Payment` | Belongs to member. Enum payment_method (cash/etransfer/credit_card/other). |
| `Expense` | Group spending, not tied to a member. Enum category. |

## Business Rules

```ruby
LATE_FEE    = 5   # dollars, Attendance::LATE_FEE
NO_SHOW_FEE = 10  # dollars, Attendance::NO_SHOW_FEE
```

```
member.balance_due   = member.charges.sum(:amount) - member.payments.sum(:amount)
treasury_balance     = Payment.sum(:amount) - Expense.sum(:amount)
```

Fee amounts are constants, not stored in a settings table, per the MVP design principle of simple, deterministic processes.

## Commands

```bash
bin/setup                              # install gems, prepare DB (first run)
bin/dev                                # run app locally (Puma)
bin/rails db:create db:migrate
bin/rails test                         # run all tests
bin/rails test test/path/to_test.rb:42 # run one test by line number
bin/rails test:system                  # Capybara/Selenium system tests
bin/jobs                               # run background job worker
bin/rubocop                            # lint
bin/brakeman                           # static security analysis
bin/bundler-audit                      # audit gems for CVEs
bin/ci                                 # full CI suite (lint + security + tests)
```
