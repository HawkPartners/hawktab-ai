# PostHog Events Reference

**Last updated:** 2026-02-15

This document lists all PostHog events tracked in Crosstab AI and suggests dashboards you can build.

---

## Pipeline Events

### `pipeline_completed`
**When:** Pipeline finishes successfully (or partially)
**Triggered by:** `pipelineOrchestrator.ts` after Excel generation

**Properties:**
| Property | Type | Description | Dashboard Use |
|----------|------|-------------|---------------|
| `run_id` | string | Unique run identifier | Filter by run |
| `pipeline_id` | string | Pipeline session ID | Group runs |
| `status` | `'success' \| 'partial' \| 'error'` | Final status | Success rate metric |
| `table_count` | number | Tables generated | Output volume |
| `cut_count` | number | Banner cuts processed | Complexity metric |
| `duration_sec` | number | Total pipeline time (seconds) | **Average duration** |
| `excel_generated` | boolean | Whether Excel was created | Success indicator |
| `r2_upload_failed` | boolean | Whether R2 upload failed | Reliability metric |
| **`total_cost_usd`** | number | **Total pipeline cost** | **Weekly spend, avg cost** |
| **`total_tokens`** | number | **Total tokens used** | Token usage trends |
| `total_input_tokens` | number | Input tokens | Token breakdown |
| `total_output_tokens` | number | Output tokens | Token breakdown |
| `total_agent_calls` | number | Total AI calls | Call volume |
| **`agent_costs`** | object | **Cost per agent** | **Most expensive agents** |
| **`agent_durations_sec`** | object | **Duration per agent** | **Slowest agents** |
| **`agent_call_counts`** | object | **Calls per agent** | Agent usage patterns |
| **`agent_tokens`** | object | **Tokens per agent** | Token distribution |
| `has_loops` | boolean | Whether data has loops | Complexity flag |
| `loop_count` | number | Number of loop groups | Complexity metric |
| `variable_count` | number | Variables in dataset | Dataset size |
| `project_type` | string | `'standard' \| 'segmentation' \| 'maxdiff'` | Project breakdown |
| `banner_mode` | string | `'upload' \| 'auto_generate'` | Feature adoption |
| `weighted` | boolean | Whether run used weights | Feature usage |

**Example agent_costs structure:**
```json
{
  "BannerAgent": 0.12,
  "CrosstabAgent": 0.45,
  "VerificationAgent": 1.88,
  "SkipLogicAgent": 0.05
}
```

---

### `pipeline_failed`
**When:** Pipeline encounters an error
**Triggered by:** `pipelineOrchestrator.ts` catch block

**Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `run_id` | string | Run identifier |
| `pipeline_id` | string | Pipeline session ID |
| `error_message` | string | Error description |
| `error_type` | string | Error class name |
| `partial_cost_usd` | number | Costs before failure |
| `partial_tokens` | number | Tokens used before failure |
| `partial_agent_calls` | number | Calls before failure |
| `duration_before_failure_sec` | number | Time before error |
| `project_type` | string | Project type |
| `banner_mode` | string | Banner mode |

---

## Project Lifecycle Events

### `project_created`
**When:** User completes new project wizard
**Triggered by:** `projects/new/page.tsx`

**Properties:**
- `project_id`
- `project_name`
- `project_type`
- `banner_mode`
- `has_weight_variable`
- `display_mode`
- `theme`

---

### `project_launch_success` / `project_launch_error`
**When:** Project launches (before pipeline runs)
**Triggered by:** `/api/projects/launch/route.ts`

**Properties:**
- `project_id`
- `run_id`
- `org_id`
- `user_id`
- `project_type`
- `banner_mode`

---

### `project_deleted`
**When:** User deletes a project
**Triggered by:** `/api/projects/[projectId]/route.ts`

**Properties:**
- `project_id`
- `org_id`
- `user_id`

---

## User & Review Events

### `review_decision_made`
**When:** User makes a decision on a flagged column
**Triggered by:** `projects/[projectId]/review/page.tsx`

**Properties:**
- `project_id`
- `run_id`
- `group_name`
- `column_name`
- `action` - `'approve' | 'select_alternative' | 'provide_hint' | 'skip'`
- `has_hint`
- `alternative_index`

---

### `review_submitted`
**When:** User submits all review decisions
**Triggered by:** `projects/[projectId]/review/page.tsx`

**Properties:**
- `project_id`
- `run_id`
- `total_flagged_columns`
- `approved_count`
- `alternative_count`
- `hint_count`
- `skip_count`

---

### `feedback_submitted`
**When:** User submits feedback on a run
**Triggered by:** `projects/[projectId]/page.tsx`

**Properties:**
- `project_id`
- `run_id`
- `rating`
- `has_comment`

---

### `pipeline_cancelled`
**When:** User cancels a running pipeline
**Triggered by:** `projects/[projectId]/page.tsx`

**Properties:**
- `project_id`
- `run_id`

---

### `file_downloaded`
**When:** User downloads an output file
**Triggered by:** `projects/[projectId]/page.tsx`

**Properties:**
- `project_id`
- `run_id`
- `file_type`

