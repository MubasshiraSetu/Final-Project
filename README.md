# Festivo — Event & Food Management App

A Flutter app for managing events and food menus using Supabase.

---

## Features
- Email/password authentication (login, register, forgot password)
- Animated splash screen with auth gate
- Dashboard with event & food statistics
- Full CRUD for Events (category, date, time, location, guests, status)
- Full CRUD for Food items (category, price, quantity, vegetarian, availability)
- Link food items to events
- Search and filter for events & food
- Dark theme UI (violet + gold)
- Bottom navigation (4 tabs)

---

## Setup

### 1. Create Supabase Project
- Go to supabase
- Create a new project
- Copy **Project URL** and **Anon Key**

### 2. Setup Database
- Open Supabase SQL Editor
- Run `supabase_schema.sql`
- Creates tables: `profiles`, `events`, `food_items`

### 3. Configure App
Update `lib/utils/constants.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';