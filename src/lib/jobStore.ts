/**
 * Job Store
 * Purpose: Track background processing progress for client polling
 * Scope: In-memory map keyed by jobId; not persisted across server restarts
 */
export type JobStage =
  | 'uploading'
  | 'parsing'
  | 'banner_agent'
  | 'crosstab_agent'
  | 'table_agent'
  | 'generating_r'
  | 'executing_r'
  | 'writing_outputs'
  | 'queued_for_validation'
  | 'complete'
  | 'error'

export interface JobStatus {
  jobId: string
  stage: JobStage
  percent: number
  message: string
  sessionId?: string
  error?: string
  warning?: string
  downloadUrl?: string
}

const jobs = new Map<string, JobStatus>()

export function createJob(): JobStatus {
  const jobId = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
  const status: JobStatus = {
    jobId,
    stage: 'uploading',
    percent: 1,
    message: 'Uploading files...'
  }
  jobs.set(jobId, status)
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


