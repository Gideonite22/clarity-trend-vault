# TrendVault Marketplace

A decentralized marketplace for unique and emerging brands built on the Stacks blockchain. This contract handles listing, purchasing, and managing brand products with secure payments and ownership tracking.

## Features
- Brand registration and verification
- Product listing and management 
- Secure purchasing mechanism
- Auction system for products
- Royalty distribution system
- Review and rating system

## Contract Functions

### Core Marketplace
- List new products
- Purchase products
- Register brands
- Manage listings
- Handle royalties
- Leave reviews (1-5 star rating)

### Auction System
- Create timed auctions for products (minimum 10 block duration)
- Place bids on auction items
- Automatic bid refunds for outbid participants
- Secure auction completion and settlement
- View auction status and history

## Recent Enhancements

### Auction System Validation
- Added minimum auction duration of 10 blocks to prevent short-lived auctions
- Improved error handling for invalid auction parameters
- Enhanced documentation for auction duration requirements

### Review System Validation  
- Implemented maximum 5-star rating limit
- Added input validation for review ratings
- Improved error reporting for invalid ratings

### Error Handling
- New error constants for invalid duration and ratings
- More descriptive error messages
- Better validation checks
