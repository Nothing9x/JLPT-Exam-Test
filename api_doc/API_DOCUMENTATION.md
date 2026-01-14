# VegaX JLPT API Documentation

**Base URL**: `https://8e23deb9e9e2.ngrok-free.app/api`

> **Note**: Đây là URL tạm thời từ ngrok. URL localhost: `http://localhost:8080/api`

---

## 1. Authentication APIs

### 1.1 Register Account
**POST** `/auth/register`

Register a new user account.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "fullName": "Nguyễn Văn A",
  "language": "vi",
  "level": 3
}
```

**Fields**:
- `email` (required): User's email address
- `password` (required): Password (min 6 characters)
- `fullName` (required): User's full name
- `language` (optional): Preferred language - "vi", "en", or "ja" (default: "vi")
- `level` (optional): JLPT level 1-5 for N1-N5 (default: null)

**Response** `200 OK`:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "fullName": "Nguyễn Văn A",
    "avatarUrl": null,
    "language": "vi",
    "level": 3,
    "oauthProvider": null,
    "isPremium": false,
    "premiumExpireDate": null,
    "subscriptionPackage": null,
    "createdAt": "2026-01-08T12:00:00"
  }
}
```

**Error Responses**:
- `400 Bad Request`: Email already exists
```json
{
  "error": "Email already exists"
}
```

---

### 1.2 OAuth Login (Google/Apple)
**POST** `/auth/oauth`

Login or register with OAuth providers (Google, Apple).

**Request Body**:
```json
{
  "email": "user@example.com",
  "provider": "google",
  "oauthId": "google_user_id_123456",
  "fullName": "Nguyễn Văn A",
  "avatarUrl": "https://example.com/avatar.jpg",
  "language": "vi",
  "level": 3
}
```

**Fields**:
- `email` (required): User's email from OAuth provider
- `provider` (required): OAuth provider - "google" or "apple"
- `oauthId` (required): User ID from OAuth provider
- `fullName` (required): User's full name from OAuth profile
- `avatarUrl` (optional): Profile picture URL
- `language` (optional): Preferred language (default: "vi")
- `level` (optional): JLPT level 1-5 (default: null)

**Response** `200 OK`:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "fullName": "Nguyễn Văn A",
    "avatarUrl": "https://example.com/avatar.jpg",
    "language": "vi",
    "level": 3,
    "oauthProvider": "google",
    "isPremium": false,
    "premiumExpireDate": null,
    "subscriptionPackage": null,
    "createdAt": "2026-01-08T12:00:00"
  }
}
```

**Error Responses**:
- `400 Bad Request`: Email already registered with different method
```json
{
  "error": "Email already registered with different method"
}
```

**Note**:
- If user already exists with same OAuth provider, updates user info and returns token
- If email exists with different provider or password login, returns error

---

### 1.3 Login (Email/Password)
**POST** `/auth/login`

Login and receive JWT token.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response** `200 OK`:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "fullName": "Nguyễn Văn A",
    "avatarUrl": null,
    "language": "vi",
    "level": 3,
    "oauthProvider": null,
    "isPremium": false,
    "premiumExpireDate": null,
    "subscriptionPackage": null,
    "createdAt": "2026-01-08T12:00:00"
  }
}
```

**Error Responses**:
- `400 Bad Request`: Invalid credentials or OAuth user trying to login with password
```json
{
  "error": "Invalid email or password"
}
```
```json
{
  "error": "Please login with google"
}
```

---

### 1.4 Get User Profile
**GET** `/user/profile`

Get current user's profile information.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response** `200 OK`:
```json
{
  "id": 1,
  "email": "user@example.com",
  "fullName": "Nguyễn Văn A",
  "avatarUrl": "https://example.com/avatar.jpg",
  "language": "vi",
  "level": 3,
  "oauthProvider": null,
  "isPremium": true,
  "premiumExpireDate": "2026-07-08T12:00:00",
  "subscriptionPackage": "premium_6month",
  "createdAt": "2026-01-08T12:00:00"
}
```

---

### 1.5 Update Profile
**PUT** `/user/profile`

Update user profile information.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:
```json
{
  "fullName": "Nguyễn Văn B",
  "avatarUrl": "https://example.com/new-avatar.jpg",
  "language": "en",
  "level": 2
}
```

