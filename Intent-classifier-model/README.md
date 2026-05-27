# Intent Classifier Model

This project is a small end-to-end demo of a text classification workflow.

It shows how to:
- train a simple intent classification model,
- save the trained model as a file,
- load that model in a Flask API,
- send text to the API and get a predicted intent back.

The repo is intentionally small, so it is useful for understanding the basic MLOps flow before moving to larger projects.

## What this demo does

The model learns from a tiny in-code dataset:
- `hi` -> `greeting`
- `hello` -> `greeting`
- `how to reset password` -> `question`
- `cancel my subscription` -> `complaint`
- `great service` -> `praise`

After training, the model is saved to `model/artifacts/intent_model.pkl`.

Then the Flask app loads that file and exposes two endpoints:
- `/health` for a simple health check
- `/predict` for intent prediction

## Project structure

```text
Intent-classifier-model/
|-- app.py
|-- wsgi.py
|-- requirements.txt
|-- README.md
`-- model/
        |-- intent_model.py
        |-- train.py
        `-- artifacts/
                `-- intent_model.pkl   # created after training
```

## Files explained

### `model/train.py`
This script:
- creates a tiny sample dataset,
- builds a Scikit-learn pipeline,
- trains the classifier,
- saves the trained model to disk.

### `model/intent_model.py`
This file defines the `IntentModel` class. It loads the saved model file and provides a `predict()` method.

### `app.py`
This is the Flask application. It:
- loads the trained model,
- exposes `/health`,
- exposes `/predict`.

### `wsgi.py`
This is a production-style entrypoint that exposes the Flask app as `application`.

## Step-by-step demo

## Step 1: Open a terminal in this folder

Move into the project directory:

```powershell
cd "c:\Users\PN017156\Downloads\Courses\MLOPs-Zero-To-Hero\Intent-classifier-model"
```

## Step 2: Create a virtual environment

On Windows PowerShell:

```powershell
python -m venv .venv
```

Activate it:

```powershell
.\.venv\Scripts\Activate.ps1
```

If activation is blocked, run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\.venv\Scripts\Activate.ps1
```

## Step 3: Install dependencies

```powershell
pip install -r requirements.txt
```

This installs:
- Flask for the API
- scikit-learn for the model
- joblib for saving/loading the model
- pytest for testing
- gunicorn for deployment-style serving

## Step 4: Train the model

Run:

```powershell
python model\train.py
```

Expected output:

```text
trained
```

What happens in this step:
1. A very small text dataset is created directly inside the script.
2. A `CountVectorizer` converts text into numeric features.
3. A `MultinomialNB` classifier is trained.
4. The trained pipeline is saved to `model/artifacts/intent_model.pkl`.

Why this step is important:

The API depends on the saved file. If you start the Flask app before training, the app will fail because the model file does not exist yet.

## Step 5: Start the Flask API

Run:

```powershell
python app.py
```

The app starts on:

```text
http://127.0.0.1:6000
```

## Step 6: Check the health endpoint

Open another terminal and run:

```powershell
Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:6000/health"
```

Expected response:

```json
{
    "status": "ok"
}
```

This confirms that the Flask service is running.

## Step 7: Send a prediction request

Use PowerShell:

```powershell
$body = @{ text = "I want to cancel my subscription" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:6000/predict" -ContentType "application/json" -Body $body
```

Expected response:

```json
{
    "intent": "complaint"
}
```

## Step 8: Try more sample inputs

You can test a few more examples:

```powershell
$body = @{ text = "hello" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:6000/predict" -ContentType "application/json" -Body $body
```

Expected:

```json
{
    "intent": "greeting"
}
```

```powershell
$body = @{ text = "how to reset password" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:6000/predict" -ContentType "application/json" -Body $body
```

Expected:

```json
{
    "intent": "question"
}
```

```powershell
$body = @{ text = "great service" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:6000/predict" -ContentType "application/json" -Body $body
```

Expected:

```json
{
    "intent": "praise"
}
```

## Request and response format

### Request body

```json
{
    "text": "I want to cancel my subscription"
}
```

### Response body

```json
{
    "intent": "complaint"
}
```

Important note:

The current API returns only the predicted intent. It does not return class probabilities.

## Demo flow in simple words

This is the full sequence:
1. You train a model from sample text.
2. The trained model is saved as a `.pkl` file.
3. Flask loads that `.pkl` file when the app starts.
4. You send JSON text to `/predict`.
5. The API returns the predicted intent.

## How the prediction works internally

When you send text such as `I want to cancel my subscription`:
1. Flask receives the request.
2. `app.py` extracts the `text` field from JSON.
3. `IntentModel.predict()` sends that text to the trained Scikit-learn pipeline.
4. The pipeline vectorizes the text.
5. The Naive Bayes classifier predicts the most likely label.
6. The API returns that label as JSON.

## If you want to use curl on Windows

In PowerShell, `curl` is often an alias for `Invoke-WebRequest`, which uses different syntax.

If you want real curl syntax, use `curl.exe` instead:

```powershell
curl.exe -X POST "http://127.0.0.1:6000/predict" -H "Content-Type: application/json" -d '{"text":"I want to cancel my subscription"}'
```

## Common issues

### Error: model file not found

Cause:
You started the API before running training.

Fix:

```powershell
python model\train.py
```

### PowerShell `curl` command fails

Cause:
PowerShell maps `curl` to `Invoke-WebRequest`.

Fix:
Use either `Invoke-RestMethod` or `curl.exe`.

### Wrong prediction for new text

Cause:
The training data is extremely small. This project is only a learning demo, not a production-quality classifier.

## Why this repo is useful for learning

This repo is a good beginner demo because it shows the minimum building blocks of an ML service:
- data,
- training,
- serialization,
- model loading,
- API serving.

Once you understand this flow, you can extend it with:
- better training data,
- evaluation metrics,
- model versioning,
- Docker,
- CI/CD,
- MLflow,
- cloud deployment.
