import os

from fastapi import FastAPI

app = FastAPI()

APP_ENV = os.getenv("APP_ENV", "development")


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/version")
def version():
    return {
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "environment": APP_ENV,
    }
