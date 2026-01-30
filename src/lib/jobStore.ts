/**
 * Job Store
 * Purpose: Track background processing progress for client polling
 * Scope: In-memory map keyed by jobId; not persisted across server restarts
 *
 * Cancellation Support:
 * - AbortControllers are stored separately (not serializable)
 * - cancelJob() triggers abort signal + updates status
 * - cancelJobByPipelineId() finds and cancels by pipelineId
 */
export type JobStage =
  | 'uploading'
  | 'parsing'
  | 'banner_agent'
  | 'crosstab_agent'
  | 'table_agent'
  | 'verification_agent'
  | 'parallel_processing'
  | 'banner_review_required'
  | 'banner_review_complete'
  | 'crosstab_review_required'   // Waiting for crosstab mapping review
  | 'crosstab_review_complete'   // Crosstab review submitted
  | 'validating_r'               // Per-table R validation with retry loop
  | 'generating_r'
  | 'executing_r'
  | 'writing_outputs'
  | 'queued_for_validation'
  | 'complete'
  | 'error'
  | 'cancelled'

export interface JobStatus {
  jobId: string
  stage: JobStage
  percent: number
  message: string
  sessionId?: string
  pipelineId?: string
  dataset?: string
  error?: string
  warning?: string
  downloadUrl?: string
  reviewRequired?: boolean
  reviewUrl?: string
  flaggedColumnCount?: number
  reviewType?: 'banner' | 'crosstab'  // NEW: Which type of review is needed
  cancelled?: boolean
  cancelledAt?: string
}

const jobs = new Map<string, JobStatus>()

// Store AbortControllers separately (they're not serializable)
const abortControllers = new Map<string, AbortController>()

export function createJob(): JobStatus {
  const jobId = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
  const status: JobStatus = {
    jobId,
    stage: 'uploading',
    percent: 1,
    message: 'Uploading files...'
  }
  jobs.set(jobId, status)

  // Create AbortController for this job
  const controller = new AbortController()
  abortControllers.set(jobId, controller)

  return status
}

export function getJob(jobId: string): JobStatus | undefined {
  return jobs.get(jobId)
}

export function updateJob(jobId: string, updates: Partial<JobStatus>): JobStatus | undefined {
  const existing = jobs.get(jobId)
  if (!existing) return undefined
  const next = { ...existing, ...updates }
  jobs.set(jobId, next)
  return next
}

/**
 * Get the AbortSignal for a job to pass to agents
 */
export function getAbortSignal(jobId: string): AbortSignal | undefined {
  return abortControllers.get(jobId)?.signal
}

/**
 * Check if a job has been cancelled
 */
export function isJobCancelled(jobId: string): boolean {
  const signal = abortControllers.get(jobId)?.signal
  return signal?.aborted ?? false
}

/**
 * Cancel a job by jobId - triggers abort signal and updates status
 * Returns true if job was found and cancelled
 */
export function cancelJob(jobId: string): boolean {
  const controller = abortControllers.get(jobId)
  const job = jobs.get(jobId)

  if (!controller || !job) {
    console.log(`[JobStore] Cannot cancel job ${jobId} - not found`)
    return false
  }

  // Abort the controller (this triggers the AbortSignal)
  controller.abort()

  // Update job status
  job.cancelled = true
  job.cancelledAt = new Date().toISOString()
  job.stage = 'cancelled'
  job.message = 'Pipeline cancelled by user'
  jobs.set(jobId, job)

  console.log(`[JobStore] Cancelled job ${jobId}`)
  return true
}

/**
 * Cancel a job by pipelineId - finds the job and cancels it
 * Returns true if job was found and cancelled
 */
export function cancelJobByPipelineId(pipelineId: string): boolean {
  for (const [jobId, status] of jobs.entries()) {
    if (status.pipelineId === pipelineId) {
      return cancelJob(jobId)
    }
  }
  console.log(`[JobStore] No job found for pipeline ${pipelineId}`)
  return false
}

/**
 * Clean up a job and its AbortController (call when job is done)
 */
export function cleanupJob(jobId: string): void {
  jobs.delete(jobId)
  abortControllers.delete(jobId)
}