**Fields** (all optional):
- `fullName`: Update user's full name
- `avatarUrl`: Update profile picture URL
- `language`: Update preferred language ("vi", "en", "ja")
- `level`: Update JLPT level (1-5)

**Response** `200 OK`:
```json
{
  "id": 1,
  "email": "user@example.com",
  "fullName": "Nguyễn Văn B",
  "avatarUrl": "https://example.com/new-avatar.jpg",
  "language": "en",
  "level": 2,
  "oauthProvider": null,
  "isPremium": true,
  "premiumExpireDate": "2026-07-08T12:00:00",
  "subscriptionPackage": "premium_6month",
  "createdAt": "2026-01-08T12:00:00"
}
```

---

## 2. Practice APIs

### 2.1 Get Practice Categories
**GET** `/practice/categories`

Get list of practice categories (Kanji, Grammar, Listening, Reading).

**Response** `200 OK`:
```json
[
  {
    "id": "kanji",
    "name": "Kanji",
    "nameJa": "漢字",
    "description": "Practice reading and writing Kanji"
  },
  {
    "id": "grammar",
    "name": "Grammar",
    "nameJa": "文法",
    "description": "Practice Japanese grammar patterns"
  },
  {
    "id": "listening",
    "name": "Listening",
    "nameJa": "聴解",
    "description": "Practice listening comprehension"
  },
  {
    "id": "reading",
    "name": "Reading",
    "nameJa": "読解",
    "description": "Practice reading comprehension"
  }
]
```

**Note**: This API doesn't require authentication and can be cached offline.

---

### 2.2 Get Random Questions
**GET** `/practice/questions?level={level}&type={type}&limit={limit}`

Get random questions based on criteria.

**Query Parameters**:
- `level` (required): JLPT level (1-5 for N1-N5)
- `type` (required): Practice type (kanji, grammar, listening, reading)
- `limit` (optional): Number of questions (default: 20, max: 50)

**Example Request**:
```
GET /practice/questions?level=3&type=kanji&limit=20
```

**Response** `200 OK`:
```json
[
  {
    "id": 12345,
    "question": "彼女は<u>色盲</u>になった。",
    "answers": ["しきかん", "いろがた", "しきもう", "いろかた"],
    "audio": null,
    "image": null,
    "type": "kanji",
    "level": 3
  },
  {
    "id": 12346,
    "question": "この問題は<u>難解</u>です。",
    "answers": ["なんかい", "なんげ", "なんけ", "なんげい"],
    "audio": null,
    "image": null,
    "type": "kanji",
    "level": 3
  }
]
```

**Note**:
- Correct answer index is NOT included (only shown after submission)
- Questions are randomly selected
- For `type=listening`, `audio` field will contain the file path

---

## 3. Exam APIs

### 3.1 Get Exams by Level
**GET** `/exams?level={level}`

Get list of available exams for a specific JLPT level.

**Query Parameters**:
- `level` (required): JLPT level (1-5 for N1-N5)

