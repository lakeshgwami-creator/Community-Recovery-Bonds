# 🤝 Community Recovery Bonds

A decentralized mutual aid platform built on Stacks blockchain that enables communities to support each other through recovery bonds. Community members can create recovery bonds for those in need and collectively back them with STX tokens.

## 🚀 Features

- **🎯 Create Recovery Bonds**: Set up bonds for community members in need
- **💰 Community Backing**: Multiple users can contribute to bonds
- **⏰ Time-bound Support**: Bonds have expiration periods (1000 blocks)
- **🔒 Secure Claims**: Only beneficiaries can claim their bonds
- **💸 Platform Sustainability**: 2.5% platform fee for operations
- **🔄 Withdraw Protection**: Backers can withdraw if bonds expire unclaimed
- **📊 Transparency**: Full visibility of bond progress and backers

## 📋 Contract Functions

### Public Functions

#### `create-recovery-bond`
Create a new recovery bond for a community member.
```clarity
(create-recovery-bond beneficiary target-amount description)
```
- **beneficiary**: Principal who can claim the bond
- **target-amount**: STX amount needed (100-100,000 µSTX)
- **description**: Purpose of the bond (max 256 chars)

#### `back-recovery-bond`
Support an existing recovery bond with STX.
```clarity
(back-recovery-bond bond-id amount)
```
- **bond-id**: ID of the bond to back
- **amount**: STX amount to contribute

#### `claim-bond`
Claim a recovery bond (beneficiary only).
```clarity
(claim-bond bond-id)
```
- **bond-id**: ID of the bond to claim

#### `withdraw-backing`
Withdraw backing from expired unclaimed bonds.
```clarity
(withdraw-backing bond-id)
```

### Read-Only Functions

#### `get-bond`
Retrieve bond details by ID.

#### `get-bond-progress`
Get funding progress for a bond.

#### `get-platform-stats`
View platform statistics (total bonds, amounts, treasury).

#### `get-active-bonds`
List all currently active bonds.

## 🛠️ Usage Examples

### Creating a Recovery Bond
```bash
clarinet console
(contract-call? .recovery-bonds create-recovery-bond 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  u5000 
  "Medical emergency support")
```

### Backing a Bond
```bash
(contract-call? .recovery-bonds back-recovery-bond u1 u1000)
```

### Claiming a Bond
```bash
(contract-call? .recovery-bonds claim-bond u1)
```

## 🔧 Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- Node.js (for testing)

### Installation
```bash
git clone <repository>
cd Community-Recovery-Bonds
clarinet check
```

### Testing
```bash
npm install
npm test
```

## 📖 Contract Details

- **Contract Name**: `recovery-bonds`
- **Network**: Stacks Blockchain
- **Language**: Clarity
- **Bond Duration**: 1000 blocks (~7 days)
- **Min Bond Amount**: 100 µSTX
- **Max Bond Amount**: 100,000 µSTX
- **Platform Fee**: 2.5%

## 🛡️ Security Features

- ✅ Only beneficiaries can claim bonds
- ✅ Creators cannot back their own bonds
- ✅ No double-backing from same user
- ✅ Automatic expiry protection
- ✅ Emergency withdrawal for contract owner

## 🤔 How It Works

1. **📝 Bond Creation**: Community member creates a recovery bond
2. **🤝 Community Support**: Others contribute STX to the bond
3. **💰 Claiming**: Beneficiary claims funds when needed
4. **🔄 Safety Net**: Unclaimed expired bonds can be withdrawn by backers

## 📊 Platform Economics

- Bonds must be between 100-100,000 µSTX
- 2.5% platform fee on successful claims
- Fees support platform maintenance and development
- Backers can recover funds from expired bonds

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `clarinet check`
5. Submit a pull request

## 📄 License

This project is open source. See LICENSE file for details.

## 🆘 Support

For questions or issues:
- Create an issue on GitHub
- Join our community discussions
- Check the documentation

---

*Building stronger communities through decentralized mutual aid* 💪
