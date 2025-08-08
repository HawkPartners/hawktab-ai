/**
 * GET /api/process-crosstab/status?jobId=...
 * Purpose: Poll job status for processing pipeline
 * Reads: in-memory job store
 * Returns: { jobId, stage, percent, message, sessionId? }
 */
import { NextRequest, NextResponse } from 'next/server'
import { getJob } from '../../../../lib/jobStore'

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const jobId = searchParams.get('jobId')
  if (!jobId) {
    return NextResponse.json({ error: 'Missing jobId' }, { status: 400 })
  }
  const job = getJob(jobId)
  if (!job) {
    return NextResponse.json({ error: 'Job not found' }, { status: 404 })
  }
  return NextResponse.json(job)
}


