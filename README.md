# Municipal Bond Issuance and Investor Relations System

A comprehensive Clarity smart contract system for managing municipal bond offerings, investor relations, and automated payment distributions.

## System Overview

This system provides a complete solution for municipal bond management with five core contracts:

### Core Contracts

1. **bond-registry.clar** - Central registry for all bond offerings
2. **investor-management.clar** - Investor verification and KYC management
3. **bond-subscription.clar** - Bond purchase and subscription processing
4. **payment-distribution.clar** - Automated interest and principal payments
5. **reporting-compliance.clar** - Performance reporting and regulatory compliance

## Key Features

### Bond Offering Management
- Create and configure bond offerings with detailed terms
- Set minimum/maximum investment amounts
- Configure interest rates and payment schedules
- Manage offering periods and closures

### Investor Relations
- Comprehensive investor verification system
- KYC compliance tracking
- Investment history and portfolio management
- Automated communication and notifications

### Payment Automation
- Scheduled interest payment distribution
- Principal repayment processing
- Automated calculation of payment amounts
- Payment history and audit trails

### Compliance & Reporting
- Real-time performance metrics
- Regulatory compliance monitoring
- Credit rating integration
- Transparent reporting for all stakeholders

## Data Structures

### Bond Structure
```clarity
{
  bond-id: uint,
  issuer: principal,
  total-amount: uint,
  interest-rate: uint,
  maturity-date: uint,
  payment-frequency: uint,
  minimum-investment: uint,
  maximum-investment: uint,
  status: (string-ascii 20),
  created-at: uint
}
