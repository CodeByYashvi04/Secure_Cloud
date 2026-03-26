from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
import datetime
import uvicorn

app = FastAPI(title="CloudSecure AI Engine")

# --- Models ---
class AuditLog(BaseModel):
    userId: str
    service: str
    action: str
    ipAddress: str
    timestamp: Optional[str] = None

class BatchLogs(BaseModel):
    logs: List[AuditLog]

# --- AI Logic ---
# In a real app, this would be pre-trained or incrementally trained.
# For this project, we'll use a pre-fit model or fit on the fly for demonstration.
model = IsolationForest(contamination=0.1, random_state=42)

def prepare_data(logs: List[AuditLog]):
    # Convert logs to a numeric format for Isolation Forest
    # We can use simple label encoding for service/action and IP parts
    data = []
    for log in logs:
        # Simple feature engineering
        service_id = hash(log.service) % 100
        action_id = hash(log.action) % 100
        # IP to numeric (simple version)
        ip_parts = log.ipAddress.split('.')
        ip_sum = sum(int(p) for p in ip_parts) if len(ip_parts) == 4 else 0
        
        data.append([service_id, action_id, ip_sum])
    
    return np.array(data)

@app.post("/analyze")
async def analyze_logs(batch: BatchLogs):
    if not batch.logs:
        return {"riskScore": 0, "anomalies": []}
    
    X = prepare_data(batch.logs)
    
    # Fit/Predict
    if len(X) < 5:
        # Not enough data for a robust forest, use heuristic
        scores = [0] * len(X)
    else:
        model.fit(X)
        # decision_function returns lower values for anomalies
        raw_scores = model.decision_function(X)
        # Normalize to 0-100 (where 100 is high risk)
        # IsolationForest decision_function is roughly between -0.5 and 0.5
        scores = [int((0.5 - s) * 100) for s in raw_scores]
        scores = [max(0, min(100, s)) for s in scores]

    results = []
    for i, log in enumerate(batch.logs):
        results.append({
            "log": log,
            "riskScore": scores[i],
            "isAnomaly": scores[i] > 70
        })

    # Return aggregate stats
    avg_risk = int(sum(scores) / len(scores))
    return {
        "status": "success",
        "averageRiskScore": avg_risk,
        "results": results
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "model": "IsolationForest"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
