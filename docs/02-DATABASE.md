# Database Design

## Core Tables

### 1. Users Table
- Stores user account information
- Unique constraints on email and phone
- Supports multiple user types (individual, business, vendor, etc.)
- KYC verification status tracking

### 2. Wallets Table
- One wallet per user per currency
- Balance tracking
- Account number for bank integration
- Status management

### 3. Transactions Table
- All financial transactions
- Type: deposit, withdrawal, transfer, payment
- Status tracking
- Metadata for additional info

### 4. Roles & Permissions
- RBAC (Role-Based Access Control)
- Flexible permission system
- Role hierarchy support

### 5. KYC Documents
- Document storage references
- Verification tracking
- Timestamp management

## Schema Evolution Strategy

- Use database migrations
- Backward compatibility
- Versioning system
- Regular audits

## Data Protection

- Encryption for sensitive fields
- Row-level security
- Audit logging
- GDPR compliance
