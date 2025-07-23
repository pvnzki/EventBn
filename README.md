# 🎟️ Event Ticketing Platform

A modern, scalable, and user-friendly **event ticketing and management system** designed for both end-users and organizers.  
This system includes a **Flutter mobile app**, a **web-based organizer dashboard**, and a **robust backend API** with a PostgreSQL database.

---

## 🚀 Features

### User App (Flutter)
- Browse and search events
- Book and purchase tickets
- View ticket QR codes
- Event notifications and reminders

### Organizer Dashboard (Web)
- Create and manage events
- Ticket tier setup (e.g., VIP, Early Bird)
- View analytics and sales reports
- Manage check-ins and validate tickets

### Backend API
- RESTful API with secure endpoints
- JWT-based authentication
- PostgreSQL relational database
- Admin, Organizer, and User roles

---

## 🧱 Tech Stack

| Layer        | Technology                        |
|--------------|------------------------------------|
| Mobile App   | Flutter                            |
| Web Dashboard| React / Next.js + Tailwind CSS     |
| Backend API  | Node.js (Express/NestJS) / Django  |
| Database     | PostgreSQL                         |
| DevOps       | Docker, GitHub Actions, NGINX      |

---

## 📂 Folder Structure

```bash
event-ticketing-system/
│
├── mobile-app/                  # Flutter mobile app (Android/iOS)
│   └── ...                      # All Flutter source files
│
├── web-dashboard/              # Organizer web portal (React/Next.js)
│   └── ...                      # Web frontend components and pages
│
├── backend-api/                # RESTful or GraphQL backend API
│   ├── src/
│   │   ├── controllers/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── models/
│   │   └── middleware/
│   ├── tests/
│   ├── .env.example
│   └── package.json / requirements.txt
│
├── database/                   # DB schema, ERD, and migrations
│   ├── er-diagram.png
│   ├── schema.sql
│   ├── migrations/
│   └── db-docs.md
│
├── docs/                       # Documentation and reference files
│   ├── project-proposal.pdf
│   ├── srs.md
│   └── technology-stack.md
│
├── devops/                     # Deployment, CI/CD, Docker, etc.
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── github-actions/
│   └── nginx/
│
├── .gitignore
└── README.md
```

## ⚙️ Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/event-ticketing-system.git
cd event-ticketing-system
```

### 2. Setup Mobile App (Flutter)
```bash
cd mobile-app
flutter pub get
flutter run
```

### 3. Setup Web Dashboard
```bash
cd web-dashboard
npm install
npm run dev
```

### 4. Setup Backend
```bash
cd backend-api
npm install
cp .env.example .env
npm run dev
```

## 🛠️ Deployment & CI/CD

This project includes Docker support and GitHub Actions CI/CD pipelines. See `devops/` for deployment scripts and configs.
