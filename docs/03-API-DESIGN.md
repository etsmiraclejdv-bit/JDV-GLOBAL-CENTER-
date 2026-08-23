# API Design Guidelines

## API Versioning
- Current: v1
- Format: `/api/v1/resource`
- Future: `/api/v2/resource`

## Endpoint Structure

```
GET    /api/v1/users/:id             - Get user
POST   /api/v1/users                 - Create user
PUT    /api/v1/users/:id             - Update user
DELETE /api/v1/users/:id             - Delete user

GET    /api/v1/wallets/:userId       - Get wallet
POST   /api/v1/wallets/:userId/deposit    - Deposit
POST   /api/v1/wallets/:userId/withdraw   - Withdraw

POST   /api/v1/payments              - Create payment
GET    /api/v1/payments/:id          - Get payment
GET    /api/v1/payments              - List payments
```

## Response Format

### Success Response
```json
{
  "success": true,
  "data": {},
  "meta": {
    "pagination": {}
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description",
    "status": 400
  }
}
```

## Authentication
- JWT Bearer tokens
- Token expiration: 24 hours
- Refresh token: 7 days
- Required header: `Authorization: Bearer <token>`

## Rate Limiting
- 1000 requests per minute (per user)
- 10000 requests per hour (per user)

## Status Codes
- 200: OK
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error
