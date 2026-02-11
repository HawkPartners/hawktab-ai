'use client';

import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';

const ACTIVE_JOB_KEY = 'crosstab-active-job';
const ACTIVE_PIPELINE_KEY = 'crosstab-active-pipeline';

interface ProjectContextValue {
  activeProjectId: string | null;
  activeJobId: string | null;
  setActiveProject: (projectId: string | null) => void;
  setActiveJob: (jobId: string | null) => void;
  clearActive: () => void;
}

const ProjectContext = createContext<ProjectContextValue | null>(null);

export function ProjectProvider({ children }: { children: ReactNode }) {
  const [activeProjectId, setActiveProjectId] = useState<string | null>(null);
  const [activeJobId, setActiveJobId] = useState<string | null>(null);

  // Sync from localStorage on mount
  useEffect(() => {
    setActiveJobId(localStorage.getItem(ACTIVE_JOB_KEY));
    setActiveProjectId(localStorage.getItem(ACTIVE_PIPELINE_KEY));
  }, []);

  const setActiveProject = useCallback((id: string | null) => {
    setActiveProjectId(id);
    if (id) {
      localStorage.setItem(ACTIVE_PIPELINE_KEY, id);
    } else {
      localStorage.removeItem(ACTIVE_PIPELINE_KEY);
    }
  }, []);

  const setActiveJob = useCallback((id: string | null) => {
    setActiveJobId(id);
    if (id) {
      localStorage.setItem(ACTIVE_JOB_KEY, id);
    } else {
      localStorage.removeItem(ACTIVE_JOB_KEY);
    }
  }, []);

  const clearActive = useCallback(() => {
    setActiveProjectId(null);
    setActiveJobId(null);
    localStorage.removeItem(ACTIVE_JOB_KEY);
    localStorage.removeItem(ACTIVE_PIPELINE_KEY);
  }, []);

  return (
    <ProjectContext.Provider value={{ activeProjectId, activeJobId, setActiveProject, setActiveJob, clearActive }}>
      {children}
    </ProjectContext.Provider>
  );
}

export function useProject() {
  const ctx = useContext(ProjectContext);
  if (!ctx) throw new Error('useProject must be used within a ProjectProvider');
  return ctx;
}
