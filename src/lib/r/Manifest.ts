import type { TablePlan } from '@/lib/tables/TablePlan';
import type { CutsSpec } from '@/lib/tables/CutsSpec';

export type RManifest = {
  dataFilePath: string;
  tablePlan: TablePlan;
  cutsSpec: CutsSpec;
};

export function buildRManifest(sessionId: string, tablePlan: TablePlan, cutsSpec: CutsSpec): RManifest {
  return {
    dataFilePath: `temp-outputs/${sessionId}/dataFile.sav`,
    tablePlan,
    cutsSpec,
  };
}


