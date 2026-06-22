# PRESENT

Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

PRESENT is an admin-only web app for managing group attendance and finances — built to serve any group (church, social club, sports team, or community organisation) through a single admin interface. The admin records attendance for each event; the system automatically charges members for lateness or absence. Charges and payments feed a per-member balance, and the group treasury balance is derived from all payments received minus all expenses paid out. Members can also sign in to a self-service portal to view their own attendance, charges, and payments.

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
| Deployment | Kamal + Docker, fronted by Thruster, on a single AWS EC2 instance |

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

Local secrets live in `.env` (development/test, via dotenv-rails, not committed). Production credentials are set via `config/credentials.yml.enc` and Kamal secrets — see [Deploying to AWS](#deploying-to-aws) below.

| Variable | Purpose |
|---|---|
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` in production |
| `POSTGRES_PASSWORD` | Database password, read by Kamal accessory + app |
| `APP_HOST` | Production host — used for mailer links (e.g. Devise password resets) |

### Seed Data

`bin/rails db:seed` is a no-op outside `development`. In development it resets and recreates 9 demo members (no charges, payments, or attendance — those are created through the app). There is no seeded admin `User`; sign up for the first admin account through the normal Devise flow at `/users/sign_up`.

## User Roles

| Role | Description |
|---|---|
| `User` (admin) | Manages members, records attendance, creates manual charges, records payments and expenses, views reports. The only role for MVP — all non-portal routes are admin-protected. |
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
│   ├── portal/              # Member self-service dashboard
│   └── ...                  # Members, attendances, charges, payments, expenses, reports (admin)
├── models/
│   ├── attendance.rb         # Automatic charge callback, double-charge guard
│   ├── charge.rb / payment.rb / expense.rb
│   ├── member.rb             # balance_due, amount_owed
│   ├── user.rb               # Admin Devise model
│   └── concerns/
│       ├── refreshes_dashboard.rb        # Turbo broadcast on dashboard stats
│       └── refreshes_member_balance.rb   # Turbo broadcast on member balance
└── views/
    ├── attendances/ charges/ payments/ expenses/ members/   # Admin CRUD views
    ├── reports/                                              # Attendance, balances, treasury
    ├── portal/dashboard/                                     # Member self-service view
    └── devise/                                                # Admin auth views

app/javascript/controllers/
└── attendance_date_controller.js   # Stimulus controller for the attendance date picker

db/
├── schema.rb
└── seeds.rb   # Demo members only, development-only
```

## Key Models

| Model | Notes |
|---|---|
| `User` | Admin account. Devise: database_authenticatable, registerable, recoverable, rememberable, validatable. |
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
member.balance_due      = member.charges.sum(:amount) - member.payments.sum(:amount)
treasury_balance        = Payment.sum(:amount) - Expense.sum(:amount)
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

## Deploying to AWS

This app deploys via [Kamal](https://kamalmanual.com) to a single EC2 instance, with Postgres running as a Kamal accessory container on the same box. No RDS, no ECS — just one box and Docker, matching the `config/deploy.yml` already in this repo.

### 1. AWS setup (console)

1. Create an IAM user (not root) with EC2 + ECR permissions; generate access keys for the AWS CLI.
2. Launch an EC2 instance — Ubuntu 24.04, `t3.small`/`t4g.small` is enough — with a security group allowing inbound 22 (your IP only), 80, 443.
3. Allocate an Elastic IP and associate it with the instance.
4. Add your SSH public key at launch (Kamal connects over SSH to provision Docker and deploy).
5. Create an ECR repository for the `present` image.
6. (Optional) Point a domain at the Elastic IP via Route 53 or your existing registrar.

### 2. Repo config

Fill in the `TODO` placeholders in `config/deploy.yml`:

- `servers.web` → your Elastic IP
- `accessories.postgres.host` → the same Elastic IP
- `registry.server` → your ECR repository URI (`<account-id>.dkr.ecr.<region>.amazonaws.com`)

Set `proxy.ssl.host` to your domain once you have one (deploy to the bare IP first if not).

Set `APP_HOST` (used for mailer links, e.g. Devise password resets) to your domain or IP via `config/deploy.yml`'s `env.clear` once known.

### 3. Secrets

Before running any `bin/kamal` command, export in your shell:

```bash
export POSTGRES_PASSWORD=<a strong password>
```

`.kamal/secrets` reads `RAILS_MASTER_KEY` from `config/master.key` and `POSTGRES_PASSWORD`/`PRESENT_DATABASE_PASSWORD` from this env var automatically — neither is ever committed.

For ECR registry auth, also export `KAMAL_REGISTRY_PASSWORD` to an ECR auth token (`aws ecr get-login-password`).

### 4. Deploy

```bash
bin/kamal setup   # first time: provisions Docker on the server, builds/pushes, starts containers
bin/kamal deploy  # every deploy after that
```

Verify with `curl http://<elastic-ip>/up` (expect `200`), then sign up as the first real admin user through the normal Devise flow.