**Example Request**:
```
GET /exams?level=1
```

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "title": "Test 1",
    "level": 1,
    "time": 85,
    "totalScore": 180,
    "passScore": 100
  },
  {
    "id": 16,
    "title": "Test 16",
    "level": 1,
    "time": 85,
    "totalScore": 180,
    "passScore": 100
  }
]
```

**Note**: This list is fixed and can be cached offline.

---

### 3.2 Get Exam Detail
**GET** `/exams/{exam_id}`

Get full details of an exam including all questions.

**Path Parameters**:
- `exam_id`: The exam ID

**Example Request**:
```
GET /exams/1
```

**Response** `200 OK`:
```json
{
  "id": 1,
  "title": "Test 1",
  "level": 1,
  "time": 85,
  "score": 180,
  "passScore": 100,
  "parts": [
    {
      "id": 1,
      "name": "文字・語彙",
      "time": 55,
      "minScore": 38,
      "maxScore": 120,
      "sections": [
        {
          "id": 1,
          "kind": "cách đọc kanji",
          "questionGroups": [
            {
              "id": 1,
              "countQuestion": 1,
              "title": "問題＿＿＿の読み方として最もよいものを、１・２・３・４から一つ選びなさい。",
              "audio": "",
              "image": "",
              "txtRead": "",
              "questions": [
                {
                  "id": 14838,
                  "question": "彼女は<u>色盲</u>になった。",
                  "answer1": "しきかん",
                  "answer2": "いろがた",
                  "answer3": "しきもう",
                  "answer4": "いろかた",
                  "correctAnswer": 2,
                  "image": "",
                  "explain": "...",
                  "explainEn": "...",
                  "explainVn": "...",
                  "explainCn": "..."
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

**Note**: Full exam data including all parts, sections, and questions.

---

### 3.3 Submit Exam
**POST** `/exams/submit`

Submit exam answers for grading and save to history.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:
```json
{
  "examId": 1,
  "answers": {
    "14838": 2,
    "14839": 1,
    "14840": 3
  }
}
```

**Response** `200 OK`:
```json
{
  "id": 123,
  "examId": 1,
  "examTitle": "Test 1",
  "totalScore": 180,
  "yourScore": 145,
  "isPassed": true,
  "submittedAt": "2026-01-08T14:30:00",
  "details": [
    {
      "questionId": 14838,
      "question": "彼女は<u>色盲</u>になった。",
      "yourAnswer": 2,
      "correctAnswer": 2,
      "isCorrect": true,
      "explanation": "しきもう means color blindness..."
    },
    {
      "questionId": 14839,
      "question": "...",
      "yourAnswer": 1,
      "correctAnswer": 3,
      "isCorrect": false,
      "explanation": "..."
    }
  ]
}
```

**Note**:
- Saves result to user's exam history
- Returns detailed breakdown of all answers
- Score is calculated based on correct answers

---

## 4. History APIs

### 4.1 Get Exam History
**GET** `/history/exams`

Get list of all exam results submitted by the user.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response** `200 OK`:
```json
[
  {
    "id": 123,
    "examId": 1,
    "examTitle": "Test 1",
    "level": 1,
    "totalScore": 180,
    "yourScore": 145,
    "isPassed": true,
    "submittedAt": "2026-01-08T14:30:00"
  },
  {
    "id": 124,
    "examId": 16,
    "examTitle": "Test 16",
    "level": 1,
    "totalScore": 180,
    "yourScore": 98,
    "isPassed": false,
    "submittedAt": "2026-01-07T10:15:00"
  }
]
```

---

### 4.2 Get Exam Result Detail
**GET** `/history/exams/{result_id}`

Get detailed results including all questions and answers for a specific exam submission.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Path Parameters**:
- `result_id`: The exam result ID

**Example Request**:
```
GET /history/exams/123
```

**Response** `200 OK`:
```json
{
  "id": 123,
  "examId": 1,
  "examTitle": "Test 1",
  "level": 1,
  "totalScore": 180,
  "yourScore": 145,
  "isPassed": true,
  "submittedAt": "2026-01-08T14:30:00",
  "answers": [
    {
      "questionId": 14838,
      "userAnswer": 2,
      "correctAnswer": 2,
      "isCorrect": true
    },
    {
      "questionId": 14839,
      "userAnswer": 1,
      "correctAnswer": 3,
      "isCorrect": false
    }
  ]
}
```

---

### 4.3 Save Practice History
**POST** `/history/practice`

Save a practice question result to user's history.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:
```json
{
  "questionId": 14838,
  "userAnswer": 2,
  "isCorrect": true,
  "practiceType": "kanji",
  "level": 3
}
```

**Response** `200 OK`:
```json
{
  "message": "Practice history saved successfully"
}
```

---

### 4.4 Get Practice Summary
**GET** `/history/summary`

Get statistics and summary of practice history for charts and analytics.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response** `200 OK`:
```json
{
  "totalQuestions": 150,
  "correctAnswers": 120,
  "accuracy": 80.0,
  "byType": {
    "kanji": {
      "type": "kanji",
      "total": 50,
      "correct": 40,
      "accuracy": 80.0
    },
    "grammar": {
      "type": "grammar",
      "total": 50,
      "correct": 42,
      "accuracy": 84.0
    },
    "listening": {
      "type": "listening",
      "total": 25,
      "correct": 18,
      "accuracy": 72.0
    },
    "reading": {
      "type": "reading",
      "total": 25,
      "correct": 20,
      "accuracy": 80.0
    }
  },
  "byLevel": {
    "1": {
      "level": 1,
      "total": 20,
      "correct": 12,
      "accuracy": 60.0
    },
    "2": {
      "level": 2,
      "total": 30,
      "correct": 24,
      "accuracy": 80.0
    },
    "3": {
      "level": 3,
      "total": 100,
      "correct": 84,
      "accuracy": 84.0
    }
  }
}
```

---

## 5. Bookmarks APIs

### 5.1 Save Question Bookmark
**POST** `/bookmarks/questions`

Bookmark a question for later review.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:
```json
{
  "questionId": 14838,
  "note": "Need to review this kanji reading"
}
```

**Response** `200 OK`:
```json
{
  "message": "Question bookmarked successfully"
}
```

---

### 5.2 Get Question Bookmarks
**GET** `/bookmarks/questions`

Get all bookmarked questions.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "questionId": 14838,
    "question": "彼女は<u>色盲</u>になった。",
    "answers": ["しきかん", "いろがた", "しきもう", "いろかた"],
    "correctAnswer": 2,
    "note": "Need to review this kanji reading",
    "createdAt": "2026-01-08T12:00:00"
  }
]
```

---

### 5.3 Delete Question Bookmark
**DELETE** `/bookmarks/questions/{question_id}`

Remove a question from bookmarks.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Path Parameters**:
- `question_id`: The question ID

**Response** `200 OK`:
```json
{
  "message": "Bookmark deleted successfully"
}
```

---

### 5.4 Save Vocabulary Bookmark
**POST** `/bookmarks/vocabulary`

Bookmark a vocabulary word.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:
```json
{
  "word": "色盲",
  "reading": "しきもう",
  "meaning": "Color blindness",
  "level": 1,
  "note": "Important medical term"
}
```

**Response** `200 OK`:
```json
{
  "message": "Vocabulary bookmarked successfully"
}
```

---

### 5.5 Get Vocabulary Bookmarks
**GET** `/bookmarks/vocabulary`

Get all bookmarked vocabulary words.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "word": "色盲",
    "reading": "しきもう",
    "meaning": "Color blindness",
    "level": 1,
    "note": "Important medical term",
    "createdAt": "2026-01-08T12:00:00"
  }
]
```

---

### 5.6 Delete Vocabulary Bookmark
**DELETE** `/bookmarks/vocabulary/{bookmark_id}`

Remove a vocabulary bookmark.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Path Parameters**:
- `bookmark_id`: The bookmark ID

**Response** `200 OK`:
```json
{
  "message": "Bookmark deleted successfully"
}
```

---

### 5.7 Save Grammar Bookmark
**POST** `/bookmarks/grammar`

Bookmark a grammar pattern.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:
```json
{
  "pattern": "～ばかり",
  "meaning": "Just did; nothing but; only",
  "example": "買ったばかりの服を汚した",
  "level": 2,
  "note": "Commonly confused with だけ"
}
```

**Response** `200 OK`:
```json
{
  "message": "Grammar bookmarked successfully"
}
```

---

### 5.8 Get Grammar Bookmarks
**GET** `/bookmarks/grammar`

Get all bookmarked grammar patterns.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "pattern": "～ばかり",
    "meaning": "Just did; nothing but; only",
    "example": "買ったばかりの服を汚した",
    "level": 2,
    "note": "Commonly confused with だけ",
    "createdAt": "2026-01-08T12:00:00"
  }
]
```

---

### 5.9 Delete Grammar Bookmark
**DELETE** `/bookmarks/grammar/{bookmark_id}`

Remove a grammar bookmark.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Path Parameters**:
- `bookmark_id`: The bookmark ID

**Response** `200 OK`:
```json
{
  "message": "Bookmark deleted successfully"
}
```

---

## 6. Premium & Billing APIs

### 6.1 Get Billing Packages
**GET** `/billing/packages`

Get list of available premium subscription packages.

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "packageId": "premium_1month",
    "name": "Premium 1 Month",
    "durationDays": 30,
    "originalPrice": 99000,
    "salePercent": 0,
    "finalPrice": 99000,
    "description": "• Unlimited practice\n• Full exam access\n• No ads",
    "storeProductId": "com.vegax.jlpt.premium.1month"
  },
  {
    "id": 2,
    "packageId": "premium_6month",
    "name": "Premium 6 Months",
    "durationDays": 180,
    "originalPrice": 499000,
    "salePercent": 20,
    "finalPrice": 399000,
    "description": "• Save 20%\n• Unlimited practice\n• Full exam access\n• No ads",
    "storeProductId": "com.vegax.jlpt.premium.6month"
  },
  {
    "id": 3,
    "packageId": "premium_1year",
    "name": "Premium 1 Year",
    "durationDays": 365,
    "originalPrice": 899000,
    "salePercent": 35,
    "finalPrice": 584000,
    "description": "• Save 35%\n• Best value\n• Unlimited practice\n• Full exam access\n• No ads\n• Priority support",
    "storeProductId": "com.vegax.jlpt.premium.1year"
  }
]
```

**Price Format**:
- `originalPrice`: Original price in VND
- `salePercent`: Discount percentage (0-100)
- `finalPrice`: Final price after discount
- `storeProductId`: Corresponding product ID in App Store / Google Play

**Note**: This list is fixed and can be cached offline.

---

### 6.2 Get Subscription Status
**GET** `/user/subscription-status`

Check if current user is premium and expiration date.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response** `200 OK`:
```json
{
  "isPremium": true,
  "expireDate": "2026-07-08T12:00:00",
  "packageId": "premium_6month",
  "daysRemaining": 181
}
```

**Response** `200 OK` (Non-premium):
```json
{
  "isPremium": false,
  "expireDate": null,
  "packageId": null,
  "daysRemaining": null
}
```

---

## Error Responses

All APIs may return these common error responses:

### 400 Bad Request
```json
{
  "timestamp": "2026-01-08T12:00:00.000+00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation error message",
  "path": "/api/auth/register"
}
```

### 401 Unauthorized
```json
{
  "timestamp": "2026-01-08T12:00:00.000+00:00",
  "status": 401,
  "error": "Unauthorized",
  "message": "Invalid or expired token",
  "path": "/api/user/profile"
}
```

### 404 Not Found
```json
{
  "timestamp": "2026-01-08T12:00:00.000+00:00",
  "status": 404,
  "error": "Not Found",
  "message": "Resource not found",
  "path": "/api/exams/999"
}
```

### 500 Internal Server Error
```json
{
  "timestamp": "2026-01-08T12:00:00.000+00:00",
  "status": 500,
  "error": "Internal Server Error",
  "message": "An unexpected error occurred",
  "path": "/api/..."
}
```

---

## Authentication

Most APIs require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Public APIs** (no authentication required):
- POST `/auth/register`
- POST `/auth/login`
- GET `/practice/categories`
- GET `/billing/packages`
- GET `/exams` (list)
- GET `/exams/{id}` (detail)
- GET `/data/**` (media files)

**Protected APIs** (authentication required):
- GET `/user/profile`
- PUT `/user/profile`
- GET `/user/subscription-status`
- GET `/practice/questions`
- POST `/exams/submit`
- GET `/history/exams`
- GET `/history/exams/{result_id}`
- POST `/history/practice`
- GET `/history/summary`
- POST `/bookmarks/questions`
- GET `/bookmarks/questions`
- DELETE `/bookmarks/questions/{question_id}`
- POST `/bookmarks/vocabulary`
- GET `/bookmarks/vocabulary`
- DELETE `/bookmarks/vocabulary/{bookmark_id}`
- POST `/bookmarks/grammar`
- GET `/bookmarks/grammar`
- DELETE `/bookmarks/grammar/{bookmark_id}`
- GET `/mytest/config`
- GET `/mytest/questions`
- POST `/mytest/generate`
- GET `/mytest/questions/{id}/answer`

---

## 7. My Test APIs

Tính năng tự tạo đề thi theo dạng câu hỏi (Vocabulary, Grammar, Reading, Listening).

### 7.1 Get My Test Config
**GET** `/mytest/config?level={level}`

Lấy cấu hình các loại câu hỏi có sẵn cho một level JLPT cụ thể.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Query Parameters**:
- `level` (required): JLPT level (1-5 for N1-N5)

**Example Request**:
```
GET /mytest/config?level=3
```

**Response** `200 OK`:
```json
{
  "level": 3,
  "categories": [
    {
      "category": "VOCABULARY",
      "types": [
        {
          "id": 1,
          "key": "Cách đọc kanji",
          "name": "Cách đọc kanji",
          "level": 0,
          "numberQues": 150
        },
        {
          "id": 5,
          "key": "Cách viết từ",
          "name": "Cách đọc Hiragana",
          "level": 0,
          "numberQues": 120
        },
        {
          "id": 2,
          "key": "Thay đổi cách nói",
          "name": "Đồng nghĩa",
          "level": 2,
          "numberQues": 80
        }
      ]
    },
    {
      "category": "GRAMMAR",
      "types": [
        {
          "id": 7,
          "key": "Lựa chọn ngữ pháp",
          "name": "Dạng ngữ pháp",
          "level": 0,
          "numberQues": 200
        },
        {
          "id": 8,
          "key": "Lắp ghép câu",
          "name": "Thành lập câu",
          "level": 0,
          "numberQues": 100
        }
      ]
    },
    {
      "category": "READING",
      "types": [
        {
          "id": 10,
          "key": "Đoạn văn ngắn",
          "name": "Đoạn văn ngắn",
          "level": 0,
          "numberQues": 60
        }
      ]
    },
    {
      "category": "LISTENING",
      "types": [
        {
          "id": 16,
          "key": "Nghe hiểu chủ đề",
          "name": "Nghe hiểu chủ đề",
          "level": 0,
          "numberQues": 80
        }
      ]
    }
  ]
}
```

**Type Level Meaning**:
- `0`: Dễ
- `1`: Trung bình
- `2`: Khó
- `3`: Rất khó

---

### 7.2 Get My Test Questions
**GET** `/mytest/questions?level={level}&category={category}&typeId={typeId}&limit={limit}`

Lấy các câu hỏi ngẫu nhiên theo category và type.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Query Parameters**:
- `level` (required): JLPT level (1-5 for N1-N5)
- `category` (required): Category - VOCABULARY, GRAMMAR, READING, LISTENING
- `typeId` (optional): Type ID để lọc theo loại câu hỏi cụ thể
- `limit` (optional): Số câu hỏi (default: 20, max: 50)

**Example Request**:
```
GET /mytest/questions?level=3&category=VOCABULARY&typeId=1&limit=10
```

**Response** `200 OK`:
```json
[
  {
    "id": 12345,
    "question": "彼女は<u>色盲</u>になった。",
    "answers": ["しきかん", "いろがた", "しきもう", "いろかた"],
    "audio": null,
    "image": null,
    "txtRead": null,
    "groupTitle": "問題＿＿＿の読み方として最もよいものを...",
    "category": "VOCABULARY",
    "typeId": 1,
    "typeName": "Cách đọc kanji",
    "level": 3
  },
  {
    "id": 12346,
    "question": "この問題は<u>難解</u>です。",
    "answers": ["なんかい", "なんげ", "なんけ", "なんげい"],
    "audio": null,
    "image": null,
    "txtRead": null,
    "groupTitle": "問題＿＿＿の読み方として最もよいものを...",
    "category": "VOCABULARY",
    "typeId": 1,
    "typeName": "Cách đọc kanji",
    "level": 3
  }
]
```

**Note**:
- Correct answer is NOT included (use `/mytest/questions/{id}/answer` to check)
- Questions are randomly selected
- For LISTENING category, `audio` field contains the file path

---

### 7.3 Generate Custom Test
**POST** `/mytest/generate`

Tạo một đề thi tùy chỉnh với các loại câu hỏi và số lượng cụ thể.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:
```json
{
  "level": 3,
  "categories": [
    {
      "category": "VOCABULARY",
      "types": [
        { "typeId": 1, "count": 10 },
        { "typeId": 2, "count": 5 }
      ]
    },
    {
      "category": "GRAMMAR",
      "types": [
        { "typeId": 7, "count": 10 },
        { "typeId": 8, "count": 5 }
      ]
    },
    {
      "category": "LISTENING",
      "types": [
        { "typeId": 16, "count": 5 }
      ]
    }
  ]
}
```

**Response** `200 OK`:
```json
{
  "totalQuestions": 35,
  "categories": {
    "VOCABULARY": [
      {
        "id": 12345,
        "question": "彼女は<u>色盲</u>になった。",
        "answers": ["しきかん", "いろがた", "しきもう", "いろかた"],
        "audio": null,
        "image": null,
        "txtRead": null,
        "groupTitle": "...",
        "category": "VOCABULARY",
        "typeId": 1,
        "typeName": "Cách đọc kanji",
        "level": 3
      }
    ],
    "GRAMMAR": [
      {
        "id": 23456,
        "question": "...",
        "answers": ["...", "...", "...", "..."],
        "audio": null,
        "image": null,
        "txtRead": null,
        "groupTitle": "...",
        "category": "GRAMMAR",
        "typeId": 7,
        "typeName": "Dạng ngữ pháp",
        "level": 3
      }
    ],
    "LISTENING": [
      {
        "id": 34567,
        "question": "...",
        "answers": ["...", "...", "...", "..."],
        "audio": "/data/audio/26/xxx.mp3",
        "image": null,
        "txtRead": null,
        "groupTitle": "...",
        "category": "LISTENING",
        "typeId": 16,
        "typeName": "Nghe hiểu chủ đề",
        "level": 3
      }
    ]
  }
}
```

---

### 7.4 Get Question Answer
**GET** `/mytest/questions/{id}/answer`

Lấy đáp án và giải thích cho một câu hỏi cụ thể.

**Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Path Parameters**:
- `id`: Question ID

**Example Request**:
```
GET /mytest/questions/12345/answer
```

**Response** `200 OK`:
```json
{
  "id": 12345,
  "question": "彼女は<u>色盲</u>になった。",
  "answers": ["しきかん", "いろがた", "しきもう", "いろかた"],
  "correctAnswer": 2,
  "audio": null,
  "image": null,
  "txtRead": null,
  "groupTitle": "問題＿＿＿の読み方として最もよいものを...",
  "explain": "色盲（しきもう）は色を識別できない状態...",
  "explainEn": "Color blindness is a condition...",
  "explainVn": "Mù màu là tình trạng không thể phân biệt màu sắc...",
  "explainCn": "色盲是一种无法识别颜色的状况...",
  "category": "VOCABULARY",
  "typeId": 1,
  "typeName": "Cách đọc kanji",
  "level": 3
}
```

**Note**: `correctAnswer` là index của đáp án đúng (0-3 tương ứng với answer 1-4)

---

### 7.5 Question Type Reference

| Type ID | Category | Key | Name |
|---------|----------|-----|------|
| 1 | VOCABULARY | Cách đọc kanji | Cách đọc kanji |
| 2 | VOCABULARY | Thay đổi cách nói | Đồng nghĩa |
| 3 | VOCABULARY | Điền từ theo văn cảnh | Biểu hiện từ |
| 4 | VOCABULARY | Ứng dụng từ | Cách dùng từ |
| 5 | VOCABULARY | Cách viết từ | Cách đọc Hiragana |
| 6 | VOCABULARY | Hình thành từ | Cấu tạo từ |
| 7 | GRAMMAR | Lựa chọn ngữ pháp | Dạng ngữ pháp |
| 8 | GRAMMAR | Lắp ghép câu | Thành lập câu |
| 9 | GRAMMAR | Ngữ pháp theo đoạn văn | Ngữ pháp theo đoạn văn |
| 10 | READING | Đoạn văn ngắn | Đoạn văn ngắn |
| 11 | READING | Đoạn văn vừa | Đoạn văn trung bình |
| 12 | READING | Đoạn văn dài | Đoạn văn dài |
| 13 | READING | Đọc hiểu tổng hợp | Đọc hiểu tổng hợp |
| 14 | READING | Đọc hiểu chủ đề | Đọc hiểu chủ đề |
| 15 | READING | Tìm thông tin | Tìm thông tin |
| 16 | LISTENING | Nghe hiểu chủ đề | Nghe hiểu chủ đề |
| 17 | LISTENING | Nghe hiểu điểm chính | Nghe hiểu điểm chính |
| 18 | LISTENING | Nghe hiểu khái quát | Nghe hiểu khái quát |
| 19 | LISTENING | Trả lời nhanh | Trả lời nhanh |
| 20 | LISTENING | Nghe hiểu tổng hợp | Nghe hiểu tổng hợp |
| 21 | LISTENING | Nghe hiểu diễn đạt | Nghe hiểu diễn đạt |

---

## Media Files

Audio and image files can be accessed via:

```
https://8e23deb9e9e2.ngrok-free.app/data/audio/{folder}/{filename}.mp3
https://8e23deb9e9e2.ngrok-free.app/data/images/{folder}/{filename}.png
```

Example:
```
https://8e23deb9e9e2.ngrok-free.app/data/audio/26/23526_092020_audio_N3_NHCD_q94.mp3
```

The file paths are included in the API responses (e.g., in exam questions).
