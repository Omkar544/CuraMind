from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime, timezone
import os

# =========================================
# CONFIGURATION
# =========================================

MONGO_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DB_NAME = "curamind_lifelog"


class MongoStorage:
    _client = MongoClient(MONGO_URI)
    _db = _client[DB_NAME]

    # Collections
    _reports = _db["module_reports"]
    _medicines = _db["medicine_alerts"]
    _appointments = _db["appointments"]

    # =========================================
    # SAVE AI MODULE REPORT (DailyMoves, MindEase, Vision)
    # =========================================
    @classmethod
    def save_report(
        cls,
        user_id: str,
        module_name: str,
        input_data: dict,
        prediction: str,
        timestamp: datetime = None
    ):
        """
        Stores AI module results into MongoDB.
        Supports optional custom timestamp.
        """

        # ✅ Always use timezone-aware UTC
        if timestamp is None:
            timestamp = datetime.now(timezone.utc)

        report_document = {
            "user_id": user_id,
            "module": module_name,
            "timestamp": timestamp,
            "inputs": input_data,
            "result": prediction
        }

        result = cls._reports.insert_one(report_document)
        print(f"✅ MongoDB: Saved {module_name} report for {user_id}")

        return str(result.inserted_id)

    # =========================================
    # SAVE CARECLOCK ITEM (Medicine / Appointment)
    # =========================================
    @classmethod
    def save_careclock_item(cls, user_id: str, item_type: str, data: dict):
        """
        Stores Medicine or Appointment alerts into MongoDB.
        """

        data["user_id"] = user_id

        # ✅ FIXED → timezone-aware UTC
        data["timestamp"] = datetime.now(timezone.utc)

        target_col = cls._medicines if item_type == "medicine" else cls._appointments
        result = target_col.insert_one(data)

        print(f"✅ MongoDB: Saved {item_type} for {user_id}")
        return str(result.inserted_id)

    # =========================================
    # GET FULL LIFELOG DATA
    # =========================================
    @classmethod
    def get_full_lifelog(cls, user_id: str):
        """
        Aggregates AI reports, medicines, and appointments
        for the LifeLog Hub screen.
        """

        ai_reports = list(
            cls._reports.find({"user_id": user_id}).sort("timestamp", -1)
        )

        meds = list(
            cls._medicines.find({"user_id": user_id}).sort("timestamp", -1)
        )

        apps = list(
            cls._appointments.find({"user_id": user_id}).sort("timestamp", -1)
        )

        return {
            "ai_reports": ai_reports,
            "medicine_alerts": meds,
            "appointments": apps
        }

    # =========================================
    # GET CARECLOCK ALERTS
    # =========================================
    @classmethod
    def get_careclock_alerts(cls, user_id: str):
        appointments = list(cls._appointments.find({"user_id": user_id}))
        medicines = list(cls._medicines.find({"user_id": user_id}))
        return {"appointments": appointments, "medicines": medicines}

    # =========================================
    # UPDATE DOCUMENT
    # =========================================
    @classmethod
    def update_document(cls, collection_name: str, doc_id: str, update_data: dict):
        try:
            collection = cls._db[collection_name]

            if "_id" in update_data:
                del update_data["_id"]

            result = collection.update_one(
                {"_id": ObjectId(doc_id)},
                {
                    "$set": {
                        **update_data,
                        # ✅ FIXED → timezone-aware UTC
                        "updated_at": datetime.now(timezone.utc)
                    }
                }
            )

            return result.modified_count > 0 or result.matched_count > 0

        except Exception as e:
            print(f"❌ MongoStorage Update Error: {e}")
            return False

    # =========================================
    # DELETE DOCUMENT
    # =========================================
    @classmethod
    def delete_document(cls, collection_name: str, doc_id: str, user_id: str):
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