---

## Wizard Events

### `file_uploaded`
**When:** User uploads a file in the wizard
**Triggered by:** `projects/new/page.tsx`

**Properties:**
- `file_type` - `'dataFile' | 'surveyDocument' | 'bannerPlan' | 'messageList'`
- `file_name`
- `file_size_bytes`
- `file_extension`

---

### `wizard_step_completed`
**When:** User completes a wizard step
**Triggered by:** `projects/new/page.tsx`

**Properties:**
- `step_number`
- `step_name`

---

## Team Events

### `member_removed`
**When:** Admin removes a team member
**Triggered by:** `/api/members/[membershipId]/route.ts`

**Properties:**
- `org_id`
- `membership_id`
- `removed_by_user_id`

---

## Dashboard Ideas

### 💰 **Cost Tracking**
1. **Weekly Spend**
   - Metric: Sum of `total_cost_usd` from `pipeline_completed`
   - Group by: Week
   - Breakdown: By `status` or `project_type`

2. **Average Cost Per Run**
   - Metric: Average of `total_cost_usd`
   - Filter: `status = 'success'`

3. **Most Expensive Agents** ⭐ NEW
   - Metric: Sum of each agent's cost from `agent_costs` object
   - Visualization: Bar chart
   - Shows: Which agents drive costs

4. **Cost by Project Type**
   - Metric: Sum of `total_cost_usd`
   - Breakdown: By `project_type`

---

### ⏱️ **Duration & Performance**
1. **Average Pipeline Duration**
   - Metric: Average of `duration_sec`
   - Filter: `status = 'success'`
   - Trend: Over time

2. **Duration Distribution**
   - Metric: Histogram of `duration_sec`
   - Insight: Are most runs fast? Any outliers?

3. **Slowest Agents** ⭐ NEW
   - Metric: Average of each agent's duration from `agent_durations_sec`
   - Shows: Which agents take the longest

---

### 📊 **Success & Reliability**
1. **Success Rate**
   - Metric: Count of runs by `status`
   - Formula: (success + partial) / total
   - Trend over time

2. **Failure Reasons**
   - Metric: Count of `pipeline_failed` events
   - Breakdown: By `error_type`

3. **R2 Upload Reliability**
   - Metric: Count where `r2_upload_failed = true`
   - Percentage of total runs

---

### 🔬 **Usage Patterns**
1. **Runs Per Week**
   - Metric: Count of `pipeline_completed`
   - Group by: Week
   - Insight: Usage trends

2. **Feature Adoption**
   - Metric: Count by `banner_mode` (upload vs auto-generate)
   - Metric: Count where `weighted = true`
   - Insight: Which features are being used

3. **Project Type Distribution**
   - Metric: Count by `project_type`
   - Pie chart: Standard vs Segmentation vs MaxDiff

4. **Loop Complexity**
   - Metric: Average `loop_count`
   - Metric: Percentage where `has_loops = true`

---

### 🤖 **Agent Analytics** ⭐ NEW
1. **Agent Call Volume**
   - Metric: Sum of each agent's calls from `agent_call_counts`
   - Shows: Which agents are used most

2. **Agent Token Usage**
   - Metric: Sum of each agent's tokens from `agent_tokens`
   - Breakdown: Input vs Output
   - Shows: Which agents consume most tokens

3. **Agent Cost Efficiency**
   - Formula: `agent_costs` / `agent_call_counts`
   - Shows: Cost per call for each agent
   - Identify: Expensive vs cheap agents

---

### 📈 **Business Metrics**
1. **Monthly Spend Forecast**
   - Metric: Sum of `total_cost_usd`
   - Cumulative sum over month
   - Projection: Linear trend

2. **Cost Per Table**
   - Formula: `total_cost_usd` / `table_count`
   - Shows: Efficiency metric

3. **Partial Cost on Failures**
   - Metric: Sum of `partial_cost_usd` from `pipeline_failed`
   - Shows: Money lost to failures

---

## Quick Start: Building Your First Dashboard

### Dashboard 1: "Weekly Costs"
1. Go to PostHog → Insights → New Insight
2. Select "Trends"
3. Event: `pipeline_completed`
4. Metric: Sum of `total_cost_usd`
5. Group by: Week
6. Filter: None (or `status = success` only)
7. Save as "Weekly Pipeline Spend"

### Dashboard 2: "Most Expensive Agents" ⭐
1. Insights → New Insight → SQL
2. Query:
   ```sql
   SELECT
     JSONExtractKeysAndValues(properties, 'String')
   FROM events
   WHERE event = 'pipeline_completed'
     AND JSONHas(properties, 'agent_costs')
   ```
3. Or use the Breakdowns feature:
   - Event: `pipeline_completed`
   - Breakdown: `agent_costs` (each key)
   - Metric: Sum

---

## Notes
- All events include `distinctId` set to `orgId` for multi-tenant analytics
- Agent breakdown properties (`agent_costs`, `agent_durations_sec`, etc.) are **new as of 2026-02-15**
- Pipeline events are only sent on success or completion (not on in-progress states)
- Costs are estimated using LiteLLM pricing (updated daily)
