# 📊 Technical Documentation: Coin Circle App

This document provides a comprehensive technical breakdown of the **Coin Circle** application—a production-ready group savings (Digital Chit Fund) platform.

---

## 1. Wireframe Diagram (Low-Fidelity)
*Low-fidelity sketches of all app screens showing layout and navigation.*

![Wireframe Diagram](docs/wireframe_diagram.png)

**Overview:**
- **Auth Flow**: Simple login/signup with email validation.
- **Dashboard**: Core hub for savings pools and wallet overview.
- **Pool Management**: Detail views for contribution history and member lists.
- **Wallet**: Interface for manual funding and withdrawal requests.

---

## 2. User Flow Diagram
*The step-by-step journey of a user interacting with the app's core features.*

```mermaid
graph TD
    Start((Start)) --> Onboard{Onboarded?}
    Onboard -- No --> Signup[Signup / Email Verification]
    Onboard -- Yes --> Login[Login]
    
    Signup --> Profile[Profile Setup & KYC]
    Login --> Dashboard[Main Dashboard]
    
    Dashboard --> Explore[Explore Pools]
    Dashboard --> Create[Create New Pool]
    Dashboard --> Wallet[Manage Wallet]
    
    Explore --> Join[Join Pool]
    Join --> Deposit[Add Funds to Wallet]
    Deposit --> Pay[Submit Contribution]
    
    Pay --> Draw{Wait for Draw}
    Draw --> Winner[Winner Selected]
    Winner --> Payout[Receive Payout]
    Payout --> Repeat[Join Next Round]
```

---

## 3. System Architecture Diagram
*The distributed infrastructure powering real-time financial collaboration.*

![System Architecture](docs/system_architecture.png)

```mermaid
graph TD
    Client[Flutter Mobile App] <--> Auth[Supabase Auth]
    Client <--> API[Postgres / RPC API]
    Client <--> Realtime[Supabase Realtime]
    Client <--> Storage[Supabase Storage]
    
    subgraph "Backend (Supabase)"
        API <--> DB[(PostgreSQL)]
        Realtime <--> DB
        Storage <--> DB
        DB --- RLS[Row Level Security]
    end
    
    subgraph "External Integration"
        Client <--> FCM[Firebase Cloud Messaging]
        Client <--> Payments[UPI / Manual Verification]
    end
```

---

## 4. Database Schema Diagram
*Entities and relational constraints for secure financial auditing.*

![Database Schema](docs/database_schema.png)

```mermaid
erDiagram
    profiles ||--o{ pool_members : "belongs to"
    profiles ||--o{ transactions : "commits"
    pools ||--o{ pool_members : "contains"
    pools ||--o{ draws : "generates"
    pools ||--o{ transactions : "logs"
    
    profiles {
        uuid id PK
        string full_name
        string email
        decimal wallet_balance
        string kyc_status
    }
    
    pools {
        uuid id PK
        string name
        decimal total_amount
        int max_members
        string status "active/closed/draft"
        uuid creator_id FK
    }
    
    pool_members {
        uuid id PK
        uuid pool_id FK
        uuid user_id FK
        string role "member/admin"
    }
    
    transactions {
        uuid id PK
        uuid user_id FK
        uuid pool_id FK
        decimal amount
        string type "deposit/contribution/payout/withdrawal"
        string status "pending/verified/failed"
        string utr_number
    }
    
    draws {
        uuid id PK
        uuid pool_id FK
        uuid winner_id FK
        datetime draw_date
        decimal amount
    }
```

---

## 5. API Design Diagram
*Documenting core endpoints and database procedures.*

| Method | Endpoint / Function | Payload | Response |
| :-- | :-- | :-- | :-- |
| `POST` | `auth.signUp()` | `{email, password}` | `Session Object` |
| `GET` | `from('pools')` | `query filters` | `List<Pool>` |
| `RPC` | `create_pool` | `{name, amount, members}` | `uuid pool_id` |
| `RPC` | `join_pool` | `{pool_id, user_id}` | `Success/Error` |
| `RPC` | `process_payout` | `{pool_id, winner_id}` | `Audit Record` |
| `PUT` | `update_profile` | `{full_name, avatar_url}` | `Profile` |

---

## 6. UI/UX Mockup Diagram (High-Fidelity)
*Final visual design with premium styling, dark mode, and Material 3.*

![UI/UX Mockup](docs/ui_ux_mockup.png)

**Design Highlights:**
- **Gradients**: Deep blue to gold transitions.
- **Glassmorphism**: Translucent cards for pool stats.
- **Micro-interactions**: Smooth transitions between dashboard tiles.
- **Typography**: Clean sans-serif (Inter/Outfit) for readability.

---

## 7. Component Structure Diagram
*Frontend hierarchy following Clean Architecture principles.*

```mermaid
graph TD
    App[main.dart] --> Root[App Root]
    Root --> Provider[Riverpod State Provider]
    Provider --> Shell[Scaffold Shell]
    
    Shell --> Features[Feature Modules]
    
    subgraph "Pool Feature"
        PoolUI[Pool List Widget] --> PoolItem[Pool Card Component]
        PoolItem --> PoolAction[Join Button]
        PoolAction --> PoolLogic[Pool Controller]
        PoolLogic --> PoolRepo[Pool Repository]
    end
    
    subgraph "Wallet Feature"
        WalletUI[Wallet Screen] --> TransactionList[Transaction Row]
        TransactionList --> AuditLog[Verification Badge]
    end
```

---

## 8. Data Flow Diagram
*How data travels through the app layers for a 'Deposit Funds' action.*

```mermaid
sequenceDiagram
    participant U as User
    participant V as View (Flutter)
    participant C as Controller (Riverpod)
    participant R as Repository
    participant S as Supabase Service
    participant D as Database
    
    U->>V: Enter UTR & Amount
    V->>C: triggerDeposit(amount, utr)
    C->>R: createTransactionEntry()
    R->>S: from('transactions').insert()
    S->>D: Store Pending Record
    D-->>S: Success
    S->>V: Realtime Update: "Pending Verification"
    D->>D: Trigger Notify Admin (SQL)
```

---

## 9. Deployment Architecture Diagram
*Production-ready infrastructure for global accessibility.*

```mermaid
graph TD
    CDN[Cloudflare / Global CDN] --> App[Flutter Mobile Bundle]
    App --> BaaS[Supabase Cloud]
    
    subgraph "Supabase Region"
        BaaS --> Mesh[API Gateway]
        Mesh --> Auth[Identity Service]
        Mesh --> PGB[PostgreSQL / PgBouncer]
        Mesh --> WS[Realtime WebSocket Server]
    end
    
    BaaS --> FCM[Firebase Notification Hub]
    FCM --> Dev[(User Devices)]
```

---

## 10. Technology Stack Diagram
*The modern tools powering the end-to-end experience.*

![Technology Stack](docs/tech_stack.png)

- **Frontend**: Flutter (Mobile), Dart (Logic)
- **State Mgmt**: Riverpod (Reactive state)
- **Database**: PostgreSQL (Relational storage)
- **Backend-as-a-Service**: Supabase
- **Real-time**: Supabase Realtime (WebSockets)
- **File Storage**: Supabase Storage (Identity-based)
- **Push Notifications**: Firebase Cloud Messaging
- **Security**: PostgreSQL RLS & Vault
- **Infrastructure**: GitHub Actions (CI/CD)

---
