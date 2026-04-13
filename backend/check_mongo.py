import os
from pymongo import MongoClient
from bson import json_util
import json

# --- CONFIGURATION ---
MONGO_URI = "mongodb://localhost:27017"
DB_NAME = "curamind_lifelog"

def check_data():
    try:
        client = MongoClient(MONGO_URI)
        db = client[DB_NAME]
        
        print("="*60)
        print(f"CURAMIND MONGODB DATA VIEWER")
        print("="*60)

        # 1. Check Module Reports (Fitness & Mental Health)
        print(f"\n[1] COLLECTION: module_reports")
        reports = list(db.module_reports.find())
        if not reports:
            print(" -> No reports found.")
        else:
            for i, report in enumerate(reports, 1):
                print(f"\n--- Report #{i} ---")
                print(f"User ID:   {report.get('user_id')}")
                print(f"Module:    {report.get('module')}")
                print(f"Result:    {report.get('result')}")
                print(f"Timestamp: {report.get('timestamp')}")
                print(f"Inputs:    {report.get('inputs')}")

        # 2. Check Appointments
        print(f"\n[2] COLLECTION: appointments")
        appointments = list(db.appointments.find())
        if not appointments:
            print(" -> No appointments found.")
        else:
            for i, appt in enumerate(appointments, 1):
                print(f" - Doc: {appt.get('doctor_name')} | Date: {appt.get('date')} | Time: {appt.get('time')}")

        # 3. Check Medicines
        print(f"\n[3] COLLECTION: medicine_alerts")
        meds = list(db.medicine_alerts.find())
        if not meds:
            print(" -> No medicines found.")
        else:
            for i, med in enumerate(meds, 1):
                print(f" - Med: {med.get('medicine_name')} | Time: {med.get('time')}")

        print("\n" + "="*60)
        client.close()

    except Exception as e:
        print(f"❌ Connection Error: {e}")

if __name__ == "__main__":
    check_data()