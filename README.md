**CuraMind: Mindful Healing, Meaningful Living**



A full-stack, AI-powered holistic wellness platform built with Flutter and FastAPI. This project integrates mental health assessments (PHQ-9, GAD-7), fitness tracking, an AI chatbot, and an XAI-powered report generator into a single, user-friendly application.



&nbsp;**About The Project**



In today's fast-paced lifestyle, individuals often struggle to balance mental health, physical fitness, and overall well-being. Challenges like stress, anxiety, lack of activity monitoring, and difficulty understanding complex health reports prevent people from making timely, informed decisions.



CuraMind is a holistic digital health platform designed to address these issues. It integrates multiple supportive modules into one application, leveraging Artificial Intelligence and Data Science to deliver preventive care, early detection of health risks, and actionable lifestyle insights.



**Built With**



Frontend: Flutter \& Dart



Backend: Python 3.9+ \& FastAPI



Databases: PostgreSQL (for users) \& MongoDB (for reports/logs)



AI/ML: XGBoost, Scikit-learn, Transformers (Hugging Face), VaderSentiment



XAI: SHAP, ELI5



RPA/Automation: UiPath (for the LifeLog report generation process)



Chatbot: Botpress (integrated via WebView)



**Features**



CuraMind is built around five core modules to provide comprehensive support:



🧠 MindEase (Mental Health):



Guides users through standardized assessments (PHQ-9 for depression, GAD-7 for anxiety).



Features an intelligent journaling system with deep sentiment analysis (via FastAPI) to track mood trends.



🤖 TalkBuddy (AI Chatbot):



Integrates a Botpress web-based chatbot to provide interactive, 24/7 AI-driven conversations for support and guidance.



🏃 DailyMoves (Fitness Tracker):



Tracks daily physical activities (steps, exercise duration, intensity).



Uses a 99% accurate XGBoost model to predict a user's categorical health condition (e.g., At-Risk, Fit, Unfit) based on 12 key biometric and lifestyle features.



📄 LifeLog (Report Generation):



Provides a consolidated dashboard of all user reports.



Generates Explainable AI (XAI) reports (using SHAP/ELI5) to show users why the AI reached a fitness conclusion.



Uses UiPath automation to structure and compile user data from various modules into comprehensive progress reports.



Includes a text summarization feature (using T5/Pegasus models) for simplifying uploaded medical reports.



⏰ CareClock (Scheduler):



Manages medication reminders and appointment scheduling to ensure adherence to treatment plans.

