from fastapi import APIRouter, HTTPException, status, Query
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from ..services.mongo_storage import MongoStorage

router = APIRouter()

# --- Data Models ---

class CareClockItem(BaseModel):
    user_id: str
    type: str  # 'appointment' or 'medicine'
    alert_enabled: bool = True
    timestamp_ref: Optional[str] = None
    
    # Appointment specific fields
    doctor_name: Optional[str] = None
    specialty: Optional[str] = None
    date: Optional[str] = None
    
    # Medicine specific fields
    medicine_name: Optional[str] = None
    dosage: Optional[str] = None
    
    # Shared field (Visit Time or Alarm Time)
    time: str

# --- Endpoints ---

@router.post("/save", status_code=status.HTTP_201_CREATED)
async def save_care_item(item: CareClockItem):
    """
    Saves a new schedule (Appointment or Medicine) to MongoDB.
    FIXED: Uses 'item_type' parameter to match MongoStorage class method.
    """
    try:
        # We store the data in the appropriate collection based on type
        # Changed 'type=item.type' to 'item_type=item.type' to fix the 500 error
        doc_id = MongoStorage.save_careclock_item(
            user_id=item.user_id,
            item_type=item.type,
            data=item.dict()
        )
        print(f"✅ CareClock: New {item.type} saved for User {item.user_id}")
        return {"status": "success", "id": doc_id}
    except Exception as e:
        print(f"❌ CareClock Save Error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@router.post("/update/{doc_id}")
async def update_care_item(doc_id: str, item: CareClockItem):
    """
    Updates an existing schedule in MongoDB using its document ID.
    """
    try:
        # Determine collection name based on type
        collection = "appointments" if item.type == "appointment" else "medicine_alerts"
        
        # update_document logic in MongoStorage handles ObjectId conversion
        success = MongoStorage.update_document(
            collection_name=collection,
            doc_id=doc_id,
            update_data=item.dict()
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Schedule record not found or no changes made")
            
        print(f"🔄 CareClock: {item.type} updated [ID: {doc_id}]")
        return {"status": "success", "message": "Schedule updated successfully"}
    except Exception as e:
        print(f"❌ CareClock Update Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/history/{user_id}")
async def get_care_history(user_id: str):
    """
    Fetches all combined history for the CareClock screen and LifeLog Hub.
    """
    try:
        results = MongoStorage.get_careclock_alerts(user_id)
        
        # Helper to stringify Mongo ObjectIds for JSON compatibility
        def prepare_list(items):
            for item in items:
                if "_id" in item:
                    item["_id"] = str(item["_id"])
            return items

        return {
            "medicines": prepare_list(results.get("medicines", [])),
            "appointments": prepare_list(results.get("appointments", []))
        }
    except Exception as e:
        print(f"❌ CareClock History Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch history")

@router.delete("/delete/{doc_id}")
async def delete_care_item(doc_id: str, user_id: str = Query(...)):
    """
    Deletes a specific record from either collection.
    """
    try:
        deleted = False
        # Loop through both collections to find and delete the doc
        for coll in ["medicine_alerts", "appointments"]:
            if MongoStorage.delete_document(coll, doc_id, user_id):
                deleted = True
                break
        
        if not deleted:
            raise HTTPException(status_code=404, detail="Record not found or unauthorized")
            
        print(f"🗑️ CareClock: Record {doc_id} deleted by User {user_id}")
        return {"status": "success", "message": "Record removed from schedule"}
    except Exception as e:
        print(f"❌ CareClock Delete Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))