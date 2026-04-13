from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime
import os

# --- CONFIGURATION ---
# Loads the URI from environment variables or defaults to the local instance
MONGO_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DB_NAME = "curamind_lifelog"

class MongoStorage:
    _client = MongoClient(MONGO_URI)
    _db = _client[DB_NAME]

    # Pre-defining collections for internal use and better performance
    _reports = _db["module_reports"]
    _medicines = _db["medicine_alerts"]
    _appointments = _db["appointments"]

    @classmethod
    def save_report(cls, user_id: str, module_name: str, input_data: dict, prediction: str):
        """
        Stores AI module results (Daily Moves, MindEase) into MongoDB module_reports collection.
        This is used by the ML assessment routers.
        """
        report_document = {
            "user_id": user_id,
            "module": module_name,
            "timestamp": datetime.utcnow(),
            "inputs": input_data,
            "result": prediction
        }
        result = cls._reports.insert_one(report_document)
        print(f"✅ MongoDB: Saved {module_name} report for {user_id}")
        return str(result.inserted_id)

    @classmethod
    def save_careclock_item(cls, user_id: str, item_type: str, data: dict):
        """
        Stores Medicine or Appointment alerts into MongoDB.
        Uses separate collections to keep data clean.
        """
        data["user_id"] = user_id
        data["timestamp"] = datetime.utcnow()
        
        # Select target collection based on type string
        target_col = cls._medicines if item_type == "medicine" else cls._appointments
        result = target_col.insert_one(data)
        
        print(f"✅ MongoDB: Saved {item_type} for {user_id}")
        return str(result.inserted_id)

    @classmethod
    def get_full_lifelog(cls, user_id: str):
        """
        Aggregates AI reports, medicines, and appointments for the LifeLog Hub screen.
        Fixes potential AttributeErrors by providing a unified fetch method.
        """
        ai_reports = list(cls._reports.find({"user_id": user_id}).sort("timestamp", -1))
        meds = list(cls._medicines.find({"user_id": user_id}).sort("timestamp", -1))
        apps = list(cls._appointments.find({"user_id": user_id}).sort("timestamp", -1))
        
        return {
            "ai_reports": ai_reports,
            "medicine_alerts": meds,
            "appointments": apps
        }

    @classmethod
    def get_careclock_alerts(cls, user_id: str):
        """Fetches active alerts specifically for history views."""
        appointments = list(cls._appointments.find({"user_id": user_id}))
        medicines = list(cls._medicines.find({"user_id": user_id}))
        return {"appointments": appointments, "medicines": medicines}

    @classmethod
    def update_document(cls, collection_name: str, doc_id: str, update_data: dict):
        """
        General update method used by the CareClock update endpoint.
        Handles ID conversion and ensures the _id field isn't overwritten.
        """
        try:
            collection = cls._db[collection_name]
            # Prevent overwriting the immutable _id field
            if "_id" in update_data:
                del update_data["_id"]
            
            result = collection.update_one(
                {"_id": ObjectId(doc_id)},
                {"$set": {**update_data, "updated_at": datetime.utcnow()}}
            )
            return result.modified_count > 0 or result.matched_count > 0
        except Exception as e:
            print(f"❌ MongoStorage Update Error: {e}")
            return False

    @classmethod
    def delete_document(cls, collection_name: str, doc_id: str, user_id: str):
        """
        Deletes a specific document while ensuring the requesting user owns it.
        """
        try:
            collection = cls._db[collection_name]
            result = collection.delete_one({
                "_id": ObjectId(doc_id), 
                "user_id": user_id
            })
            return result.deleted_count > 0
        except Exception as e:
            print(f"❌ MongoStorage Delete Error: {e}")
            return False