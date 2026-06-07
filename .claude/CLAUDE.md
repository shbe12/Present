# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

---

## Project overview

A Rails 8.1 admin-only web application for managing group attendance and finances. Built to serve any type of group — church, social club, sports team, or community organisation — through a single admin interface.

The admin records attendance for each event; the system automatically charges members for lateness or absence. Charges and payments feed a per-member balance. The group treasury balance is derived from all payments received minus all expenses paid out.

**Design principle:** prefer simple, deterministic processes. Business rules (fee amounts, balance formulas) are explicit constants and model methods — not configurable at runtime for MVP.

**MVP scope (Phase 1)**

- Member management (CRUD)
- Attendance recording per event
- Automatic late-fee and no-show-fee charges on attendance save
- Manual charge creation (uniform, activity, equipment, dues, etc.)
- Payment recording from members
- Expense recording for group spending
- Dashboard with financial and attendance summaries
- Balance reports (per member and treasury)

**Planned future phases**

- Multi-group support (each group isolated, admin scoped to their group)
- Group-type configuration (church / social / sports / community) to tailor terminology and charge types
- Member self-service portal (view own balance, attendance history, payment history)

Only the Admin role exists for MVP. All routes are admin-protected.

---

## Expected data flow

### Attendance → automatic charge

```
Admin records attendance
  └─ status == :late    → Charge.create!(charge_type: :late_fee,    amount: 5)
  └─ status == :no_show → Charge.create!(charge_type: :no_show_fee, amount: 10)
  └─ status == :present / :excused → no charge
```

Charge creation happens in an `after_create` callback on `Attendance`. If a status is corrected after saving, the associated charge must be voided or destroyed. Guard against double-charging on re-save.

### Member balance

```
member.balance_due = member.charges.sum(:amount) - member.payments.sum(:amount)
```

Computed on demand. Avoid N+1 on index pages — use `includes` or a counter cache when listing all members with balances.

### Treasury balance

```
treasury_balance = Payment.sum(:amount) - Expense.sum(:amount)
```

Member payments are the primary income source. Donations are a future addition (will require a separate `Income` model or a `category: :donation` on a generic income record).

### Automatic fee amounts

Defined as constants — not stored in a settings table for MVP:

```ruby
LATE_FEE    = 5   # dollars
NO_SHOW_FEE = 10  # dollars
```

---

## Data models

### Member
| Field | Type | Notes |
|---|---|---|
| `name` | string | required |
| `phone` | string | |
| `email` | string | |
| `active` | boolean | default true |
| `joined_on` | date | |

Associations: `has_many :attendances`, `has_many :charges`, `has_many :payments`

### Attendance
| Field | Type | Notes |
|---|---|---|
| `member_id` | references | |
| `date` | date | |
| `status` | string | enum: present, late, no_show, excused |
| `notes` | text | |

`after_create` callback fires charge creation for `late` and `no_show`.

### Charge
| Field | Type | Notes |
|---|---|---|
| `member_id` | references | |
| `amount` | decimal | |
| `charge_type` | string | enum: late_fee, no_show_fee, uniform, activity, membership, equipment, other |
| `description` | string | |
| `due_date` | date | |

### Payment
| Field | Type | Notes |
|---|---|---|
| `member_id` | references | |
| `amount` | decimal | |
| `paid_on` | date | |
| `payment_method` | string | enum: cash, etransfer, credit_card, other |
| `notes` | text | |

### Expense
| Field | Type | Notes |
|---|---|---|
| `amount` | decimal | |
| `category` | string | enum: uniforms, activities, equipment, food, transportation, facility_rental, other |
| `description` | string | |
| `spent_on` | date | |

---

## Tech stack

| Layer | Choice |
|---|---|
| Language | Ruby 3.3.5 |
| Framework | Rails 8.1 |
| Database | PostgreSQL |
| Auth | Devise (`:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`) |
| Frontend JS | Hotwire — Turbo + Stimulus via importmap (no Node / npm build step) |
| CSS | Bootstrap 5.3 + sassc-rails; SCSS entrypoint at `app/assets/stylesheets/application.scss` |
| Forms | simple_form |
| Assets | Propshaft + sprockets-rails |
| Background jobs | solid_queue (`bin/jobs`) |
| Cache / cable | solid_cache, solid_cable (database-backed, no Redis) |
| Deploy | Kamal (`bin/kamal`) + Dockerfile, fronted by Thruster |
| Env vars | dotenv-rails (`.env` in development/test) |
| Linting | RuboCop (`rubocop-rails-omakase` + `.rubocop.yml` overrides) |
| Security | Brakeman + bundler-audit |
| Testing | Minitest + Capybara/Selenium for system tests |

Scaffolded from [lewagon/rails-templates](https://github.com/lewagon/rails-templates) Devise template.

---

## Commands

```bash
bin/setup                              # install gems, prepare DB (first run)
bin/dev                                # run app locally (Puma)
bin/rails db:create db:migrate
bin/rails db:prepare                   # create + migrate/load schema
bin/rails test                         # run all tests
bin/rails test test/path/to_test.rb    # run one file
bin/rails test test/path/to_test.rb:42 # run one test by line number
bin/rails test:system                  # Capybara/Selenium system tests
bin/jobs                               # run background job worker
bin/rubocop                            # lint
bin/brakeman                           # static security analysis
bin/bundler-audit                      # audit gems for CVEs
bin/ci                                 # full CI suite (lint + security + tests)
```

---

## Conventions

### General
- Prefer simple, deterministic solutions. If a task can be done with a straightforward Rails pattern (callback, scope, model method), do that rather than introducing additional abstractions.
- Keep processes cheap — avoid unnecessary queries, callbacks, or service objects when a model method or scope is sufficient.
- When a feature has non-deterministic edge cases (e.g. correcting an attendance status after a charge was already created), isolate that logic in the model with clear guard clauses rather than handling it ad hoc in controllers or views.

### Style
- RuboCop config (`.rubocop.yml`) relaxes Omakase: double-quoted strings allowed, 120-char line length, several Metrics/Style cops disabled. Match this style in all new code.
- Use `simple_form` for all forms, consistent with the Devise views in `app/views/devise/`.
- Use Bootstrap 5.3 utility classes and components for markup and layout.

### Models
- Enums declared with `enum :field, { value: "value" }` (string-backed) for database readability.
- Monetary amounts stored as `decimal` (not integer cents) for simplicity at this scale.
- Business logic (balance calculation, fee constants) lives in the model, not the controller.
- Charge creation from attendance lives in an `after_create` callback on `Attendance`, not in the controller.

### Controllers
- Thin controllers — no balance math or fee logic inline.
- Use `before_action :authenticate_user!` on all non-public routes.
- Reports are plain scoped queries (no separate model) — consider an `app/queries/` directory as complexity grows.

### Views / Hotwire
- Prefer Turbo Frames for in-place updates (e.g. marking attendance, recording a payment) over full page reloads.
- Stimulus controllers live in `app/javascript/controllers/` and follow the `[name]_controller.js` convention.
- No `package.json` or npm — all JS added via importmap (`config/importmap.rb`) or written as Stimulus controllers.

### Testing
- Model tests cover balance calculation logic and automatic charge callbacks.
- System tests cover the admin attendance-recording and payment-recording flows.
- No fixtures for financial data — use inline `create` calls so amounts are explicit and readable.

### Routes
- Devise routes via `devise_for :users`.
- All non-auth resources protected with `before_action :authenticate_user!`.
- Reports accessible at `/reports/attendance`, `/reports/balances`, `/reports/treasury`.
