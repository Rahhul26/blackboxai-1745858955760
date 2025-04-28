from fastapi import FastAPI, UploadFile, File, Form, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import firebase_admin
from firebase_admin import auth, credentials
import shutil
import os

from backend.ml_model import load_model, predict_calories

app = FastAPI()

# Allow CORS for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase Admin SDK
cred = credentials.Certificate("backend/firebase_service_account.json")
firebase_admin.initialize_app(cred)

# Firebase authentication dependency
async def get_current_user(token: str = Form(...)):
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        return {"user_id": uid}
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")

class MealDetails(BaseModel):
    description: Optional[str] = None
    calories: Optional[float] = None

@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...), user: dict = Depends(get_current_user)):
    """
    Endpoint to receive food image for calorie detection.
    """
    # Save uploaded file temporarily
    temp_dir = "backend/temp_images"
    os.makedirs(temp_dir, exist_ok=True)
    file_path = os.path.join(temp_dir, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Load model and predict calories
    model = load_model()
    calories_estimated = predict_calories(file_path)

    # Optionally delete the temp file after prediction
    os.remove(file_path)

    return {"filename": file.filename, "user": user, "calories_estimated": calories_estimated}

@app.post("/submit-meal/")
async def submit_meal(meal: MealDetails, user: dict = Depends(get_current_user)):
    """
    Endpoint to receive manual meal details.
    """
    # TODO: Store meal details, provide diet recommendation
    return {"meal": meal, "user": user, "recommendation": "Suitable for your diet"}

@app.get("/")
async def root():
    return {"message": "Food Calorie Detector Backend is running"}
