# 📦 Zone 25-14 Database

Welcome to the database core for **Zone 25-14**.  
This module defines the full relational database structure powering the entire platform, including users, products, loyalty systems, friends system, orders, and much more.

---

## 🧠 About Zone 25-14 Database

Zone 25-14 is not just a project —  
It’s a living, evolving platform built around loyalty, rebellion, and community.

This database acts as the **foundational layer** for:

- Authentication & Role Management
- E-Commerce Systems
- Loyalty & Leveling Systems
- Product Management
- Friends & Messaging Systems
- Admin Control Systems

---

## 🛠️ Technologies Used

- **PostgreSQL** (v14+)
- **pgcrypto** extension for encryption (`uuid_generate_v4()`, data protection)
- **SQL Relational Schema**
- **Manual Scripts & Controlled Evolution**

---

## 📋 Database Core Structure

| Table | Purpose |
|:------|:--------|
| users | Main user accounts, encrypted data, authentication |
| user_roles_levels | Role management (Explorer, Supporter, Moderator, Founder, etc.) |
| products | Main products listed for e-commerce |
| product_images | Store multiple images for each product |
| product_variations | Handle size, color, etc. for each product |
| brands | Brand/Niche linkage (OtakuSquad, WD Crew, etc.) |
| categories | Product categories and subcategories |
| orders | Orders placed by users |
| order_items | Items inside each order |
| wishlist | User saved/favorite products (planned) |
| friends | Friendships between users (planned) |
| messages | User-to-user messaging (planned) |
| loyalty_points | Level up users based on shopping and activity |

---

## 🛡️ Security Measures

- Passwords are hashed using bcrypt (`bcryptjs` on backend side).
- Sensitive fields (email, phone) are encrypted with `pgcrypto`.
- UUIDs are used for all primary keys for extra security and scaling.

---

## 📦 How to Setup Database Locally

1. Install PostgreSQL (v14+ recommended).
2. Enable `pgcrypto` extension:

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

3. Create the database:

``bash
createdb the_zone_core

4.Run the SQL schema files manually or through a migration tool.

5.Connection details for local development:
Parameter | Value
DB_HOST | localhost
DB_PORT | 5432
DB_USER | postgres
DB_PASSWORD | yourpassword
DB_NAME | the_zone_core

## 🔥 Planned Future Upgrades

- Friends and Messaging Systems
- Donations and Loyalty Reward Titles
- Public Wishlist / Gift Systems
- Admin Dashboards and Advanced Permission Trees
- Subscription System (Mystery Boxes, Exclusive Merch)
