# OmniDrive — Admin Role Setup & Privileges Guide

This guide details how Role-Based Access Control (RBAC) works in OmniDrive, how to assign the `admin` role to any account, how to create a new administrator, and how the Admin Console operates in the mobile app.

---

## 1. Role-Based Access Control (RBAC) Overview

OmniDrive enforces a 4-tier role hierarchy in Supabase PostgreSQL:

| Role | Signup Availability | Default Status | Target UI Shell | Permissions |
|:---|:---|:---|:---|:---|
| **`customer`** | Public (App UI) | Auto-approved (`is_approved = true`) | `CustomerShell` | Browse parts, place orders, chat with AI mechanic, sensor fusion runs |
| **`vendor`** | Public (App UI) | Pending (`is_approved = false`) | `VendorShell` | Manage shop catalog, inventory stock, incoming customer orders |
| **`rider`** | Public (App UI) | Pending (`is_approved = false`) | `RiderShell` | View available ready orders, claim deliveries, update dispatch status |
| **`admin`** | **Internal Only** (Database/SQL) | Pre-approved (`is_approved = true`) | `AdminShell` | Approve/reject vendor & rider applications, platform order auditing |

> **Security Note:** Public signups on the mobile app can only register as `customer`, `vendor`, or `rider`. To prevent unauthorized privilege escalation, the `admin` role cannot be self-selected during registration and must be provisioned directly via Supabase.

---

## 2. How to Assign the Admin Role

### Method 1: Instant SQL Query (Recommended)

1. Open your [Supabase Dashboard](https://supabase.com/dashboard/project/cqeubytgsrxdkfejxvan).
2. Navigate to **SQL Editor** in the left sidebar.
3. Paste and run the following query, replacing the email with the account you want to promote:

```sql
UPDATE public.user_profiles
SET role = 'admin', is_approved = true
WHERE id = (
    SELECT id 
    FROM auth.users 
    WHERE email = 'your-email@example.com'
);
```

4. Confirm the update:
```sql
SELECT u.email, p.role, p.full_name, p.is_approved
FROM auth.users u
JOIN public.user_profiles p ON p.id = u.id
WHERE u.email = 'your-email@example.com';
```

---

### Method 2: Supabase Table Editor (GUI)

1. Open your [Supabase Dashboard](https://supabase.com/dashboard/project/cqeubytgsrxdkfejxvan).
2. Go to **Table Editor** → click on `user_profiles`.
3. Locate the row corresponding to your user (match by `id` or `full_name`).
4. Double-click the `role` cell and change its value to `admin`.
5. Ensure `is_approved` is checked (`true`).
6. Click outside the cell to save.

---

### Method 3: Create a Brand New Admin Account from Scratch

If you want a dedicated administrative account (e.g., `admin@omnidrive.com`):

1. In Supabase Dashboard, go to **Authentication** → **Users** → **Add User** → **Create User**.
2. Enter the email (e.g., `admin@omnidrive.com`), set a password, and check **Auto Confirm User**.
3. Go to **SQL Editor** and run:

```sql
INSERT INTO public.user_profiles (id, role, full_name, is_approved)
VALUES (
    (SELECT id FROM auth.users WHERE email = 'admin@omnidrive.com'),
    'admin',
    'OmniDrive System Admin',
    true
)
ON CONFLICT (id) DO UPDATE 
SET role = 'admin', is_approved = true;
```

---

## 3. Currently Configured Admin Accounts

The following accounts are already registered with the `admin` role in the production database:

| Email | Full Name | Role | Status |
|:---|:---|:---|:---|
| `ammar.akbar2002@gmail.com` | Ammar | `admin` | Verified (`is_approved = true`) |
| `sardarsameerkhan5093@gmail.com` | Sardar Sameer | `admin` | Verified (`is_approved = true`) |

### Resetting Admin Password (If Needed)
To set a known testing password for either admin account, run this in the Supabase SQL Editor:
```sql
UPDATE auth.users
SET encrypted_password = crypt('Admin123!', gen_salt('bf'))
WHERE email IN ('ammar.akbar2002@gmail.com', 'sardarsameerkhan5093@gmail.com');
```
*Both accounts can then sign in with password:* `Admin123!`

---

## 4. How the Admin Login Flow Operates in the App

```
LoginScreen
   │ (User enters Admin email + password on any tab)
   ▼
Supabase Auth: signInWithPassword()
   │
   ▼
AuthGate: Checks public.user_profiles.role
   │
   ├─► role != 'admin' ───────► Route to Customer / Vendor / Rider Shell
   │
   └─► role == 'admin'
           │
           ├─► If TOTP MFA enrolled & active ──► AdminMfaScreen (6-digit TOTP challenge)
           │
           └─► No active TOTP enrolled ────────► AdminShell (Direct Entry)
```

### Universal Admin Sign-In
Admins can enter their credentials from **any** role tab on the `LoginScreen`. `AuthGate` dynamically resolves the user's role directly from the `user_profiles` database table and routes them into the `AdminShell`.

---

## 5. Admin Console Capabilities (`AdminShell`)

Once logged in as an Admin, the app provides three primary tabs:

1. **Pending Approvals (`AdminApprovalsScreen`):**
   - Live queue of newly registered **Vendors** and **Riders** (`is_approved = false`).
   - Displays shop name, business location, phone number, and applicant email.
   - **One-Tap Approval:** Calls `approve_user(p_user_id, p_role)` RPC, marking the profile verified and immediately unlocking app access for that vendor or rider.
   - **Rejection:** Calls `reject_user(p_user_id)` RPC to delete fraudulent signups.

2. **Global Orders Audit (`AdminOrdersScreen`):**
   - Real-time visibility into all marketplace transactions across all vendor shops and riders.
   - Displays order amounts, rider delivery assignments, and fulfillment stages (`Pending` → `Preparing` → `Ready` → `Dispatched` → `Delivered`).

3. **Admin Profile (`AdminProfileScreen`):**
   - Displays admin identity, role badge, and account management options.
