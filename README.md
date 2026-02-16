# SafePlate — AI-Powered Food Safety Assistant 🥗

SafePlate helps people with food allergies feel confident when eating out. Take a photo of a restaurant menu, tell SafePlate what allergens you want to avoid, and it returns **safe**, **unsafe**, and **modifiable** dish recommendations—plus brief explanations.

**Hackathon project (TIDALHACK:26)**  
**Devpost:** https://devpost.com/software/safeplate-8fznlt  

---

## Why SafePlate?

Dining out can be stressful when menus don’t clearly list ingredients or hidden allergens. SafePlate uses vision + LLM reasoning to make menus easier to understand and safer to navigate.

---

## What it does

- 📸 **Upload/scan a menu image**
- 🔎 **Extract dishes from the menu image**
- 🧠 **Generate ingredient lists**
- 🚫 **Filter based on allergens you want to avoid**
- 🏷️ **Classify dishes** into:
  - **SAFE** (no allergen detected)
  - **UNSAFE** (contains allergen)
  - **MODIFIABLE** (can be customized to remove/substitute allergen)

---

## System overview

**Flow (high level):**

`Menu Image → Dish Extraction (Vision) → Ingredients + Safety (LLM) → Safe/Unsafe/Modifiable Results`

### Architecture (serverless)
- Client sends menu image as **Base64** (HTTP POST)
- **API Gateway** receives request
- **AWS Lambda**:
  1) decodes image  
  2) calls **Amazon Bedrock (Claude Vision)** to extract dish names  
  3) calls **Amazon Bedrock (Claude)** per dish to return ingredients + safety classification  
  4) returns a structured JSON response

---

## Tech stack

- **AWS Lambda** (serverless backend)
- **Amazon API Gateway** (REST endpoint)
- **Amazon Bedrock** (Claude models)
  - Claude **3.5 Sonnet (Vision)** for dish extraction
  - Claude **3 Haiku** for ingredients + allergen safety
- **Python + boto3**
- **Base64** image transport
- **Flutter** (mobile UI)

