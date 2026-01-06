# Decipher API Test Commands

Based on the official OpenAPI spec (`decipher-api.yaml`).

## Setup

```bash
export DECIPHER_API_KEY="auq1v7pus15npcwvw14sg0dqqr54vdm2d8k0bdbbg48d3qa1ut4g287qcnxg8r2e"
export DECIPHER_BASE="https://selfserve.decipherinc.com"
export SURVEY="selfserve/21a7/g1011/250717"  # The closed ASCVD survey
```

---

## 1. List All Surveys

**Endpoint**: `GET /api/v1/rh/companies/all/surveys`

```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/rh/companies/all/surveys" | jq '.[0:5]'
```

To see just title, path, state:
```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/rh/companies/all/surveys" \
  | jq '[.[] | {title, path, state, qualified}] | .[0:10]'
```

---

## 2. List Files Available for a Survey

**Endpoint**: `GET /api/v1/surveys/{survey}/files`

This tells you what files exist (survey.xml, quota.xls, etc.):

```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/files" | jq '.'
```

Expected response (if you have access):
```json
[
  {"filename": "survey.xml", "modified": "2020-10-20T21:02:11Z", "size": 1239},
  {"filename": "static/less-compiled.css", "modified": "2020-10-20T21:02:14Z", "size": 73860}
]
```

If you get `403 Permission denied`, your API key doesn't have file access for this survey.

---

## 3. Download survey.xml (Contains Skip Logic!)

**Endpoint**: `GET /api/v1/surveys/{survey}/files/{filename}`

```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/files/survey.xml"
```

To save to file:
```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/files/survey.xml" \
  > temp-outputs/survey.xml
```

**Note**: The skip logic (`cond` attributes) is ONLY in survey.xml, not in the datamap.

---

## 4. Get Datamap (Variables & Questions)

**Endpoint**: `GET /api/v1/surveys/{survey}/datamap`

```bash
# JSON format
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/datamap?format=json" | jq '.'
```

Save to file:
```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/datamap?format=json" \
  > temp-outputs/datamap.json
```

Just questions:
```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/datamap?format=json" \
  | jq '.questions'
```

Just variables:
```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/datamap?format=json" \
  | jq '.variables'
```

**What datamap gives you**: Variable labels, types, question text, answer options
**What datamap does NOT give you**: Skip logic (cond attributes)

---

## 5. Get Survey Data (Respondent Answers)

**Endpoint**: `GET /api/v1/surveys/{survey}/data`

```bash
# First 5 qualified respondents
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/data?format=json&limit=5&cond=qualified" | jq '.'
```

All respondents (including partials):
```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/data?format=json&limit=5&cond=ALL" | jq '.'
```

Specific fields only:
```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/data?format=json&fields=uuid,status,S3,S4" | jq '.'
```

---

## 6. Get Completion Summary

**Endpoint**: `GET /api/v1/surveys/{survey}/summary/completions`

```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/summary/completions" | jq '.'
```

---

## 7. Get Data Layouts

**Endpoint**: `GET /api/v1/surveys/{survey}/layouts`

```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/layouts" | jq '.'
```

---

## 8. Get Quota Information

**Endpoint**: `GET /api/v1/surveys/{survey}/quota`

```bash
curl -s -H "x-apikey: $DECIPHER_API_KEY" \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/quota" | jq '.'
```

This includes markers and their conditions (`cond` attribute).

---

## 9. Evaluate a Condition (Debug Tool)

**Endpoint**: `POST /api/v1/surveys/{survey}/evaluate`

Test if a condition is valid:
```bash
curl -s -X POST -H "x-apikey: $DECIPHER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"cond": "S3.r1"}' \
  "$DECIPHER_BASE/api/v1/surveys/$SURVEY/evaluate" | jq '.'
```

---

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 401 | Invalid/missing API key |
| 403 | **Permission denied** - API key valid but you don't have access to this resource |
| 404 | Resource not found |
| 405 | Wrong HTTP method |
| 428 | Survey hibernated, needs reactivation |

---

## Key Finding: Where is Skip Logic?

**Skip logic (`cond` attributes) is ONLY in `survey.xml`**, not in the datamap JSON.

The datamap gives you:
- Variable names, types, labels
- Question text
- Answer options

The datamap does NOT give you:
- Skip logic conditions
- Question routing
- Termination conditions

To get skip logic, you need `/files/survey.xml` access.

---

## Troubleshooting 403 Errors

If you get `403 Permission denied` on `/files/survey.xml`:

1. Your API key has **datamap access** but not **file access**
2. Check your permissions in Decipher portal
3. You may need elevated permissions from your admin

The `/files` endpoint requires specific permissions that may not be granted by default.
