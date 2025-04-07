

![Screenshot 2025-04-07 162614](https://github.com/user-attachments/assets/ad89142d-2b34-4bb0-84d2-2032d4511a2c)
![Screenshot 2025-04-07 162714](https://github.com/user-attachments/assets/bd9448f9-29b0-4265-9891-799a32c70d74)

https://github.com/user-attachments/assets/53cc70b4-577d-4c13-b93f-bc47d6ee781a

System Architecture 
![image](https://github.com/user-attachments/assets/e4004ceb-b8e3-4947-baa6-ac0648be05dd)





Overall User Flow Of The App

![image](https://github.com/user-attachments/assets/fee4111e-df58-4e26-9d0a-45c3e29fc7cb)

![image](https://github.com/user-attachments/assets/95909731-433d-4d1e-9fd1-90b5eb8b556d)


Here’s a **shortened intro** for Flinder along with **clear steps to set up the project**:

---

## 🏠 Flinder – Smart Roommate & Flat Finder

**Flinder** is a modern roommate matching app that uses AI, real-time chat, and a swipe-based interface to help users find compatible flatmates and apply for flats as a group. The platform blends **Supabase** for auth and real-time chat, **Express.js** for API orchestration, and a **Flask-based ML engine** for compatibility scoring based on user bios and lifestyle tags.

---

## ⚙️ Project Setup Guide

### 1. **Frontend: Flutter App**
> Handles UI, user interactions, swipes, and real-time messaging.

- Install Flutter: [Flutter Docs](https://docs.flutter.dev/get-started/install)
- Clone the repo:  
  ```bash
  git clone https://github.com/your-org/flinder-app.git
  cd flinder-app
  flutter pub get
  ```
- Add environment config (`.env`) with:
  ```env
  SUPABASE_URL=your-supabase-url
  SUPABASE_ANON_KEY=your-anon-key
  EXPRESS_API_URL=http://your-express-server
  ```
- Run on emulator or device:
  ```bash
  flutter run
  ```

---

### 2. **Backend: Express.js API Server**
> Orchestrates swipes, groups, chat logic, and talks to Supabase & ML engine.

- Navigate to backend:
  ```bash
  cd flinder-backend
  ```
- Install dependencies:
  ```bash
  npm install
  ```
- Create `.env`:
  ```env
  SUPABASE_URL=your-supabase-url
  SUPABASE_SERVICE_KEY=your-service-role-key
  ML_API_URL=http://localhost:5000
  PORT=3000
  ```
- Start server:
  ```bash
  npm run dev
  ```

---

### 3. **ML Engine: Flask + Docker**
> Extracts tags from bios, calculates compatibility scores.

- Navigate to ML service:
  ```bash
  cd flinder-ml
  ```
- Build & run Docker container:
  ```bash
  docker build -t flinder-ml .
  docker run -p 5000:5000 flinder-ml
  ```

---

### 4. **Supabase Setup**
> Manages auth, users, chats, swipes, groups, and real-time messaging.

- Create a project on [Supabase](https://supabase.com)
- Enable:
  - Auth (email/password)
  - Realtime for `messages`, `swipes`, `groups`
- Run SQL to create tables:
  - `users`, `swipes`, `chats`, `messages`, `chat_members`, `groups`, `flats`
- Get your `SUPABASE_URL` and keys from project settings.



