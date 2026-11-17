# System Architecture Document — Home Energy Coach

**Course:** High Integrity Systems (WS 2026/27) — Frankfurt University of Applied Sciences  
**Supervisor:** Prof. Dr. Christina Andersson  
**Authors:** Madhusudan Ambulkar, Zafar, Newaz  
**Sprint:** Sprint 2 (Architecture & Modelling)

---

## 1. Architectural Overview & Layered Design

The **Home Energy Coach** employs a decoupled, four-tier client-server architecture designed for high integrity, strict separation of concerns, and green software efficiency:

1. **Presentation Layer (Native iOS Client — SwiftUI):** Handles student onboarding, 168-bit weekly schedule configuration, personalized habit recommendation cards, and daily check-in interactions. Communicates exclusively over HTTPS/JSON with the API Gateway.
2. **Application & API Gateway Layer (Python FastAPI):** Acts as the central orchestrator, authentication boundary, request validator (Pydantic schemas), and asynchronous job scheduler. Isolates the iOS client from direct database access and R microservice internals.
3. **Persistence Layer (PostgreSQL):** Relational source of truth storing normalized user household profiles (`users`), habit catalogs (`habits`), user commitments (`commitments`), longitudinal check-ins (`checkins`), cached SMARD grid intensity series (`grid_intensity`), and precomputed recommendation scores (`recommendations`).
4. **Analytical & ML Microservice Layer (Containerized R + `plumber`):** Executes statistical clustering, association rule mining, collaborative filtering, and external SMARD grid ingestion.

---

## 2. Core Architectural Constraints & Design Justifications

### 2.1 Strict Separation of `plumber` Transport vs. Domain R Packages
Per supervisor architectural review, **`plumber` is restricted strictly to REST endpoint routing, HTTP request parsing, and JSON serialization**. No statistical, data-wrangling, or machine learning logic is permitted inside `plumber.R` endpoint definitions. All analytical execution is encapsulated within modular, unit-tested internal R scripts and specialized CRAN packages:
* **Data Ingestion & Wrangling:** `dplyr`, `tidyr`, `lubridate`, `httr2` / `bunddev` (Bundesnetzagentur SMARD API Filter 1223).
* **Household Segmentation:** `cluster`, `factoextra` (k-means / PAM clustering on household demand, heating type, and 168-bit schedule availability).
* **Habit Recommendation & Pattern Mining:** `recommenderlab` (collaborative filtering on check-in histories) and `arules` (frequent habit co-adoption rules).
* **Statistical Calibration:** `stats` ($\text{CO}_2$ savings estimation anchored to UBA $344\text{ g CO}_2/\text{kWh}$ and Stromspiegel 2025 baselines).

### 2.2 Green Software Engineering: Scheduled Nightly Batch Execution
Rather than running computationally expensive ML training and recommendation scoring synchronously on every mobile API request, the system enforces an **asynchronous nightly batch execution pattern**:
* **Low-Carbon Compute Alignment:** Scheduled jobs trigger during off-peak overnight windows (e.g., `02:00 CET`), avoiding daytime peak grid load and minimizing idle container CPU wake-ups.
* **Sub-50ms Mobile Latency:** During daytime usage, the iOS app reads precomputed, ranked habit recommendations directly from PostgreSQL via FastAPI without invoking R compute.
* **Fault Isolation:** If the R analytics container experiences a transient SMARD API timeout, the iOS client degrades gracefully by serving the previous night's cached recommendations from PostgreSQL.

---

## 3. Component Summary

| Layer | Technology | Primary Responsibilities |
| :--- | :--- | :--- |
| **Mobile Client** | SwiftUI (iOS) | Onboarding form, schedule picker, habit feed, daily check-in logging |
| **Backend API** | Python FastAPI | JWT auth, CRUD endpoints, Pydantic validation, nightly cron trigger |
| **Database** | PostgreSQL 16 | ACID persistence for user profiles, check-ins, SMARD cache, ML outputs |
| **Analytics Service** | R 4.6.2 + `plumber` (Docker) | Thin HTTP wrapper invoking batch R pipelines (`cluster`, `recommenderlab`, `arules`) |
| **External Data** | SMARD REST API | Hourly German electricity generation mix (Filter 1223) |

---

## 4. UML Modelling Artifacts

All source diagrams are maintained as version-controlled PlantUML files under `docs/uml/`:
* `01_use_case.puml` — Student, Backend Scheduler, and External SMARD API interactions.
* `02_class_diagram.puml` — Domain entities (`User`, `Habit`, `Commitment`, `CheckIn`, `GridIntensity`, `Recommendation`) and R service boundary.
* `03_activity_diagram.puml` — End-to-end onboarding, nightly batch recommendation pipeline, and daily check-in workflow.
* `04_sequence_diagram.puml` — Synchronous mobile check-in flow vs. asynchronous nightly batch ML execution flow.